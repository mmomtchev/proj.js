import native from 'proj.js/native';
import { assert } from 'chai';

// Test explicitly loading the native module from TS

describe('native', () => {
  it('can be imported from JS', () => {
    const db = native.DatabaseContext.create();
    assert.instanceOf(db, native.DatabaseContext);
  });
});
