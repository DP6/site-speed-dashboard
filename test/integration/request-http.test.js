const chai = require('chai');
const expect = chai.expect;
const assert = chai.assert;
const execPromise = require('child-process-promise').exec;
const path = require('path');
const requestRetry = require('requestretry');
const uuid = require('uuid');

const PORT = process.env.PORT || 8080;
process.env.PROJECT_BUCKET_GCS = 'site_speed_dashboard_test'; //bucket com arquivo de configuração publico
process.env.PSI_KEY = '';
const BASE_URL = `http://localhost:${PORT}`;
const cwd = path.join(__dirname, './../../');
let ffProc;

describe('Execução cloud function template', async () => {
  // Run the functions-framework instance to host functions locally
  before(() => {
    // exec's 'timeout' param won't kill children of "shim" /bin/sh process
    // Workaround: include "& sleep <TIMEOUT>; kill $!" in executed command
    ffProc = execPromise(
      `functions-framework --target=getUrls --signature-type=http --port ${PORT} & sleep 16; kill $!`,
      { shell: true, cwd }
    );
  });

  after(async () => {
    // Wait for the functions framework to stop
    await ffProc;
  });

  it('Deve retornar HTTP status code 200', async () => {
    const response = await requestEndpoint();

    assert.strictEqual(response.statusCode, 200);
  });
});

async function requestEndpoint() {
  return requestRetry({
    url: `${BASE_URL}/?debugging=true`,
    method: 'GET',
    retryDelay: 200,
    json: true,
  });
}
