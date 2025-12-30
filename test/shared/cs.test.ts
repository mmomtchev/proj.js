import { assert } from 'chai';
import { assertInstanceOf } from './chai-workaround.js';

import qPROJ from 'proj.js';
import type * as PROJ from 'proj.js';

describe('CoordinateSystem with automatic import', () => {
  let PROJ: Awaited<typeof qPROJ>;

  let dbContext: PROJ.DatabaseContext;
  let authFactory: PROJ.AuthorityFactory;
  let crs: PROJ.CRS;
  let geoCRS: PROJ.GeographicCRS;

  before('init', async () => {
    PROJ = await qPROJ;
    dbContext = PROJ.DatabaseContext.create();
    authFactory = PROJ.AuthorityFactory.create(dbContext, 'EPSG');
    crs = authFactory.createCoordinateReferenceSystem('3857');
    geoCRS = crs.extractGeographicCRS();
  });

  it('class constructor inheritance', () => {
    assertInstanceOf(PROJ.EllipsoidalCS, PROJ.CoordinateSystem.constructor);
    assertInstanceOf(PROJ.SphericalCS, PROJ.CoordinateSystem.constructor);
    assertInstanceOf(PROJ.CartesianCS, PROJ.CoordinateSystem.constructor);
    assertInstanceOf(PROJ.VerticalCS, PROJ.CoordinateSystem.constructor);
    assertInstanceOf(PROJ.AffineCS, PROJ.CoordinateSystem.constructor);
    assertInstanceOf(PROJ.OrdinalCS, PROJ.CoordinateSystem.constructor);
    assertInstanceOf(PROJ.ParametricCS, PROJ.CoordinateSystem.constructor);
    assertInstanceOf(PROJ.TemporalCS, PROJ.CoordinateSystem.constructor);
    assertInstanceOf(PROJ.DateTimeTemporalCS, PROJ.CoordinateSystem.constructor);
    assertInstanceOf(PROJ.TemporalCS, PROJ.CoordinateSystem.constructor);
    assertInstanceOf(PROJ.TemporalMeasureCS, PROJ.CoordinateSystem.constructor);
  });

  it('static properties', () => {
    assert.instanceOf(PROJ.AxisDirection.NORTH, PROJ.AxisDirection);
    assert.instanceOf(PROJ.RangeMeaning.EXACT, PROJ.RangeMeaning);
  });

  it('extract CoordinateSystem', () => {
    const cs = geoCRS.coordinateSystem();
    assert.instanceOf(cs, PROJ.BaseObject);
    assertInstanceOf(cs, PROJ.CoordinateSystem);
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
    const axis = PROJ.CoordinateSystemAxis.create({
      'name': 'Garga',
      [PROJ.Identifier.CODE_KEY]: '1337',
      [PROJ.Identifier.AUTHORITY_KEY]: 'DeadCow',
      [PROJ.Identifier.EPSG]: false
    }, 'axis', PROJ.AxisDirection.NORTH_EAST, PROJ.UnitOfMeasure.METRE, null);
    assert.instanceOf(axis, PROJ.CoordinateSystemAxis);
    assert.isNull(axis.meridian());
    assert.isTrue(axis.unit().equal(PROJ.UnitOfMeasure.METRE));
    assert.isFalse(axis.unit().equal(PROJ.UnitOfMeasure.DEGREE));
  });
});
