import { assert } from 'chai';
import { assertInstanceOf } from './chai-workaround.js';

import qPROJ from 'proj.js';
import type * as PROJ from 'proj.js';

describe('CoordinateOperation with automatic import', () => {
  let PROJ: Awaited<typeof qPROJ>;

  let dbContext: PROJ.DatabaseContext;
  let authFactory: PROJ.AuthorityFactory;
  let authFactoryEPSG: PROJ.AuthorityFactory;
  let coord_op_ctxt: PROJ.CoordinateOperationContext;
  let sourceCRS, targetCRS: PROJ.CRS;
  let operation: PROJ.CoordinateOperation;

  before('init', async () => {
    PROJ = await qPROJ;
    dbContext = PROJ.DatabaseContext.create();
    authFactory = PROJ.AuthorityFactory.create(dbContext, 'string');
    authFactoryEPSG = PROJ.AuthorityFactory.create(dbContext, 'EPSG');
    sourceCRS = authFactoryEPSG.createCoordinateReferenceSystem('4326');
    targetCRS = PROJ.createFromUserInput('+proj=utm +zone=31 +datum=WGS84 +type=crs', dbContext) as PROJ.CRS;
    coord_op_ctxt = PROJ.CoordinateOperationContext.create(authFactory, null, 0);
    const list = PROJ.CoordinateOperationFactory.create().createOperations(sourceCRS, targetCRS, coord_op_ctxt);
    operation = list[0];
  });

  it('automatic downcasting / inheritance chain', () => {
    assertInstanceOf(operation, PROJ.CoordinateOperation);
    assert.instanceOf(operation, PROJ.ConcatenatedOperation);

    const ops = (operation as PROJ.ConcatenatedOperation).operations();
    assert.isArray(ops);
    assert.isAtLeast(ops.length, 2);
  
    const single = ops[0];
    assert.instanceOf(single, PROJ.Conversion);
    assertInstanceOf(single, PROJ.SingleOperation);
    assertInstanceOf(single, PROJ.CoordinateOperation);
  });

  it('operationVersion (optional string that is empty)', () => {
    const s = operation.operationVersion();
    assert.isNull(s);
  });

  it.skip('formula (optional string that is not empty)', () => {
    // TODO: PROJ returns a dangling pointer for method and ASAN reports a heap overflow
    // Remember to check it, maybe it is not supposed to work
    const ops = (operation as PROJ.ConcatenatedOperation).operations();
    const single = ops[0] as PROJ.SingleOperation;
    const method = single.method();
    assert.instanceOf(method, PROJ.OperationMethod);
    assert.isString(method.formula());
  });

});
