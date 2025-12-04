import { assert } from 'chai';

import qPROJ from 'proj.js';

// TODO: Check if there is a more elegant solution with rollup
const proj_db_url = new URL('./node_modules/proj.js/lib/binding/proj/proj.db', import.meta.url);

// This loads proj.db into the environment
// when it hasn't been already inlined
async function loadProjDb(PROJ) {
  console.log(`Loading proj.db from ${proj_db_url}`);
  const proj_db_data = new Uint8Array(await (await fetch(proj_db_url)).arrayBuffer());
  console.log(`Downloaded ${proj_db_data.length} bytes`);
  assert.throws(() => {
    PROJ.loadDatabase('text');
  }, /Uint8Array/);
  PROJ.loadDatabase(proj_db_data);
}

qPROJ.then(async (PROJ) => {
  if (!PROJ.proj_js_inline_projdb) {
    await loadProjDb(PROJ);
  } else {
    console.log('proj.db is inlined in the WASM bundle');
  }

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
  console.time('AuthorityFactory.createCoordinateReferenceSystem()');
  const sourceCRS = authFactoryEPSG.createCoordinateReferenceSystem('4326');
  console.timeEnd('AuthorityFactory.createCoordinateReferenceSystem()');
  console.time('createFromUserInput()');
  const targetCRS = PROJ.createFromUserInput('+proj=utm +zone=31 +datum=WGS84 +type=crs', dbContext);
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
  window.testDone();
}).catch(window.testDone);
