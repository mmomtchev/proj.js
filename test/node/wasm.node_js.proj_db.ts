import * as fs from 'node:fs';
import * as path from 'node:path';
import * as process from 'node:process';
import { fileURLToPath } from 'node:url';
import { assert } from 'chai';
import qPROJ from 'proj.js/wasm';

// This loads proj.db into the environment in Node.js
// when it hasn't been already inlined.

// When using tsx it can be affected by
// https://github.com/privatenumber/tsx/issues/499
// (the top-level await will force a transpilation
// and a double module loading)

async function loadProjDb() {
  const PROJ = await qPROJ;
  if (PROJ.proj_js_inline_projdb)
    return;
  const proj_db_path = process.env.PROJ_DB_PATH ?
    process.env.PROJ_DB_PATH : 
    path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..', 'lib', 'binding', 'proj', 'proj.db');
  // eslint-disable-next-line no-console
  console.log(`Loading proj.db from ${proj_db_path}`);
  const proj_db_data = await fs.promises.readFile(proj_db_path);
  assert.throws(() => {
    // @ts-expect-error
    PROJ.loadDatabase('text');
  }, /Uint8Array/);
  PROJ.loadDatabase(proj_db_data);
}

export const mochaHooks = {
  beforeAll: loadProjDb,

  // This forces the GC to run after each test if the interfaces is exposed.
  // It is used mainly for ASAN testing.
  afterEach: globalThis.gc ? globalThis.gc : () => { }
};
