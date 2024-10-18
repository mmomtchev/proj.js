import { assert } from 'chai';

import qPROJ from 'proj.js';
import type * as PROJ from 'proj.js';

describe('CoordinateSystem with automatic import', () => {
  let PROJ: Awaited<typeof qPROJ>;

  let dbContext: PROJ.DatabaseContext;
  let authFactory: PROJ.AuthorityFactory;
  let authFactoryEPSG: PROJ.AuthorityFactory;
  let crs: PROJ.CRS;
  let geoCRS: PROJ.GeographicCRS;

  before('init', async () => {
    PROJ = await qPROJ;
    dbContext = PROJ.DatabaseContext.create();
    authFactory = PROJ.AuthorityFactory.create(dbContext, 'string');
    authFactoryEPSG = PROJ.AuthorityFactory.create(dbContext, 'EPSG');
    crs = authFactoryEPSG.createCoordinateReferenceSystem('3857');
    geoCRS = crs.extractGeographicCRS();
  });

  it('class constructor inheritance', () => {
    assert.instanceOf(PROJ.EllipsoidalCS, PROJ.CoordinateSystem.constructor);
    assert.instanceOf(PROJ.SphericalCS, PROJ.CoordinateSystem.constructor);
    assert.instanceOf(PROJ.CartesianCS, PROJ.CoordinateSystem.constructor);
    assert.instanceOf(PROJ.VerticalCS, PROJ.CoordinateSystem.constructor);
    assert.instanceOf(PROJ.AffineCS, PROJ.CoordinateSystem.constructor);
    assert.instanceOf(PROJ.OrdinalCS, PROJ.CoordinateSystem.constructor);
    assert.instanceOf(PROJ.ParametricCS, PROJ.CoordinateSystem.constructor);
    assert.instanceOf(PROJ.TemporalCS, PROJ.CoordinateSystem.constructor);
    assert.instanceOf(PROJ.DateTimeTemporalCS, PROJ.CoordinateSystem.constructor);
    assert.instanceOf(PROJ.TemporalCS, PROJ.CoordinateSystem.constructor);
    assert.instanceOf(PROJ.TemporalMeasureCS, PROJ.CoordinateSystem.constructor);
  });

  it('static properties', () => {
    assert.instanceOf(PROJ.AxisDirection.NORTH, PROJ.AxisDirection);
    assert.instanceOf(PROJ.RangeMeaning.EXACT, PROJ.RangeMeaning);
  });

  it('extract CoordinateSystem', () => {
    const cs = geoCRS.coordinateSystem();
    assert.instanceOf(cs, PROJ.BaseObject);
    assert.instanceOf(cs, PROJ.CoordinateSystem);
    assert.instanceOf(cs, PROJ.EllipsoidalCS);
  });

  it('CoordinateSystemAxis', () => {
    const cs = geoCRS.coordinateSystem();
    const axis = cs.axisList();
    assert.isArray(axis);
    assert.isAbove(axis.length, 0);
    axis.forEach((ax) => {
      assert.instanceOf(ax, PROJ.CoordinateSystemAxis);
      if (ax.meridian() !== null)
        assert.instanceOf(ax.meridian(), PROJ.Meridian);
      assert.instanceOf(ax.name(), PROJ.Identifier);
      assert.instanceOf(ax.unit(), PROJ.UnitOfMeasure);
    });
  });

  it('create w/ PropertyMap', () => {
    // TODO: PropertyMap can be an automatic JS object
    const pmap = new PROJ.PropertyMap();
    pmap.set(PROJ.Identifier.CODE_KEY, '1337');
    pmap.set(PROJ.Identifier.AUTHORITY_KEY, 'DeadCow');
    pmap.set(PROJ.Identifier.EPSG, false);
    const axis = PROJ.CoordinateSystemAxis.create(pmap, 'axis', PROJ.AxisDirection.NORTH_EAST, PROJ.UnitOfMeasure.METRE, null);
    assert.instanceOf(axis, PROJ.CoordinateSystemAxis);
    assert.isNull(axis.meridian());
    assert.isTrue(axis.unit().equal(PROJ.UnitOfMeasure.METRE));
  });
});
