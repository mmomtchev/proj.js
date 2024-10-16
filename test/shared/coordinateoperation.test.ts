import { assert } from 'chai';

import qPROJ from 'proj.js';
import type { Proj } from 'proj.js';

describe('CoordinateOperation with automatic import', () => {
  let PROJ: Awaited<typeof qPROJ>;

  let dbContext: Proj.DatabaseContext;
  let authFactory: Proj.AuthorityFactory;
  let authFactoryEPSG: Proj.AuthorityFactory;
  let coord_op_ctxt: Proj.CoordinateOperationContext;
  let sourceCRS, targetCRS: Proj.CRS;
  let operation: Proj.CoordinateOperation;

  before('init', async () => {
    PROJ = await qPROJ;
    dbContext = PROJ.DatabaseContext.create();
    authFactory = PROJ.AuthorityFactory.create(dbContext, 'string');
    authFactoryEPSG = PROJ.AuthorityFactory.create(dbContext, 'EPSG');
    sourceCRS = authFactoryEPSG.createCoordinateReferenceSystem('4326');
    targetCRS = PROJ.createFromUserInput('+proj=utm +zone=31 +datum=WGS84 +type=crs', dbContext) as Proj.CRS;
    coord_op_ctxt = PROJ.CoordinateOperationContext.create(authFactory, null, 0);
    const list = PROJ.CoordinateOperationFactory.create().createOperations(sourceCRS, targetCRS, coord_op_ctxt);
    operation = list[0];
  });

  it('automatic downcasting / inheritance chain', () => {
    assert.instanceOf(operation, PROJ.CoordinateOperation);
    assert.instanceOf(operation, PROJ.ConcatenatedOperation);

    const ops = (operation as Proj.ConcatenatedOperation).operations();
    assert.isArray(ops);
    assert.isAtLeast(ops.length, 2);
  
    const single = ops[0];
    assert.instanceOf(single, PROJ.Conversion);
    assert.instanceOf(single, PROJ.SingleOperation);
    assert.instanceOf(single, PROJ.CoordinateOperation);
  });

  it('operationVersion (optional string that is empty)', () => {
    const s = operation.operationVersion();
    assert.isNull(s);
  });

  it.skip('formula (optional string that is not empty)', () => {
    // TODO: PROJ returns a dangling pointer for method and ASAN reports a heap overflow
    // Remember to check it, maybe it is not supposed to work
    const ops = (operation as Proj.ConcatenatedOperation).operations();
    const single = ops[0] as Proj.SingleOperation;
    const method = single.method();
    assert.instanceOf(method, PROJ.OperationMethod);
    assert.isString(method.formula());
  });

});
