import native from '../lib/native.cjs';
import { assert } from 'chai';

// This test is exclusive to Node.js
// npx run test:nodejs

describe('native', () => {
  it('can be imported from JS', () => {
    const db = native.DatabaseContext.create();
    assert.instanceOf(db, native.DatabaseContext);
  });
});
