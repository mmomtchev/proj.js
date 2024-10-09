// This is the index.js of the web page demo

import qPROJ from 'proj.js';

// refer to the webpack configuration to ses how this works
// @ts-ignore
import proj_db_url from '../../lib/binding/proj/proj.db';

console.log('Hello from WASM');

function print(msg: string) {
  const div = document.createElement('div');
  const text = document.createTextNode(msg);
  div.appendChild(text);
  document.getElementsByTagName('body')[0].appendChild(div);
}

print('Loading WASM');
(async function () {
  const PROJ = await qPROJ;
  print('WASM loaded and transpiled');
  console.log('WASM', PROJ);

  print(`proj.db is inlined: ${PROJ.proj_js_inline_projdb}`);

  if (!PROJ.proj_js_inline_projdb) {
    const proj_db = await fetch(proj_db_url);
    const proj_db_data = new Uint8Array(await proj_db.arrayBuffer());
    PROJ.loadDatabase(proj_db_data);
    print(`loaded proj.db from ${proj_db_url}`);
  }

  const dbContext = PROJ.DatabaseContext.create();
  const authFactory = PROJ.AuthorityFactory.create(dbContext, 'string');
  const coord_op_ctxt = PROJ.CoordinateOperationContext.create(authFactory, null, 0);
  const authFactoryEPSG = PROJ.AuthorityFactory.create(dbContext, 'EPSG');
  const sourceCRS = authFactoryEPSG.createCoordinateReferenceSystem('4326');
  const targetCRS = PROJ.createFromUserInput('+proj=utm +zone=31 +datum=WGS84 +type=crs', dbContext);
  const list = PROJ.CoordinateOperationFactory.create().createOperations(sourceCRS, targetCRS, coord_op_ctxt);

  const transformer = list[0].coordinateTransformer();
  const c0 = new PROJ.PJ_COORD;
  c0.v = [49, 2, 0, 0];
  const c1 = transformer.transform(c0);

  print(`Successfully converted ${c0.v} from EPSG:4326 to UTM WGS84 -> ${c1.v}`);
})();
