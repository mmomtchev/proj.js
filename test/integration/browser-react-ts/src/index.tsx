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
      const dbContext = PROJ.DatabaseContext.create();
      const authFactory = PROJ.AuthorityFactory.create(dbContext, 'string');
      const coord_op_ctxt = PROJ.CoordinateOperationContext.create(authFactory, null, 0);
      const authFactoryEPSG = PROJ.AuthorityFactory.create(dbContext, 'EPSG');
      const sourceCRS = authFactoryEPSG.createCoordinateReferenceSystem('4326');
      // This is very awkward because create-react-app imposes TypeScript 4 which does not support proj.js .d.ts
      // You should consider switching to Vite & TypeScript 5
      const targetCRS = PROJ.createFromUserInput('+proj=utm +zone=31 +datum=WGS84 +type=crs', dbContext) as typeof sourceCRS;
      const list = PROJ.CoordinateOperationFactory.create().createOperations(sourceCRS, targetCRS, coord_op_ctxt);

      const transformer = list[0].coordinateTransformer();
      const c0 = new PROJ.PJ_COORD;
      c0.v = [49, 2, 0, 0];
      const c1 = transformer.transform(c0);
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
