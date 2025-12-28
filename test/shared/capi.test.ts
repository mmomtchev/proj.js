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
    for (const op of list) {
      assert.instanceOf(op, PROJ.PJ_LIST_ELEMENT);
      assert.isString(op.id);
      assert.isString(op.descr);
      assert.isFunction(op.proj);
      // Alas, some of these operations expect very different types
      // of arguments and simply calling them with a projection
      // or whatever amounts to a very good fuzzing test for PROJ,
      // which obviously sooner or later finds a weak point.
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

    const { result, confidence } = PROJ.proj_identify(pj, null);

    assert.instanceOf(result, PROJ.PJ_OBJ_LIST);
    assert.isArray(confidence);

    assert.isNumber(result.length());
    assert.strictEqual(result.length(), confidence.length);

    assert.isNumber(confidence[0]);
    assert.strictEqual(confidence[0], 100);
    assert.instanceOf(result.get(0), PROJ.PJ);
    assert.strictEqual(result.get(0).parent, result);

    for (const el of result) {
      assert.instanceOf(el, PROJ.PJ);
      assert.strictEqual(el.parent, result);
    }
  });

  it('proj_create_from_name', () => {
    const list = PROJ.proj_create_from_name('EPSG', 'utm', [PROJ.PJ_TYPE_CRS], true, 100);
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
    assert.throws(() => {
      PROJ.proj_create_from_wkt('layman projection', { STRICT: true });
    }, /missing \[/);
  });

  it('proj_create_from_wkt w/o any warning', () => {
    const wkt = 'GEOGCS["WGS 84", DATUM["WGS_1984", SPHEROID["WGS 84", 6378137, 298.257223563, AUTHORITY["EPSG", "7030"]], AUTHORITY["EPSG", "6326"]], PRIMEM["Greenwich", 0, AUTHORITY["EPSG", "8901"]], UNIT["degree", 0.0174532925199433, AUTHORITY["EPSG", "9122"]], AUTHORITY["EPSG", "4326"]]';
    const [pj, warnings] = PROJ.proj_create_from_wkt(wkt, { STRICT: true });
    assert.instanceOf(pj, PROJ.PJ);
    assert.isArray(warnings);
    assert.isEmpty(warnings);
    assert.instanceOf(pj, PROJ.PJ);
  });

  it('PJ_OPERATION_FACTORY_CONTEXT', () => {
    const factory_ctx = PROJ.proj_create_operation_factory_context('EPSG');
    assert.instanceOf(factory_ctx, PROJ.PJ_OPERATION_FACTORY_CONTEXT);

    PROJ.proj_operation_factory_context_set_area_of_interest(factory_ctx,
      -152, -18, -148, -16);
    PROJ.proj_operation_factory_context_set_allow_use_intermediate_crs(factory_ctx,
      PROJ.PROJ_INTERMEDIATE_CRS_USE_IF_NO_DIRECT_TRANSFORMATION);
    PROJ.proj_operation_factory_context_set_desired_accuracy(factory_ctx, 10);
    PROJ.proj_operation_factory_context_set_spatial_criterion(factory_ctx,
      PROJ.PROJ_SPATIAL_CRITERION_STRICT_CONTAINMENT);
    PROJ.proj_operation_factory_context_set_allowed_intermediate_crs(factory_ctx,
      ['EPSG', '4326']);

    const geo = PROJ.proj_create('EPSG:4326');
    const mercator = PROJ.proj_create('EPSG:3857');

    const ops = PROJ.proj_create_operations(geo, mercator, factory_ctx);
    assert.instanceOf(ops, PROJ.PJ_OBJ_LIST);
    assert.isAbove(ops.length(), 0);
    for (const op of ops) {
      assert.instanceOf(op, PROJ.PJ);
      assert.isString(op.toString());
      assert.include(op.toString(), 'Mercator');
    }
  });

  it('proj_coordoperation_get_param / proj_coordoperation_get_info', () => {
    const op = PROJ.proj_create_operations(
      PROJ.proj_create('EPSG:4326'),
      PROJ.proj_create('EPSG:3857'),
      PROJ.proj_create_operation_factory_context('EPSG')).get(0);

    const info = PROJ.proj_coordoperation_get_method_info(op);
    assert.deepStrictEqual(info, {
      method_name: 'Popular Visualisation Pseudo Mercator',
      method_auth_name: 'EPSG',
      method_code: '1024'
    });

    const param = PROJ.proj_coordoperation_get_param(op, 0);
    assert.deepStrictEqual(param, {
      name: 'Latitude of natural origin',
      auth_name: 'EPSG',
      code: '8801',
      value: 0,
      unit_conv_factor: 0.017453292519943295,
      unit_name: 'degree',
      unit_auth_name: 'EPSG',
      unit_code: '9102',
      unit_category: 'angular'
    });
  });

  it('proj_coordoperation_get_towgs84_values', () => {
    const op = PROJ.proj_create_crs_to_crs('EPSG:4326',
      '+proj=latlong +ellps=GRS80 +towgs84=-199.87,74.79,246.62');
    const transform = PROJ.proj_coordoperation_get_towgs84_values(op);
    assert.isArray(transform);
    assert.lengthOf(transform, 3);
    assert.deepStrictEqual(transform, [199.87, -74.79, -246.62]);
  });

  it('proj_ellipsoid_get_parameters', () => {
    const pj = PROJ.proj_get_ellipsoid(PROJ.proj_create('EPSG:4326'));
    const ellipsoid = PROJ.proj_ellipsoid_get_parameters(pj);
    assert.isNumber(ellipsoid.semi_major_metre);
    assert.isNumber(ellipsoid.semi_minor_metre);
    assert.isBoolean(ellipsoid.is_semi_minor_computed);
    assert.isNumber(ellipsoid.inv_flattening);
    assert.closeTo(ellipsoid.inv_flattening, 298, 0.5);
    assert.closeTo(ellipsoid.semi_major_metre / ellipsoid.semi_minor_metre, 1 + 1 / ellipsoid.inv_flattening, 1);
  });

  it('PJ_AREA', () => {
    const area = new PROJ.PJ_AREA(-8.0125, 37.9875, 12.0125, 53.0125);
    area.set_name('AROME');
    const pj = PROJ.proj_create_crs_to_crs('EPSG:4326', 'EPSG:3857', area);
    assert.instanceOf(pj, PROJ.PJ);
    assert.isTrue(PROJ.proj_coordoperation_is_instantiable(pj));
  });

  it('proj_trans_generic', () => {
    const coords = new Float64Array([
      -8.0125000, 53.0125000,
      -8.0125000, 37.9875000,
      12.0125000, 53.0125000,
      12.0125000, 37.9875000,
      2.0000000, 45.5000000
    ]);
    const expected = new Float64Array([
      5901324.505678415, -894868.9412058722,
      4228749.1565094795, -894868.9412058722,
      5901324.505678415, 1347131.021836296,
      4228749.1565094795, 1347131.021836296,
      5065036.831093947, 222684.20850554405
    ]);

    const op = PROJ.proj_create_crs_to_crs('EPSG:4326', 'EPSG:3857');
    PROJ.proj_trans_generic(op, PROJ.PJ_FWD, { data: coords, stride: 2 }, { data: coords, stride: 2, offset: 1 }, { data: 0 }, { data: 0 });
    assert.strictEqual(coords.length, expected.length);
    for (const i in coords)
      assert.closeTo(coords[i], expected[i], 1e-5);
  });
});
