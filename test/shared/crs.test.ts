import { assert } from 'chai';
import { assertInstanceOf } from './chai-workaround.js';

import qPROJ from 'proj.js';
import type * as PROJ from 'proj.js';

describe('CRS with automatic import', () => {
  let PROJ: Awaited<typeof qPROJ>;

  let dbContext: PROJ.DatabaseContext;
  let authFactory: PROJ.AuthorityFactory;

  before('init', async () => {
    PROJ = await qPROJ;
    dbContext = PROJ.DatabaseContext.create();
    authFactory = PROJ.AuthorityFactory.create(dbContext, 'EPSG');
  });

  it('identify', () => {
    const crs = authFactory.createCoordinateReferenceSystem('4326');
    assertInstanceOf(crs, PROJ.CRS);

    assert.lengthOf(crs.identify(authFactory), 0);
    const id = crs.identify(authFactory);
    assert.lengthOf(id, 1);
    assertInstanceOf(id[0][0], PROJ.CRS);
    assert.strictEqual(id[0][1], 100);
  });

  it('identify (return std::list of std::pair)', () => {
    const crs = authFactory.createCoordinateReferenceSystem('4326');
    assertInstanceOf(crs, PROJ.CRS);

    assert.lengthOf(crs.identify(authFactory), 0);
    const id = crs.identify(authFactory);
    assert.lengthOf(id, 1);
    assertInstanceOf(id[0][0], PROJ.CRS);
    assert.strictEqual(id[0][1], 100);
  });

  it('canonicalBounds (return NULL CRS reference)', () => {
    const crs = authFactory.createCoordinateReferenceSystem('4326');
    assertInstanceOf(crs, PROJ.CRS);

    const bounds = crs.canonicalBoundCRS();
    assert.isNull(bounds);
  });

  it('createFromUserInput (automatic downcasting / inheritance chain)', () => {
    const crs = PROJ.createFromUserInput('+proj=utm +zone=31 +datum=WGS84 +type=crs', dbContext);
    assert.instanceOf(crs, PROJ.BaseObject);
    assertInstanceOf(crs, PROJ.CRS);
    assert.instanceOf(crs, PROJ.ProjectedCRS);
  });

  it('isDynamic (return bool)', () => {
    const crs = authFactory.createCoordinateReferenceSystem('3857');
    assert.isBoolean(crs.isDynamic());
  });

  it('getCRSInfoList() (return a structured object from a C++ struct)', () => {
    const list = authFactory.getCRSInfoList();
    assert.isArray(list);
    assert.strictEqual(list[0].authName, 'EPSG');
    assert.isString(list[0].code);
    assert.isNumber(list[0].east_lon_degree);
  });

  it('extract GeographicCRS (return CRS)', () => {
    const crs = authFactory.createCoordinateReferenceSystem('3857');
    const geographic = crs.extractGeographicCRS();
    assertInstanceOf(geographic, PROJ.CRS);
    assertInstanceOf(geographic, PROJ.SingleCRS);
    assert.instanceOf(geographic, PROJ.GeographicCRS);
  });

});
