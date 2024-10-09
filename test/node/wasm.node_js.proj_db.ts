import * as fs from 'node:fs';
import * as path from 'node:path';
import { fileURLToPath } from 'node:url';
import qPROJ from 'proj.js/wasm';
const PROJ = await qPROJ;

// This loads proj.db into the environment in Node.js
// when it hasn't been already inlined

async function loadProjDb() {
  const proj_db_path = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..', 'lib', 'binding', 'proj', 'proj.db');
  console.log(`Loading proj.db from ${proj_db_path}`);
  const proj_db_data = await fs.promises.readFile(proj_db_path);
  PROJ.loadDatabase(proj_db_data);
}

export const mochaHooks = {
  beforeAll: PROJ.proj_js_inline_projdb ? () => {} : loadProjDb
};
