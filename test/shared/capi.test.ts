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
    const inp = PROJ.proj_create('EPSG:4326');
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
    assert.instanceOf(list, PROJ.PROJ_UNIT_INFO_CONTAINER);
    let count = 0;
    for (const element of list) {
      count++;
      assert.instanceOf(element, PROJ.PROJ_UNIT_INFO);
      assert.isString(element.auth_name);
      assert.isString(element.category);
      assert.isString(element.name);
      assert.isString(element.code);
      assert.strictEqual(element.parent, list);
    }
    assert.isAbove(count, 0);
  });

  it('proj_get_celestial_body_list_from_database', () => {
    const list = PROJ.proj_get_celestial_body_list_from_database(null);
    assert.instanceOf(list, PROJ.PROJ_CELESTIAL_BODY_INFO_CONTAINER);
    let count = 0;
    for (const element of list) {
      count++;
      assert.instanceOf(element, PROJ.PROJ_CELESTIAL_BODY_INFO);
      assert.isString(element.auth_name);
      assert.isString(element.name);
      assert.strictEqual(element.parent, list);
    }
    assert.isAbove(count, 0);
  });

  it('proj_get_crs_info_list_from_database', () => {
    const list = PROJ.proj_get_crs_info_list_from_database('EPSG', null);
    assert.instanceOf(list, PROJ.PROJ_CRS_INFO_CONTAINER);
    let count = 0;
    for (const element of list) {
      count++;
      assert.instanceOf(element, PROJ.PROJ_CRS_INFO);
      assert.isString(element.auth_name);
      assert.isNumber(element.bbox_valid);
      assert.isBoolean(element.deprecated);
      assert.isNumber(element.west_lon_degree);
      assert.isNumber(element.south_lat_degree);
      assert.isNumber(element.east_lon_degree);
      assert.isNumber(element.north_lat_degree);
      assert.isNumber(element.type);
      assert.strictEqual(element.parent, list);
    }
    assert.isAbove(count, 0);
  });

  it('proj_identify', () => {
    const pj = PROJ.proj_create('EPSG:4326');
    assert.instanceOf(pj, PROJ.PJ);

    const [list, confidence] = PROJ.proj_identify(pj, null, {});

    assert.instanceOf(list, PROJ.PJ_OBJ_LIST);
    assert.isArray(confidence);

    assert.isNumber(list.length());
    assert.strictEqual(list.length(), confidence.length);

    assert.isNumber(confidence[0]);
    assert.strictEqual(confidence[0], 100);
    assert.instanceOf(list.get(0), PROJ.PJ);
    assert.strictEqual(list.get(0).parent, list);

    for (const el of list) {
      assert.instanceOf(el, PROJ.PJ);
      assert.strictEqual(el.parent, list);
    }
  });

  it('proj_create_from_name', () => {
    const list = PROJ.proj_create_from_name('EPSG', 'utm', [ PROJ.PJ_TYPE_CRS ], true, 100, {});
    assert.instanceOf(list, PROJ.PJ_OBJ_LIST);
    assert.isAbove(list.length(), 0);

    const pj = list.get(0);
    assert.instanceOf(pj, PROJ.PJ);

    assert.isString(PROJ.proj_get_id_code(pj, 0));
    assert.isString(PROJ.proj_get_id_auth_name(pj, 0));
    assert.strictEqual(PROJ.proj_get_id_auth_name(pj, 0), 'EPSG');
    assert.isBoolean(PROJ.proj_is_deprecated(pj));
    assert.isTrue(PROJ.proj_is_crs(pj));
    assert.strictEqual(PROJ.proj_get_type(pj), PROJ.PJ_TYPE_PROJECTED_CRS);
  });

  it('proj_get_area_of_use', () => {
    const pj = PROJ.proj_create('EPSG:4326');
    assert.instanceOf(pj, PROJ.PJ);

    const area_of_use = PROJ.proj_get_area_of_use(pj);
    assert.isArray(area_of_use);
    assert.lengthOf(area_of_use, 5);
    assert.isNumber(area_of_use[0]);
    assert.isNumber(area_of_use[1]);
    assert.isNumber(area_of_use[2]);
    assert.isNumber(area_of_use[3]);
    assert.isString(area_of_use[4]);
  });

  it('proj_create_from_wkt with warning', () => {
    // Maybe this should throw with the errors array in the exception?
    const [ pj, warnings, grammar_errors ] = PROJ.proj_create_from_wkt('layman projection', { STRICT: true });
    assert.instanceOf(pj, PROJ.PJ);
    assert.isArray(warnings);
    assert.isArray(grammar_errors);
    assert.isString(grammar_errors[0]);
  });

  it('proj_create_from_wkt w/o any warning', () => {
    const wkt = 'GEOGCS["WGS 84", DATUM["WGS_1984", SPHEROID["WGS 84", 6378137, 298.257223563, AUTHORITY["EPSG", "7030"]], AUTHORITY["EPSG", "6326"]], PRIMEM["Greenwich", 0, AUTHORITY["EPSG", "8901"]], UNIT["degree", 0.0174532925199433, AUTHORITY["EPSG", "9122"]], AUTHORITY["EPSG", "4326"]]';
    const [pj, warnings, grammar_errors] = PROJ.proj_create_from_wkt(wkt, { STRICT: true });
    assert.instanceOf(pj, PROJ.PJ);
    assert.isArray(warnings);
    assert.isArray(grammar_errors);
    assert.isEmpty(grammar_errors);
    assert.instanceOf(pj, PROJ.PJ);
  });
});
