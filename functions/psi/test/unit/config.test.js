const { assert } = require('chai');
const fs = require('fs');
const chai = require('chai');
const expect = chai.expect;

describe('Arquivo de configuração', () => {
  let config;
  before(() => {
    config = JSON.parse(fs.readFileSync('./../../terraform/files-copy-to-gcs/config/config.json').toString());
  });
  it('Deve possuir o atributo URLS', async () => {
    expect(config).to.have.own.property('URLS');
  });
  it('Deve possuir o atributo BQ_DATASET_ID', async () => {
    expect(config).to.have.own.property('BQ_DATASET_ID');
    expect(config.BQ_DATASET_ID).to.equal('dp6-site-speed-dashboard');
  });
  it('Deve possuir o atributo BQ_TABLE_ID_PSI_METRICS', async () => {
    expect(config).to.have.own.property('BQ_TABLE_ID_PSI_METRICS');
    expect(config.BQ_TABLE_ID_PSI_METRICS).to.equal('psi_metrics_results');
  });
  it('Deve possuir o atributo BQ_SCHEMA_PSI_METRICS', async () => {
    expect(config).to.have.own.property('BQ_SCHEMA_PSI_METRICS');
  });
});
