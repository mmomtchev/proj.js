import WASM from 'proj.js/wasm';
import { assert } from 'chai';

// Test explicitly loading the WASM from JS

describe('WASM', () => {
  it('can be imported from JS', (done) => {
    WASM
      .then((bindings) => {
        assert.isFunction(bindings.DatabaseContext.create);
        done();
      })
      .catch(done);
  });
});
