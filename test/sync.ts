import { assert } from 'chai';
import type Native from '..';
import type WASM from '../lib/wasm.mjs';

// These are all the synchronous tests
// They are shared between the Node.js native version and the WASM version
// (the only difference being that WASM must be loaded by resolving its Promise)

export default function (dll: typeof Native | typeof WASM) {
  let bindings: typeof Native;
  if (dll instanceof Promise) {
    before('load WASM', (done) => {
      dll.then((loaded) => {
        bindings = loaded;
        // If proj.db is not inlined, load it in the embedded filesystem
        // In Node.js it comes from wasm.node_js_proj_db.ts
        // In the browser, it comes from run-mocha.ts
        if (loaded.proj_js_build === 'wasm' && !loaded.proj_js_inline_projdb) {
          // @ts-ignore
          const proj_db_q = globalThis.proj_db as Promise<Uint8Array>;
          if (!proj_db_q) {
            return done('proj.db not inlined and not available from the environment');
          }
          return void proj_db_q
            .then((proj_db) => {
              loaded.FS.writeFile('/proj.db', proj_db, { encoding: 'binary' });
              done();
            })
            .catch((e) => void done(e));
        }
        // If proj.db is inlined, there is nothing left to do
        done();
      });
    });
  } else {
    bindings = dll;
  }

  describe('sync', () => {
    it('quickstart', () => {
      console.time('DatabaseContext.create()');
      const dbContext = bindings.DatabaseContext.create();
      console.timeEnd('DatabaseContext.create()');
      console.time('AuthorityFactory.create()');
      const authFactory = bindings.AuthorityFactory.create(dbContext, 'string');
      console.timeEnd('AuthorityFactory.create()');
      console.time('CoordinateOperationContext.create()');
      const coord_op_ctxt = bindings.CoordinateOperationContext.create(authFactory, null, 0);
      console.timeEnd('CoordinateOperationContext.create()');
      console.time('AuthorityFactory.create()');
      const authFactoryEPSG = bindings.AuthorityFactory.create(dbContext, 'EPSG');
      console.timeEnd('AuthorityFactory.create()');
      const sourceCRS = authFactoryEPSG.createCoordinateReferenceSystem('4326');
      console.timeEnd('AuthorityFactory.create()');
      console.time('createFromUserInput()');
      const targetCRS = bindings.createFromUserInput('+proj=utm +zone=31 +datum=WGS84 +type=crs', dbContext);
      console.timeEnd('createFromUserInput()');
      console.time('CoordinateOperationFactory.create().createOperations()');
      const list = bindings.CoordinateOperationFactory.create().createOperations(sourceCRS, targetCRS, coord_op_ctxt);
      console.timeEnd('CoordinateOperationFactory.create().createOperations()');

      console.time('coordinateTransformer()');
      const transformer = list[0].coordinateTransformer();
      const c0 = new bindings.PJ_COORD;
      c0.v = [49, 2, 0, 0];
      const c1 = transformer.transform(c0);
      console.timeEnd('coordinateTransformer()');
      assert.closeTo(c1.v[0], 426857.988, 1e-3);
      assert.closeTo(c1.v[1], 5427937.523, 1e-3);
    });
  });
}
