import WASM from 'proj.js/wasm';
import { assert } from 'chai';

// Test explicitly loading the WASM from JS

describe('WASM', () => {
  let PROJ;

  before('load WASM', (done) => {
    WASM.then((bindings) => {
      PROJ = bindings;
      done();
    })
      .catch(done);
  });

  it('can be imported from JS', () => {
    assert.isFunction(PROJ.DatabaseContext.create);
  });

  it('disallows loading proj.db multiple times', () => {
    assert.throws(() => {
      PROJ.loadDatabase(new Uint8Array(4));
    }, /once/);
  });
});
