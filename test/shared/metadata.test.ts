import { assert } from 'chai';

import qPROJ from 'proj.js';
import type * as PROJ from 'proj.js';

describe('metadata with automatic import', () => {
  let PROJ: Awaited<typeof qPROJ>;

  let dbContext: PROJ.DatabaseContext;
  let authFactory: PROJ.AuthorityFactory;
  let authFactoryEPSG: PROJ.AuthorityFactory;

  before('init', async () => {
    PROJ = await qPROJ;
    dbContext = PROJ.DatabaseContext.create();
    authFactory = PROJ.AuthorityFactory.create(dbContext, 'string');
    authFactoryEPSG = PROJ.AuthorityFactory.create(dbContext, 'EPSG');
  });

  it('static properties', () => {
    assert.isString(PROJ.Identifier.AUTHORITY_KEY);
    assert.isString(PROJ.Identifier.CODESPACE_KEY);
  });

  it('IdentifiedObject properties', () => {
    const crs = authFactoryEPSG.createCoordinateReferenceSystem('3857');
    const metadata = crs.identifiers();
    assert.isArray(metadata);
    for (const m of metadata) {
      assert.instanceOf(m, PROJ.Identifier);
      assert.instanceOf(m, PROJ.BaseObject);
      assert.isString(m.code());
      assert.isString(m.codeSpace());
      assert.strictEqual(m.code(), '3857');
      assert.strictEqual(m.codeSpace(), 'EPSG');
      assert.isNull(m.authority());
      assert.isNull(m.uri());
    }
  });

});
