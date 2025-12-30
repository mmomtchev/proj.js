import { assert } from 'chai';
import qPROJ from 'proj.js';
import type * as PROJ from 'proj.js';

it('TS (transpiled to ES6) import test', (done) => {
  qPROJ.then((PROJ) => {
    const dbContext = PROJ.DatabaseContext.create();
    const authFactory = PROJ.AuthorityFactory.create(dbContext, 'string');
    const coord_op_ctxt = PROJ.CoordinateOperationContext.create(authFactory, null, 0);
    const authFactoryEPSG = PROJ.AuthorityFactory.create(dbContext, 'EPSG');
    const sourceCRS = authFactoryEPSG.createCoordinateReferenceSystem('4326');
    const targetCRS = PROJ.createFromUserInput('+proj=utm +zone=31 +datum=WGS84 +type=crs', dbContext) as PROJ.CRS;
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
