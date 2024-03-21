import native from '../lib/native.cjs';
import { assert } from 'chai';

// This test can be run either in Node.js or in the browser
// npx run test:nodejs
// npx run test:browser

describe('native', () => {
  it('can be imported from JS', () => {
    const db = native.DatabaseContext.create();
    assert.instanceOf(db, native.DatabaseContext);
  });
});
