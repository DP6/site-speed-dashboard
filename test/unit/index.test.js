const { assert } = require('chai');
const chai = require('chai');
const expect = chai.expect;
const uuid = require('uuid');
process.env.PROJECT_BUCKET_GCS = 'site_speed_dashboard_test';

const cloudFunction = require('./../../index');

describe('Template Cloud Function', () => {
  describe('#getUrls()', () => {
    it('Deve ser uma function', () => {
      assert.isFunction(cloudFunction.getUrls);
    });
    it('Deve processar req e resp retornando http status code 200', async () => {
      const req = {
        query: {},
        method: 'OPTIONS',
        body: {
          id: uuid.v4(),
        },
      };

      let tmpResponse = { status: '' };
      let tmpFunctionStatus = (s) => {
        tmpResponse.status = s;
      };
      const res = {
        set: () => {},
        sendStatus: tmpFunctionStatus,
        send: tmpFunctionStatus,
      };

      await cloudFunction.getUrls(req, res);
      assert.strictEqual(tmpResponse.status, 204);
    });
    it('Deve processar req e resp retornando http status code 200', async () => {
      const req = {
        query: {},
      };

      let tmpResponse = { status: '' };
      let tmpFunctionStatus = (s) => {
        tmpResponse.status = s;
      };
      const res = {
        set: () => {},
        sendStatus: tmpFunctionStatus,
        send: tmpFunctionStatus,
        status: (s) => {
          tmpFunctionStatus(s);
          return { send: () => {} };
        },
      };

      await cloudFunction.getUrls(req, res);
      assert.strictEqual(tmpResponse.status, 200);
    });
  });

  describe('#loadProjectConfig()', () => {
    it('Deve retornar o objeto de configuração', async () => {
      expect(await cloudFunction.loadProjectConfig()).to.have.own.property('URLS');
    });
  });

  describe('#getUrlsDesktop()', () => {
    it('Deve ser uma function', () => {
      assert.isFunction(cloudFunction.getUrlsDesktop);
    });
    it('Deve retornar um array de metricas do PSI', async () => {
      let response = await cloudFunction.getUrlsDesktop();
      expect(response).to.be.an('array').that.not.empty;
    });
    it('O objeto de metricas deve ter o atributo Score', async () => {
      let response = await cloudFunction.getUrlsDesktop();
      expect(response[0]).to.have.own.property('Score');
    });
    it('O objeto de metricas deve ter o atributo Data', async () => {
      let response = await cloudFunction.getUrlsMobile();
      expect(response[0]).to.have.own.property('Data');
    });
    it('O objeto de metricas deve ter o atributo Brand', async () => {
      let response = await cloudFunction.getUrlsMobile();
      expect(response[0]).to.have.own.property('Brand');
    });
    it('O objeto de metricas deve ter o atributo Page', async () => {
      let response = await cloudFunction.getUrlsMobile();
      expect(response[0]).to.have.own.property('Page');
    });
  });

  describe('#getUrlsMobile()', () => {
    it('Deve ser uma function', () => {
      assert.isFunction(cloudFunction.getUrlsMobile);
    });
    it('Deve retornar um array de metricas do PSI', async () => {
      let response = await cloudFunction.getUrlsMobile();
      expect(response).to.be.an('array').that.not.empty;
    });
    it('O objeto de metricas deve ter o atributo Score', async () => {
      let response = await cloudFunction.getUrlsMobile();
      expect(response[0]).to.have.own.property('Score');
    });
    it('O objeto de metricas deve ter o atributo Data', async () => {
      let response = await cloudFunction.getUrlsMobile();
      expect(response[0]).to.have.own.property('Data');
    });
    it('O objeto de metricas deve ter o atributo Brand', async () => {
      let response = await cloudFunction.getUrlsMobile();
      expect(response[0]).to.have.own.property('Brand');
    });
    it('O objeto de metricas deve ter o atributo Page', async () => {
      let response = await cloudFunction.getUrlsMobile();
      expect(response[0]).to.have.own.property('Page');
    });
  });
});
