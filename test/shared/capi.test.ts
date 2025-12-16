// This is the mocha entry point for some C API functions.
// These tests are shared between Node.js and the browser.
import qPROJ from 'proj.js/capi';
import type * as PROJ from 'proj.js';

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

  it('proj_list_ellps', () => {
    const list = PROJ.proj_list_ellps();
    assert.isArray(list);
    assert.isAtLeast(list.length, 10);
    for (const op of list) {
      assert.instanceOf(op, PROJ.PJ_ELLPS);
      assert.isString(op.id);
      assert.isString(op.major);
      assert.isString(op.name);
    }
  });

  it('proj_get_authorities_from_database', () => {
    const list = PROJ.proj_get_authorities_from_database();
    assert.isArray(list);
    assert.isAbove(list.length, 0);
    for (const element of list) {
      assert.isString(element);
    }
  });

  it('proj_get_codes_from_database', () => {
    const list = PROJ.proj_get_codes_from_database('EPSG', PROJ.PJ_TYPE_CRS, true);
    assert.isArray(list);
    assert.isAbove(list.length, 0);
    for (const element of list) {
      assert.isString(element);
    }
  });

  it('proj_get_units_from_database', () => {
    const list = PROJ.proj_get_units_from_database(null, null, true);
    assert.isArray(list);
    assert.isAbove(list.length, 0);
    for (const element of list) {
      assert.instanceOf(element, PROJ.PROJ_UNIT_INFO);
      assert.isString(element.auth_name);
      assert.isString(element.category);
      assert.isString(element.name);
      assert.isString(element.code);
    }
  });

  it('proj_get_celestial_body_list_from_database', () => {
    const list = PROJ.proj_get_celestial_body_list_from_database(null);
    // nothing here?
    assert.isArray(list);
    for (const element of list) {
      assert.instanceOf(element, PROJ.PROJ_CELESTIAL_BODY_INFO);
      assert.isString(element.auth_name);
      assert.isString(element.name);
    }
  });

  it('proj_get_crs_info_list_from_database', () => {
    const list = PROJ.proj_get_crs_info_list_from_database('EPSG', null);
    assert.isArray(list);
    assert.isAbove(list.length, 0);
    for (const element of list) {
      assert.instanceOf(element, PROJ.PROJ_CRS_INFO);
      assert.isString(element.auth_name);
      assert.isNumber(element.bbox_valid);
      assert.isBoolean(element.deprecated);
      assert.isNumber(element.west_lon_degree);
      assert.isNumber(element.south_lat_degree);
      assert.isNumber(element.east_lon_degree);
      assert.isNumber(element.north_lat_degree);
    }
  });
});
