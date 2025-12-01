import * as chai from 'chai';
import chaiAsPromised from 'chai-as-promised';

chai.use(chaiAsPromised);
const assert: Chai.AssertStatic = chai.assert;

/** 
 * TS transpiled to CJS cannot use the automatic import (it requires ES6).
 * If you transpile to CJS, you will have to manually select the
 * right version - Node.js native or browser WASM.
 * 
 * Also, in the particular case of browser TypeScript transpiled to
 * CJS, you will have to switch your module resolution to node16.
 *
 * Consider migrating to ES6, in 2024 the tools have evolved and most
 * of the problems of the early days have been solved. TS transpiled to
 * ES6 offers numerous advantages for both browser and Node.js code.
 */
import qPROJ from 'proj.js/wasm';
type PROJ = Awaited<typeof qPROJ>;

describe('PROJ', () => {
  it('PROJ quickstart', () =>
    qPROJ.then((PROJ: PROJ) => {
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
