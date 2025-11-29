import * as native from 'proj.js/native';
import { assert } from 'chai';

// Test explicitly loading the native module from TS
describe('native', () => {
  it('can be imported from TS', () => {
    const db = native.DatabaseContext.create();
    assert.instanceOf(db, native.DatabaseContext);
    assert.isFalse(native.proj_js_inline_projdb);
    // @ts-ignore
    assert.isUndefined(native.loadDatabase);
  });
});
