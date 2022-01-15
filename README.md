# Projeto SpeedIO

### Projeto ainda em desenvolvimento

Criado com Ruby, utilizando funções para realizar as tarefas necessárias, pode não ser o melhor método de utilizar a linguagem para lidar com grande volume de dados, mas foi o que consegui aprender nesse meio tempo.

## Por que Ruby?

Estou mais acostumado e confortável em trabalhar com Python, porém quando apareceu o Bônus Points por usar Ruby, pensei: "Por que não usar Ruby? O não já tenho, então vamos tornar isso mais emocionante!" e dessa forma fui atrás de ver como Ruby é utilizado nessas situaçẽos e como é sua sintaxe para o projeto.

## use ruby index.rb para iniciar o processo

## Fluxo do Script

Script começa importando os módulos e depois inicia a conexão com o MongoDB, utilizando .env para proteger as credenciais de acesso. Após termos a conexão, é criado uma única collection que será utilizada pelo script e depois passa para a declaração das funções onde explico abaixo.

## def download_zip(collection)

Função criada para baixar todos os CSV do servidor do governo e então chamar o extrator para cada uma das situações, ela recebe a collection do Mongo pois precisará ser usado mais a frente.

## def extract_zip(file, destination)

Função responsável para receber todos os zips baixados, extrair o CSV e salvar para ser iterado na próxima função.

## def iterate_csv(collection)

Responsável por pegar o CSV, ler linha por linha, sem subir na memória RAM todo arquivo, ajeitar as informações de cada linha em um hash e então salválas no banco.

//Aqui falta ainda remover os CNAE sem informações.

puts result é para saber se está sendo salvo mesmo, ainda para fins de teste.

## def calculate_active_percentage(collection)

Essa é a primeira função de cálculo, responsável apenas para calcular a % de empresas com status ativo, através de uma regra de 3 entre o total de registros no banco e comparar os registros ativos, também do mongo, retornando a % em float.

## def calculate_restaurants_openings_by_year(collection)

Segunda função de cálculo, responsável por corelacionar a quantidade de empresas de restaurante abertas em cada ano, feito através da função aggregate do mongo no qual foi utilizado o $substr para pegar o ano da data de abertura e então somar o número de empresas que batiam o CNAE principal com o regex /^561/. Como não testei por completo essa função com todos os CNAE possíveis, pode haver erros de lógica nela.

## def calculate_cnae_principal_secundario(collection)

Terceira e última função de cálculo, que foi difícil até descobrir a função $unwind existia, ela correlaciona as informações de CNAE principal com as CNAE secundárias, que pode ser mais de uma, então ele separa no banco essas duas Fields onde a principal vira o _id  e secundária passa pela função Split para separar as várias informações dentro da mesma String, e então é utilizado a função $push para ir pegando as diferentes aparições e também ir somando quantas vezes elas aparecem. O comando $sort foi colocado apenas para organizar o retorno e o comando $unwind é para iterar o retorno do comando $split.

## def create_cnae_xlsx(calculated_cnae)

Primeira geração de XLSX, responsável por pegar o retorno da furnção calculate_cnae_principal_secundario e então ir salvando em cada linha as informações dentro do objeto fazendo uma dupla iteração do cnae principal e secundário, pois em cada principal há vários secundários. Ela possui um valor variável de colunas pois cada CNAE Principal pode variar a quantidade de CNAE Secundário.

## def create_restaurants_xlsx(calculated_restaurants)

Segunda função para geração de XLSX, que pega o retorno de create_restaurants_xlsx e salva cada um em uma linha diferente com apenas 2 colunas, uma com o ano e a outra com a quantidade de empresa.

## def create_active_xlsx(porcentage_active)

Terceira e última função de geração do XLSX, que simplesmente salva a porcentagem de empresas ativas em um arquivo separado.

## def main(collection)

Função responsável por amarrar as chamadas de funções e iniciar a reação em cadeia para rodar tudo em uma só vez.

___

Por fim vem a chamada de cada método para que ocorra tudo em ordem como um script deve ser, ainda falta alguns ajustes de código, mas está sendo desenvolvido durante meu tempo livre.

## próximos passos

[ ] Refatorar e melhorar o código já existente;
[ ] Encontrar melhores formas de resolver o problema;
[ ] Resolver problema de salvar CNAE secundários vazios 