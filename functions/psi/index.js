const { BigQuery } = require('@google-cloud/bigquery');
const { Storage } = require('@google-cloud/storage');
const psi = require('psi');
const BUCKET_GCS = process.env.PROJECT_BUCKET_GCS;
const PROJECT_FOLDER = 'config';
const PSI_KEY = process.env.PSI_KEY;
let projectConfig = {};
let debugging = false;

async function getUrls(req, res) {
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
    processPsiData();

    res.status(200).send({ debugging: debugging, message: 'Em processamento!' });
  }
}

async function makeRequest(urls, strategy) {
  const psiResults = [];
  const suggestionResults=[];
  
  
  
  const date = new Date().toISOString().split('T')[0];

  const psiRuns = urls.map(async ({ URL, brand, page }) => {
    try {
      trace(`Iniciando requisição: ${brand} ${strategy}`);
      let psi_response = await psi(URL, { strategy: strategy, key: PSI_KEY });
      if (psi_response) {
        let objBase = {};
        let {lighthouseResult,loadingExperienceResult} = psi_response.data;
        const LHREsult = lighthouseResult ? _formatLightHouseResult(date,brand,page,URL,lighthouseResult) : null;
        const LEResult = loadingExperienceResult ? _formatLoadingResult(loadingExperienceResult) : null;
        let suggestions = formatPSISuggestions(lighthouseResult);
        trace(`Suggestions: ${suggestions}`);
        trace (`Lighthouse Results: ${LHREsult}`);
        trace (`Loading Experience results: ${LEResult}`);
        // let lighthouseResult = psi_response.data.lighthouseResult;
        // let loadingExperienceResult = psi_response.data.loadingExperience;
        if (LHREsult) objBase = { ...LHREsult };
        if (LEResult) objBase = { ...LEResult };
        psiResults.push(objBase);
        suggestionResults.push(suggestions);
        
      }
    } catch (error) {
      trace(JSON.stringify(error));
    }
  });
  await Promise.all(psiRuns);
  return psiResults,suggestionResults;
}

 /**
     * Util to extract all numeric values from the lighthouse result variable.
     * @param {Object} lighthouseResult
     * @param {Object} lighthouseResult.audits 
     * @param {Object} lighthouseResult.categories 
     * @param {Object} lighthouseResult.configSettings 
     * @return {Object} LHREsult
     */
  function _formatLightHouseResult() {
    
    return {
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
    }
}

/**
 * Util to extract all values and categories the Crux loadingResult variable.
 * @param {Object} loadingExperience
 * @param {Object} loadingExperience.metrics 
 * @param {Object} loadingExperience.overall_category 
 * @return {Object} LEResult
 */
function _formatLoadingResult({ metrics, overall_category }) {
    const mock = {
        CUMULATIVE_LAYOUT_SHIFT_SCORE: { category: null, percentile: null },
        FIRST_CONTENTFUL_PAINT_MS: { category: null, percentile: null },
        FIRST_INPUT_DELAY_MS: { category: null, percentile: null },
        LARGEST_CONTENTFUL_PAINT_MS: { category: null, percentile: null },
    }
    let { CUMULATIVE_LAYOUT_SHIFT_SCORE, FIRST_CONTENTFUL_PAINT_MS, FIRST_INPUT_DELAY_MS, LARGEST_CONTENTFUL_PAINT_MS } = metrics || mock;

    return {
        'Loading_CLS_Category': CUMULATIVE_LAYOUT_SHIFT_SCORE.category || "N/A",
        'Loading_CLS': CUMULATIVE_LAYOUT_SHIFT_SCORE.percentile || "-",
        'Loading_FCP_Category': FIRST_CONTENTFUL_PAINT_MS.category || "N/A",
        'Loading_FCP': FIRST_CONTENTFUL_PAINT_MS.percentile || "-",
        'Loading_FID_Category': FIRST_INPUT_DELAY_MS.category || "N/A",
        'Loading_FID': FIRST_INPUT_DELAY_MS.percentile || "-",
        'Loading_LCP_Category': LARGEST_CONTENTFUL_PAINT_MS.category || "N/A",
        'Loading_LCP': LARGEST_CONTENTFUL_PAINT_MS.percentile || "-",
        'Loading_Overall_Category': overall_category || "N/A"
    }
}

    /**
     * Gets all opportunities from the API response body and formats them into the expected Object.
     * @param {Object} lightHouseResult - Required. The API response body. 
     * @param {String} [pagina="Home"] - Type of page.
     * @returns {Array} opportunities.
     */
    function formatPSISuggestions({ lighthouseResult }, page = "Home") {
      const { audits, categories, configSettings } = lighthouseResult;
      let { auditRefs } = categories.performance;
      return auditRefs.filter(({ group }) => group === 'load-opportunities')
          .map(({ id }) => audits[id])
          .filter(({ numericValue }) => numericValue > 0)
          .sort(
              (a, b) => b.numericValue - a.numericValue
          ).map((opportunity) => _formatSuggestion(opportunity, page,configSettings.formFactor,date));
  }

 /**
     * Util to format each opportunity into the expected Object
     * @param {Object} opportunity - Required. Load opportunity from the API response body.
     * @param {String} [pagina="Home"] - Type of page. 
     * @returns {Object} formattedOpportunidy
     */
  function _formatSuggestion(opportunity, page, device,date) {
    const { title, score, description, details, displayValue, warning } = opportunity;
    const { items, overallSavingsBytes, type, overallSavingsMs } = details;
    return {
        'Data': date,
        'Page': page,
        'Device': device,
        'Oportunidade': title,
        'Score': score,
        'Descrição': description,
        'Economia': displayValue,
        'Possivel impacto no tempo de carregamento': overallSavingsMs || '-',
        'Possivel impacto nos dados': overallSavingsBytes || '',
        'Tipo de sugestão': type || ''
    }
}

async function processPsiData() {
  trace('getUrls Desktop');
  insertRowsAsStream(
    await getUrlsDesktop(),
    projectConfig.BQ_SCHEMA_PSI_METRICS,
    projectConfig.BQ_TABLE_ID_PSI_METRICS
  );
  trace('getUrls Mobile');
  insertRowsAsStream(await getUrlsMobile(), projectConfig.BQ_SCHEMA_PSI_METRICS, projectConfig.BQ_TABLE_ID_PSI_METRICS);
}

async function getUrlsDesktop(strategy = 'desktop') {
  const base = await loadProjectConfig();
  const urls = base.URLS.filter(({ strategy }) => !!strategy.desktop);
  let desktopResults = await makeRequest(urls, 'desktop');
  return desktopResults;
}

async function getUrlsMobile(strategy = 'mobile') {
  const base = await loadProjectConfig();
  const urls = base.URLS.filter(({ strategy }) => !!strategy.mobile);
  let mobileResults = await makeRequest(urls, 'mobile');
  return mobileResults;
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
  loadProjectConfig,
  insertRowsAsStream,
  getUrlsDesktop: getUrlsDesktop,
  getUrlsMobile: getUrlsMobile,
  getUrls,
};
