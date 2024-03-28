import { assert } from 'chai';
import type Bindings from '..';

// These are all the synchronous tests
// They are shared between the Node.js native version and the WASM version
// (the only difference being that WASM must be loaded by resolving its Promise)

export default function (dll: (typeof Bindings) | Promise<typeof Bindings>) {
  let bindings: typeof Bindings;
  if (dll instanceof Promise) {
    before('load WASM', (done) => {
      dll.then((loaded) => {
        bindings = loaded;
        done();
      });
    });
  } else {
    bindings = dll;
  }

  describe('sync', () => {
    it('quickstart',() => {
      const dbContext = bindings.DatabaseContext.create();
      const authFactory = bindings.AuthorityFactory.create(dbContext, 'string');
      const coord_op_ctxt = bindings.CoordinateOperationContext.create(authFactory, null, 0);
      const authFactoryEPSG = bindings.AuthorityFactory.create(dbContext, 'EPSG');
      const sourceCRS = authFactoryEPSG.createCoordinateReferenceSystem('4326');
      const targetCRS = bindings.createFromUserInput('+proj=utm +zone=31 +datum=WGS84 +type=crs', dbContext);
      const list = bindings.CoordinateOperationFactory.create().createOperations(sourceCRS, targetCRS, coord_op_ctxt);

      // This should probably be hidden from the user in JavaScript
      const ctx = bindings.proj_context_create();

      const transformer = list[0].coordinateTransformer(ctx);
      const c0 = new bindings.PJ_COORD;
      c0.v = [49, 2, 0, 0];
      const c1 = transformer.transform(c0);
      console.log(c1.v);

      bindings.proj_context_destroy(ctx);
    });
  });
}
