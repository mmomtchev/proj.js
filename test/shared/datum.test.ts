import { assert } from 'chai';
import { assertInstanceOf } from './chai-workaround.js';

import qPROJ from 'proj.js';
import type * as PROJ from 'proj.js';

describe('Datum with automatic import', () => {
  let PROJ: Awaited<typeof qPROJ>;

  let dbContext: PROJ.DatabaseContext;
  let authFactory: PROJ.AuthorityFactory;
  let authFactoryEPSG: PROJ.AuthorityFactory;
  let crs: PROJ.CRS;
  let geoCRS: PROJ.GeographicCRS;
  let datum: PROJ.GeodeticReferenceFrame;

  before('init', async () => {
    PROJ = await qPROJ;
    dbContext = PROJ.DatabaseContext.create();
    authFactory = PROJ.AuthorityFactory.create(dbContext, 'string');
    authFactoryEPSG = PROJ.AuthorityFactory.create(dbContext, 'EPSG');
    crs = PROJ.createFromUserInput('+proj=longlat +ellps=GRS80 +pm=paris +geoid_crs=WGS84 +type=crs', dbContext) as PROJ.CRS;
    geoCRS = crs.extractGeographicCRS();
    datum = geoCRS.datum();
  });

  it('Datum', () => {
    assertInstanceOf(datum, PROJ.Datum);
  });

  it('Ellipsoid', () => {
    const ellps = geoCRS.ellipsoid();
    assert.instanceOf(ellps, PROJ.Ellipsoid);
    assert.isNumber(ellps.getEPSGCode());
    assert.instanceOf(ellps.semiMajorAxis(), PROJ.Length);
    assert.instanceOf(ellps.inverseFlattening(), PROJ.Scale);
    assert.isNumber(ellps.squaredEccentricity());
    assert.isString(ellps.celestialBody());
  })
});
