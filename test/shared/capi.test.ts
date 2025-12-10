// This is the mocha entry point for some C API functions.
// These tests are shared between Node.js and the browser.
import qPROJ from 'proj.js/capi';

import { assert } from 'chai';

describe('C-API special typemaps', () => {
  let PROJ: Awaited<typeof qPROJ>;
  before('ensure module has finished loading', (done) => {
    qPROJ.then((m) => {
      PROJ = m;
      done();
    }).catch(done);
  });

  it('proj_list_operations', () => {
    const list = PROJ.proj_list_operations();
    assert.isArray(list);
    assert.isAtLeast(list.length, 10);
    const inp = PROJ.proj_create_crs_to_crs(
      'EPSG:4326', '+proj=utm +zone=32 +datum=WGS84',
      null);
    assert.instanceOf(inp, PROJ.PJ);
    for (const op of list) {
      assert.instanceOf(op, PROJ.PJ_LIST_ELEMENT);
      assert.isString(op.id);
      assert.isString(op.descr);
      assert.isFunction(op.proj);
      const outp = op.proj(inp);
      assert.instanceOf(outp, PROJ.PJ);
    }
  });
});
