// Please note that create-react-app is not supported anymore
// Raw React is stuck at TypeScript 4 which makes using
// proj.js somewhat unpractical

// Modern React using Vite is far better

import React from 'react';
import ReactDOM from 'react-dom/client';

import * as chai from 'chai';

import qPROJ from 'proj.js';

const assert: Chai.AssertStatic = chai.assert;

const root = ReactDOM.createRoot(document.createElement('div'));

function Mocha() {
  it('PROJ quickstart', (done) => {
    qPROJ.then((PROJ) => {
      if (!PROJ.proj_js_inline_projdb) {
        console.log('If you want to inline assets, consider using a modern bundler');
        done();
        return;
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
      // This is very awkward because create-react-app imposes TypeScript 4 which does not support proj.js .d.ts
      // You should consider switching to Vite & TypeScript 5
      const targetCRS = PROJ.createFromUserInput('+proj=utm +zone=31 +datum=WGS84 +type=crs', dbContext) as typeof sourceCRS;
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
      done();
    }).catch(done);
  });
  return <></>;
}

root.render(
  <React.StrictMode>
    <Mocha />
  </React.StrictMode>
);
