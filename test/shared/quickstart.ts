import { assert } from 'chai';
import qPROJ from 'proj.js';

// This allows for easier access to the TypeScript types
// which are hidden behind a Promise and PROJ is actually a variable
import type * as PROJ from 'proj.js';

// These tests are shared between Node.js and the browser
export default function (_PROJ: typeof qPROJ) {
  let PROJ: Awaited<typeof _PROJ>;
  before('ensure module has finished loading', async () => {
    PROJ = await _PROJ;
  });

  it('quickstart', () => {
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
  });
}
