const { assert } = require('chai');
const chai = require('chai');
const expect = chai.expect;
const uuid = require('uuid');
process.env.PROJECT_BUCKET_GCS = 'site_speed_dashboard_test';
process.env.PSI_KEY = process.env.PSI_KEY || '';

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
    it('Deve retornar um objeto de metricas do PSI', async () => {
      let response = await cloudFunction.getUrlsDesktop();
      expect(response).to.be.an('object').that.not.empty;
      expect(response.speedResults[0]).to.have.own.property('Data');
      expect(response.speedResults[0]).to.have.own.property('Brand');
      expect(response.speedResults[0]).to.have.own.property('Page');
      expect(response.speedResults[0]).to.have.own.property('Site');
      expect(response.speedResults[0]).to.have.own.property('Device');
      expect(response.speedResults[0]).to.have.own.property('Score');
      expect(response.speedResults[0]).to.have.own.property('LAB_FCP');
      expect(response.speedResults[0]).to.have.own.property('LAB_FMP');
      expect(response.speedResults[0]).to.have.own.property('LAB_FCPUIdle');
      expect(response.speedResults[0]).to.have.own.property('LAB_SpeedIndex');
      expect(response.speedResults[0]).to.have.own.property('LAB_TTI');
      expect(response.speedResults[0]).to.have.own.property('LAB_InputLatency');
      expect(response.speedResults[0]).to.have.own.property('LAB_TTFB');
      expect(response.speedResults[0]).to.have.own.property('LAB_RenderBlocking');
      expect(response.speedResults[0]).to.have.own.property('LAB_TBT');
      expect(response.speedResults[0]).to.have.own.property('LAB_CLS');
      expect(response.speedResults[0]).to.have.own.property('LAB_LCP');
      expect(response.speedResults[0]).to.have.own.property('LAB_FID');
    });
  });

  describe('#getUrlsMobile()', () => {
    it('Deve ser uma function', () => {
      assert.isFunction(cloudFunction.getUrlsMobile);
    });
    it('Deve retornar um objeto de metricas do PSI', async () => {
      let response = await cloudFunction.getUrlsMobile();
      expect(response).to.be.an('object').that.not.empty;
      expect(response.speedResults[0]).to.have.own.property('Data');
      expect(response.speedResults[0]).to.have.own.property('Brand');
      expect(response.speedResults[0]).to.have.own.property('Page');
      expect(response.speedResults[0]).to.have.own.property('Site');
      expect(response.speedResults[0]).to.have.own.property('Device');
      expect(response.speedResults[0]).to.have.own.property('Score');
      expect(response.speedResults[0]).to.have.own.property('LAB_FCP');
      expect(response.speedResults[0]).to.have.own.property('LAB_FMP');
      expect(response.speedResults[0]).to.have.own.property('LAB_FCPUIdle');
      expect(response.speedResults[0]).to.have.own.property('LAB_SpeedIndex');
      expect(response.speedResults[0]).to.have.own.property('LAB_TTI');
      expect(response.speedResults[0]).to.have.own.property('LAB_InputLatency');
      expect(response.speedResults[0]).to.have.own.property('LAB_TTFB');
      expect(response.speedResults[0]).to.have.own.property('LAB_RenderBlocking');
      expect(response.speedResults[0]).to.have.own.property('LAB_TBT');
      expect(response.speedResults[0]).to.have.own.property('LAB_CLS');
      expect(response.speedResults[0]).to.have.own.property('LAB_LCP');
      expect(response.speedResults[0]).to.have.own.property('LAB_FID');
    });
  });
});
