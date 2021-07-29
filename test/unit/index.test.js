/**?
describe(): It's used to group, which you can nest as deep;
it(): It's the test case;
before(): It's a hook to run before the first it() or describe();
beforeEach(): It’s a hook to run before each it() or describe();
after(): It’s a hook to run after it() or describe();
afterEach(): It’s a hook to run after each it() or describe(); 
 */

const { assert } = require('chai');
const chai = require('chai');
const expect = chai.expect;
const uuid = require('uuid');
process.env.PROJECT_BUCKET_GCS = 'teste-raft-suite';

const cloudFunction = require('./../../index');

describe('Template Cloud Function', () => {
  describe('#templateCf()', () => {
    it('Deve ser uma function', () => {
      assert.isFunction(cloudFunction.templateCf);
    });
    it('Deve processar req e resp retornando http status code 400', async () => {
      const req = {
        query: {},
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
        status: (s) => {
          tmpFunctionStatus(s);
          return { send: () => {} };
        },
      };

      await cloudFunction.templateCf(req, res);
      assert.strictEqual(tmpResponse.status, 400);
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

      await cloudFunction.templateCf(req, res);
      assert.strictEqual(tmpResponse.status, 204);
    });
    it('Deve processar req e resp retornando http status code 200', async () => {
      const req = {
        query: { schema: 'global' },
        body: [
          {
            usuario: { idUsuario: '24413751' },
          },
        ],
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

      await cloudFunction.templateCf(req, res);
      assert.strictEqual(tmpResponse.status, 200);
    });
  });

  describe('#createSchemaBq()', () => {
    let array = [{ att: 'a' }, { att: 'b' }];
    let obj = { c: 'c' };
    let string = 'teste';

    it('Deve ser uma function', () => {
      assert.isFunction(cloudFunction.createSchemaBq);
    });
    it('Deve retornar um array com objetos', () => {
      expect(cloudFunction.createSchemaBq(array, obj, string)).to.be.an('array').that.not.empty;
    });
    it('Array deve ter objeto com a propriedade data', () => {
      expect(cloudFunction.createSchemaBq(array, obj, string)[0]).to.have.own.property('data');
    });
    it('Array deve ter objeto com a propriedade schema', () => {
      expect(cloudFunction.createSchemaBq(array, obj, string)[1]).to.have.own.property('schema');
    });
  });

  describe('#addTimestamp()', () => {
    let patternTimestamp = /^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})$/;
    let obj = { attr: 'attr' };
    it('Deve ser uma function', () => {
      assert.isFunction(cloudFunction.addTimestamp);
    });

    it('Deve possuir o atributo data', () => {
      expect(cloudFunction.addTimestamp(obj)).to.have.own.property('data');
    });
    it('Data deve estar no padrão yyyy-mm-ddThh:mm:ss', () => {
      expect(patternTimestamp.test(cloudFunction.addTimestamp(obj).data)).to.be.true;
    });
  });

  describe('#loadProjectConfig()', () => {
    it('Deve retornar o objeto de configuração', async () => {
      expect(await cloudFunction.loadProjectConfig()).to.have.own.property('DEPARA_SCHEMA');
    });
  });
});
