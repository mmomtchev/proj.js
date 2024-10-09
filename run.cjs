const bindings = require('./lib/native.cjs');

const dbContext = bindings.DatabaseContext.create();
const authFactory = bindings.AuthorityFactory.create(dbContext, 'string');
const coord_op_ctxt = bindings.CoordinateOperationContext.create(authFactory, null, 0);
const authFactoryEPSG = bindings.AuthorityFactory.create(dbContext, 'EPSG');
const sourceCRS = authFactoryEPSG.createCoordinateReferenceSystem('4326');
const targetCRS = bindings.createFromUserInput('+proj=utm +zone=31 +datum=WGS84 +type=crs', dbContext);
const list = bindings.CoordinateOperationFactory.create().createOperations(sourceCRS, targetCRS, coord_op_ctxt);

const transformer = list[0].coordinateTransformer();
const c0 = new bindings.PJ_COORD;
c0.v = [ 49, 2, 0, 0 ];
const c1 = transformer.transform(c0);
console.log(c1.v);
