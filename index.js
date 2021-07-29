const { BigQuery } = require('@google-cloud/bigquery');
const { Storage } = require('@google-cloud/storage');
const psi = require('psi');
const BUCKET_GCS = process.env.PROJECT_BUCKET_GCS;
const PROJECT_FOLDER = 'base';
let projectConfig = {};
let debugging = false;

const getUrls = async (req, res) => {
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
    const query = req.query;
    debugging = query.debugging; //Se true habilita o log do json de validação
    delete query.debugging;

    let desktop = await getUrls_desktop();
    let mobile = await getUrls_mobile();

    trace('PROJECT', 'Tem configuração');

    trace('RESULT VALID');
    res
      .status(200)
      .send(debugging ? { debugging: debugging, resultDesktop: desktop, resultMobile: mobile } : 'sucesso!');
  }
};

async function makeRequest(urls, strategy) {
  // const psi = new PSIApiUtil(PSI_API_KEY);
  // let sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(sheets.base);
  const psiResult = [];
  const date = new Date().toISOString().split('T')[0];

  const psiRuns = urls.map(async ({ URL, brand, page }) => {
    try {
      trace(`Iniciando requisição: ${brand} ${strategy}`);
      let psi_response = await psi(URL, { strategy: strategy, key: 'AIzaSyDMowLrCL6VBPQuGwjK7OKAX4kGHmhYqxk' });
      if (psi_response) {
        let lighthouseResult = psi_response.data.lighthouseResult;
        psiResult.push({
          Data: date,
          Brand: brand,
          Page: page,
          Site: URL,
          Device: lighthouseResult.configSettings.emulatedFormFactor,
          Score: lighthouseResult.categories.performance.score,
          LAB_FCP: lighthouseResult.audits['first-contentful-paint']?.numericValue || null,
          LAB_FMP: lighthouseResult.audits['first-meaningful-paint']?.numericValue || null,
          LAB_FCPUIdle: lighthouseResult.audits['first-cpu-idle']?.numericValue || null,
          LAB_SpeedIndex: lighthouseResult.audits['speed-index']?.numericValue || null,
          LAB_TTI: lighthouseResult.audits['interactive']?.numericValue || null,
          LAB_InputLatency: lighthouseResult.audits['estimated-input-latency']?.numericValue || null,
          LAB_TTFB: lighthouseResult.audits['server-response-time']?.numericValue || null,
          LAB_RenderBlocking: lighthouseResult.audits['render-blocking-resources']?.numericValue || null,
          LAB_TBT: lighthouseResult.audits['total-blocking-time']?.numericValue || null,
          LAB_CLS: lighthouseResult.audits['cumulative-layout-shift']?.numericValue || null,
          LAB_LCP: lighthouseResult.audits['largest-contentful-paint']?.numericValue || null,
        });
      }
    } catch (error) {
      trace(JSON.stringify(error));
    }
  });
  await Promise.all(psiRuns);
  return psiResult;
}

async function getUrls_desktop(strategy = 'desktop') {
  const base = await loadProjectConfig();
  const urls = base.URLS.filter(({ strategy }) => !!strategy.desktop);
  let desktopResults = await makeRequest(urls, 'desktop');
  insertRowsAsStream(desktopResults, projectConfig.BQ_SCHEMA_PSI_METRICS, projectConfig.BQ_TABLE_ID_PSI_METRICS);
  return desktopResults;
}

async function getUrls_mobile(strategy = 'mobile') {
  const base = await loadProjectConfig();
  const urls = base.URLS.filter(({ strategy }) => !!strategy.mobile);
  let mobileResults = await makeRequest(urls, 'mobile');
  insertRowsAsStream(mobileResults, projectConfig.BQ_SCHEMA_PSI_METRICS, projectConfig.BQ_TABLE_ID_PSI_METRICS);
  return mobileResults;
}

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
async function insertRowsAsStream(data, schema, tableId) {
  const bigquery = new BigQuery();
  const options = {
    schema: schema,
    skipInvalidRows: true,
    ignoreUnknownValues: true,
  };

  trace(data);
  // Insert data into a table
  await bigquery.dataset(projectConfig.BQ_DATASET_ID).table(tableId).insert(data, options, insertHandler);

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
  getUrls,
};
