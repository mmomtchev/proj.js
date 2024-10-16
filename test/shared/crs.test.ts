import { assert } from 'chai';

import qPROJ from 'proj.js';
import type * as TPROJ from 'proj.js/native';

describe('CRS with automatic import', () => {
  let PROJ: Awaited<typeof qPROJ>;

  let dbContext: TPROJ.DatabaseContext;
  let authFactory: TPROJ.AuthorityFactory;
  let authFactoryEPSG: TPROJ.AuthorityFactory;

  before('init', async () => {
    PROJ = await qPROJ;
    dbContext = PROJ.DatabaseContext.create();
    authFactory = PROJ.AuthorityFactory.create(dbContext, 'string');
    authFactoryEPSG = PROJ.AuthorityFactory.create(dbContext, 'EPSG');
  });

  it('identify', () => {
    const crs = authFactoryEPSG.createCoordinateReferenceSystem('4326');
    assert.instanceOf(crs, PROJ.CRS);

    assert.lengthOf(crs.identify(authFactory), 0);
    const id = crs.identify(authFactoryEPSG);
    assert.lengthOf(id, 1);
    assert.instanceOf(id[0][0], PROJ.CRS);
    assert.strictEqual(id[0][1], 100);
  });

  it('identify (return std::list of std::pair)', () => {
    const crs = authFactoryEPSG.createCoordinateReferenceSystem('4326');
    assert.instanceOf(crs, PROJ.CRS);

    assert.lengthOf(crs.identify(authFactory), 0);
    const id = crs.identify(authFactoryEPSG);
    assert.lengthOf(id, 1);
    assert.instanceOf(id[0][0], PROJ.CRS);
    assert.strictEqual(id[0][1], 100);
  });

  it('canonicalBounds (return NULL CRS reference)', () => {
    const crs = authFactoryEPSG.createCoordinateReferenceSystem('4326');
    assert.instanceOf(crs, PROJ.CRS);

    const bounds = crs.canonicalBoundCRS();
    assert.isNull(bounds);
  });

  it('createFromUserInput (automatic downcasting)', () => {
    const crs = PROJ.createFromUserInput('+proj=utm +zone=31 +datum=WGS84 +type=crs', dbContext);
    assert.instanceOf(crs, PROJ.ProjectedCRS);
  });
});
