// This is the index.js of the web page demo

import WASM from '../../lib/wasm.mjs';

console.log('Hello from WASM');

function print(msg) {
  const div = document.createElement('div');
  const text = document.createTextNode(msg);
  div.appendChild(text);
  document.getElementsByTagName('body')[0].appendChild(div);
}

print('Loading WASM');
WASM.then((bindings) => {
  print('WASM loaded and transpiled');
  console.log('WASM', bindings);

  const dbContext = bindings.DatabaseContext.create();
  const authFactory = bindings.AuthorityFactory.create(dbContext, 'string');
  const coord_op_ctxt = bindings.CoordinateOperationContext.create(authFactory, null, 0);
  const authFactoryEPSG = bindings.AuthorityFactory.create(dbContext, 'EPSG');
  const sourceCRS = authFactoryEPSG.createCoordinateReferenceSystem('4326');
  const targetCRS = bindings.createFromUserInput('+proj=utm +zone=31 +datum=WGS84 +type=crs', dbContext);
  const list = bindings.CoordinateOperationFactory.create().createOperations(sourceCRS, targetCRS, coord_op_ctxt);

  const transformer = list[0].coordinateTransformer();
  const c0 = new bindings.PJ_COORD;
  c0.v = [49, 2, 0, 0];
  const c1 = transformer.transform(c0);

  print(`Successfully converted ${c0.v} from EPSG:4326 to UTM WGS84 -> ${c1.v}`);
});
