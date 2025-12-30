import * as chai from 'chai';

const assert: Chai.AssertStatic = chai.assert;

import qPROJ from 'proj.js';
import qPROJ_CAPI from 'proj.js/capi';
import type * as PROJ from 'proj.js';

// @ts-ignore
import proj_db_url from 'proj.js/proj.db?url';

// This loads proj.db into the environment
// when it hasn't been already inlined
async function loadProjDb(PROJ: Awaited<typeof qPROJ | typeof qPROJ_CAPI>) {
  // eslint-disable-next-line no-console
  console.log(`Loading proj.db from ${proj_db_url}`);
  const proj_db_data = new Uint8Array(await (await fetch(proj_db_url)).arrayBuffer());
  // eslint-disable-next-line no-console
  console.log(`Downloaded ${proj_db_data.length} bytes`);
  assert.throws(() => {
    // @ts-expect-error
    PROJ.loadDatabase('text');
  }, /Uint8Array/);
  PROJ.loadDatabase(proj_db_data);
}

describe('PROJ', () => {
  before('load proj.db', (done) => {
    qPROJ.then((PROJ) => {
      if (!PROJ.proj_js_inline_projdb) {
        loadProjDb(PROJ).then(() => done()).catch(done);
      } else {
        // eslint-disable-next-line no-console
        console.log('proj.db is inlined in the WASM bundle');
        done();
      }
    }).catch(done);
  });

  it('PROJ quickstart', () =>
    qPROJ.then((PROJ) => {
      const dbContext = PROJ.DatabaseContext.create();
      const authFactory = PROJ.AuthorityFactory.create(dbContext, 'string');
      const coord_op_ctxt = PROJ.CoordinateOperationContext.create(authFactory, null, 0);
      const authFactoryEPSG = PROJ.AuthorityFactory.create(dbContext, 'EPSG');
      const sourceCRS = authFactoryEPSG.createCoordinateReferenceSystem('4326');
      const targetCRS = PROJ.createFromUserInput('+proj=utm +zone=31 +datum=WGS84 +type=crs', dbContext) as PROJ.CRS;
      const list = PROJ.CoordinateOperationFactory.create().createOperations(sourceCRS, targetCRS, coord_op_ctxt);

      const transformer = list[0].coordinateTransformer();
      const c0 = new PROJ.PJ_COORD;
      c0.v = [49, 2, 0, 0];
      const c1 = transformer.transform(c0);
      assert.closeTo(c1.v[0], 426857.988, 1e-3);
      assert.closeTo(c1.v[1], 5427937.523, 1e-3);
    })
  );

  describe('PROJ', () => {
    before('load proj.db', (done) => {
      qPROJ_CAPI.then((PROJ) => {
        if (!PROJ.proj_js_inline_projdb) {
          loadProjDb(PROJ).then(() => done()).catch(done);
        } else {
          // eslint-disable-next-line no-console
          console.log('proj.db is inlined in the WASM bundle');
          done();
        }
      }).catch(done);
    });

    it('PROJ C-API quickstart', () =>
      qPROJ_CAPI.then((PROJ) => {
        const P = PROJ.proj_create_crs_to_crs(
          'EPSG:4326', '+proj=utm +zone=32 +datum=WGS84');
        assert.instanceOf(P, PROJ.PJ);

        const norm = PROJ.proj_normalize_for_visualization(P);
        assert.instanceOf(norm, PROJ.PJ);

        const a = PROJ.proj_coord(12, 55, 0, 0);
        assert.instanceOf(a, PROJ.PJ_COORD);

        const b = PROJ.proj_trans(P, PROJ.PJ_FWD, a);
        assert.instanceOf(b, PROJ.PJ_COORD);

        const c = PROJ.proj_trans(P, PROJ.PJ_INV, b);
        assert.instanceOf(c, PROJ.PJ_COORD);

        assert.closeTo(c.lp.lam, 12, 1e-5);
        assert.closeTo(c.lp.phi, 55, 1e-5);
      })
    );
  });
});
