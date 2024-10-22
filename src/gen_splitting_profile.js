import qPROJ from 'proj.js/wasm';
import assert from 'node:assert';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const PROJ = await qPROJ;

const proj_db_path = resolve(dirname(fileURLToPath(import.meta.url)), '..', 'lib', 'binding', 'proj', 'proj.db');
const proj_db = readFileSync(proj_db_path);
if (!PROJ.proj_js_inline_projdb)
  PROJ.loadDatabase(proj_db);

const dbContext = PROJ.DatabaseContext.create();
const authFactory = PROJ.AuthorityFactory.create(dbContext, 'string');
const coord_op_ctxt = PROJ.CoordinateOperationContext.create(authFactory, null, 0);
const authFactoryEPSG = PROJ.AuthorityFactory.create(dbContext, 'EPSG');
const sourceCRS = authFactoryEPSG.createCoordinateReferenceSystem('4326');
const targetCRS = PROJ.createFromUserInput('+proj=utm +zone=31 +datum=WGS84 +type=crs', dbContext);
const list = PROJ.CoordinateOperationFactory.create().createOperations(sourceCRS, targetCRS, coord_op_ctxt);

const transformer = list[0].coordinateTransformer();
const c0 = new PROJ.PJ_COORD;
c0.v = [49, 2, 0, 0];
const c1 = transformer.transform(c0);
assert(Math.abs(c1.v[0] - 426857.988) < 1e-3);
assert(Math.abs(c1.v[1] - 5427937.523) < 1e-3);

PROJ.swig_em_write_profile();
