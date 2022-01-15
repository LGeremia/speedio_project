require 'zip'
require 'httparty'
require 'rubygems'
require 'csv'
require 'mongo'
require 'axlsx'
require 'dotenv/load'

DB_USER=ENV['DATABASE_USER']
DB_PASSWORD=ENV['DATABASE_PASSWORD']

client = Mongo::Client.new("mongodb+srv://#{DB_USER}:#{DB_PASSWORD}@cluster0.pinvn.mongodb.net/myFirstDatabase?retryWrites=true&w=majority")
collection = client[:empresas]

def iterate_csv(index,collection)
  CSV.foreach("./temp/csv/K3241.K03200Y#{index}.D11211.ESTABELE",col_sep: ";",headers: false,liberal_parsing: true, encoding: 'ISO-8859-1') do |row|
    hash = {
      :cnpj_basico=>row[0],
      :cnpj_ordem=>row[1],
      :cnpj_dv=>row[2],
      :identificador_matriz=>row[3],
      :nome_fantasia=>row[4],
      :situacao_cadastral=>row[5], #ativo = 2
      :data_situacao_cadastral=>row[6],
      :motivo_situacao_cadastral=>row[7],
      :nome_cidade_exterior=>row[8],
      :cod_pais=>row[9],
      :data_inicio_atividade=>row[10],
      :cnae_fiscal_princial=>row[11],
      :cnae_fiscal_secundaria=>row[12],
      :tipo_logradouro=>row[13],
      :logradouro=>row[14],
      :numero=>row[15],
      :complemento=>row[16],
      :bairro=>row[17],
      :cep=>row[18],
      :uf=>row[19],
      :municipio=>row[20],
      :ddd_1=>row[21],
      :telefone_1=>row[22],
      :ddd_2=>row[23],
      :telefone_2=>row[24],
      :ddd_fax=>row[25],
      :fax=>row[26],
      :email=>row[27],
      :situacao_especial=>row[28],
      :data_situacao_especial=>row[29]
    }
    result = collection.insert_one(hash)
  end
end

def extract_zip(file, destination)
  FileUtils.mkdir_p(destination)
  Zip::File.open(file) do |zip_file|
    zip_file.each do |f|
      fpath = File.join(destination, f.name)
      zip_file.extract(f, fpath) unless File.exist?(fpath)
    end
  end
end

def download_zip(collection)
  index = 0
  while index <= 0 do
    url = "http://200.152.38.155/CNPJ/K3241.K03200Y#{index}.D11211.ESTABELE.zip"
    File.open("./temp/#{index}.zip", "w+") do |file|
      file.write HTTParty.get(url).body
    end
  end
  extract_zip("./temp/#{index}.zip", "./temp/")
  iterate_csv(index,collection)
end

def calculate_active_percentage(collection)
  total_records = collection.count();
  total_active = collection.count({:situacao_cadastral=>"02"})
  porcentage_of_active = (total_active.to_f*100)/total_records.to_f 
  return porcentage_of_active
end

def calculate_restaurants_openings_by_year(collection)
  results = collection.aggregate([
    {
      '$match' => { 
        'cnae_fiscal_princial'=> /^561/
      }
    },
    {
      '$group' => { 
        '_id'=>{
          '$substr'=>[
            '$data_inicio_atividade',
            0,4
          ]
        }, 'quantidade'=>{
          '$sum'=> 1
        },
      }
    }
  ],:allow_disk_use => true)
  return results
end

def calculate_cnae_principal_secundario(collection)
  results = collection.aggregate([
    {
      '$group' => { 
        '_id'=> {
          'cnae_princial'=>'$cnae_fiscal_princial',
          'cnae_secundaria'=>{
            '$split'=> [
              '$cnae_fiscal_secundaria',','
            ]
          }
        },
        'cnae_count'=>{'$sum'=>1}
      },
    },
    { '$unwind'=> "$_id.cnae_secundaria" },
    { '$group'=> {
        '_id'=> '$_id.cnae_princial',
        'cnae_secundarias'=> { 
            '$push'=> { 
                'secundaria'=>'$_id.cnae_secundaria',
                'count'=> '$cnae_count'
            },
        },
        'count'=> { '$sum'=> '$cnae_count' }
    }},
    { '$sort'=> { 'count'=> 1 } },
  ],:allow_disk_use => true)
end

def create_cnae_xlsx(calculated_cnae)
  Axlsx::Package.new do |p|
    p.workbook.add_worksheet(:name => "Corelation Cnae") do |sheet|
      sheet.add_row ["Cnae Primary","Quantity","Cnae Secundary","Cnae Secundary Quantity"]
      calculated_cnae.each do |cnae|
        arr = [cnae["_id"],cnae["count"]]
        cnae["cnae_secundarias"].each do |scnae|
          arr.concat [scnae["secundaria"],scnae["count"]]
        end
        sheet.add_row arr
      end
    end
    p.serialize('corelation_cnae_primaryXsecundary.xlsx')
  end
end

def create_restaurants_xlsx(calculated_restaurants)
  Axlsx::Package.new do |p|
    p.workbook.add_worksheet(:name => "Corelation Restaurants") do |sheet|
      sheet.add_row ["Year","Quantity of Restaurants"]
      calculated_restaurants.each do |year|
        arr = [year["_id"],year["quantidade"]]
        sheet.add_row arr
      end
    end
    p.serialize('calculated_restaurants.xlsx')
  end
end

def create_active_xlsx(porcentage_active)
  Axlsx::Package.new do |p|
    p.workbook.add_worksheet(:name => "% Empresas Ativas") do |sheet|
      sheet.add_row ["% de empresas ativas",porcentage_active]
    end
    p.serialize('actives.xlsx')
  end
end

download_zip(collection)

#calculated_cnae = calculate_cnae_principal_secundario(collection)

#calculated_restaurants = calculate_restaurants_openings_by_year(collection)

#porcentage_active = calculate_active_percentage(collection)


#create_active_xlsx(porcentage_active)

#create_restaurants_xlsx(calculated_restaurants)

#create_cnae_xlsx(calculated_cnae)

