import * as chai from 'chai';

const assert: Chai.AssertStatic = chai.assert;

import qPROJ from 'proj.js';
import type * as PROJ from 'proj.js';

// @ts-ignore
import proj_db_url from 'proj.js/proj.db?url';

// This loads proj.db into the environment
// when it hasn't been already inlined
async function loadProjDb(PROJ: Awaited<typeof qPROJ>) {
  console.log(`Loading proj.db from ${proj_db_url}`);
  const proj_db_data = new Uint8Array(await (await fetch(proj_db_url)).arrayBuffer());
  console.log(`Downloaded ${proj_db_data.length} bytes`);
  assert.throws(() => {
    PROJ.loadDatabase('text' as any);
  }, /Uint8Array/);
  PROJ.loadDatabase(proj_db_data);
}

describe('PROJ', () => {
  before('load proj.db', (done) => {
    qPROJ.then((PROJ) => {
      if (!PROJ.proj_js_inline_projdb) {
        loadProjDb(PROJ).then(() => done()).catch(done);
      } else {
        console.log('proj.db is inlined in the WASM bundle');
        done();
      }
    }).catch(done);
  });

  it('PROJ quickstart', () =>
    qPROJ.then((PROJ) => {
      console.time('DatabaseContext.create()');
      const dbContext = PROJ.DatabaseContext.create();
      console.timeEnd('DatabaseContext.create()');
      console.time('AuthorityFactory.create()');
      const authFactory = PROJ.AuthorityFactory.create(dbContext, 'string');
      console.timeEnd('AuthorityFactory.create()');
      console.time('CoordinateOperationContext.create()');
      const coord_op_ctxt = PROJ.CoordinateOperationContext.create(authFactory, null, 0);
      console.timeEnd('CoordinateOperationContext.create()');
      console.time('AuthorityFactory.create()');
      const authFactoryEPSG = PROJ.AuthorityFactory.create(dbContext, 'EPSG');
      console.timeEnd('AuthorityFactory.create()');
      const sourceCRS = authFactoryEPSG.createCoordinateReferenceSystem('4326');
      console.timeEnd('AuthorityFactory.create()');
      console.time('createFromUserInput()');
      const targetCRS = PROJ.createFromUserInput('+proj=utm +zone=31 +datum=WGS84 +type=crs', dbContext) as PROJ.CRS;
      console.timeEnd('createFromUserInput()');
      console.time('CoordinateOperationFactory.create().createOperations()');
      const list = PROJ.CoordinateOperationFactory.create().createOperations(sourceCRS, targetCRS, coord_op_ctxt);
      console.timeEnd('CoordinateOperationFactory.create().createOperations()');

      console.time('coordinateTransformer()');
      const transformer = list[0].coordinateTransformer();
      console.timeEnd('coordinateTransformer()');
      const c0 = new PROJ.PJ_COORD;
      c0.v = [49, 2, 0, 0];
      console.time('transform()');
      const c1 = transformer.transform(c0);
      console.timeEnd('transform()');
      assert.closeTo(c1.v[0], 426857.988, 1e-3);
      assert.closeTo(c1.v[1], 5427937.523, 1e-3);
    })
  );
});
