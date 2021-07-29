const { BigQuery } = require('@google-cloud/bigquery');
const { Storage } = require('@google-cloud/storage');
const BUCKET_GCS = process.env.PROJECT_BUCKET_GCS;
const PROJECT_FOLDER = 'project-name';
let projectConfig = {};
let debugging = false;

const templateCf = async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Credentials', 'true');

  // Liberação de CROS
  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Methods', 'GET, POST');
    res.set('Access-Control-Allow-Headers', 'Authorization, Content-Type');
    res.set('Access-Control-Max-Age', '3600');
    res.sendStatus(204);
  } else {
    projectConfig = await loadProjectConfig();
    const deparaSchema = projectConfig.DEPARA_SCHEMA;
    const query = req.query;
    debugging = query.debugging; //Se true habilita o log do json de validação
    delete query.debugging;

    // Verificação se o identificado de schema foi passado por parâmetro
    if (!query[projectConfig.PARAM_QUERY_STRING_SCHEMA]) {
      res
        .status(400)
        .send(
          `${debugging ? 'debugging' : ''}${
            projectConfig.PARAM_QUERY_STRING_SCHEMA
          } não informado como parâmetro queryString`
        );
      return;
    }

    trace('PROJECT', 'Tem configuração');

    let result = [];
    result = result.concat(
      createSchemaBq([{ name: 'teste cf' }], query, `${query[projectConfig.PARAM_QUERY_STRING_SCHEMA]}:`)
    );

    trace('RESULT VALID', result);
    insertRowsAsStream(result);
    res.status(200).send(debugging ? { debugging: debugging, result: result } : 'sucesso!');
  }
};

/**
 * Monta as linhas para serem inseridas no BQ
 * @param {Array} result Status das chaves validadas
 * @param {Object} queryString
 * @param {String} schemaName Identificação do schema usado para validação
 * @returns {Array} Dados estruturados para o BQ
 */
function createSchemaBq(result, queryString, schemaName) {
  const schemaBQ = [];
  const schema = { schema: schemaName };
  const objectQuery = addTimestamp(queryString);
  result.forEach((item) => {
    schemaBQ.push({ ...objectQuery, ...schema, ...item });
  });

  return schemaBQ;
}

/**
 * Adiciona o atributo data para o objeto, contendo o timestamp do momento da execução
 * @param {Object} data Objeto
 * @returns {Object} Objeto com o atributo no padrão yyyy-mm-ddThh:mm:ss
 */
function addTimestamp(data) {
  let [date, time] = new Date().toLocaleString('pt-BR', { timeZone: 'America/Sao_Paulo' }).split(' ');
  date = date.split('/');
  let timestamp = `${date[2]}-${date[1]}-${date[0]}T${time}`;
  data.data = timestamp;
  return data;
}

/**
 * Realiza a persistências dos dados por Stream no BigQuery
 * @param {Array} data Dados estruturados no padrão de persistência do BQ
 */
async function insertRowsAsStream(data) {
  const bigquery = new BigQuery();
  const options = {
    schema: projectConfig.BQ_SCHEMA_RAWDATA,
    skipInvalidRows: true,
    ignoreUnknownValues: true,
  };

  trace(data);
  // Insert data into a table
  await bigquery
    .dataset(projectConfig.BQ_DATASET_ID)
    .table(projectConfig.BQ_TABLE_ID_RAWDATA)
    .insert(data, options, insertHandler);

  console.log(`Inserted ${data.length} rows`);
}

/**
 * Carrega o arquivo de configuração armazenado no GCS
 */
async function loadProjectConfig() {
  const storage = new Storage();
  const bucket = storage.bucket(BUCKET_GCS);

  let file = bucket.file(`${PROJECT_FOLDER}/config.json`);
  let projectConfig = (await file.download())[0].toString();

  return JSON.parse(projectConfig);
}

function insertHandler(err, apiResponse) {
  if (err) {
    console.error(err.name, JSON.stringify(err));
  }
}

/**
 * Enviado o log para o stdout, se somente se, a variável debugging = true
 * @param {Object} log Que será apresentado no stdout
 */
function trace(log) {
  if (debugging) {
    console.log(log);
  }
}

module.exports = {
  createSchemaBq,
  addTimestamp,
  loadProjectConfig,
  insertRowsAsStream,
  templateCf,
};
