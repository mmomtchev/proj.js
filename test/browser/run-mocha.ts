// This runs all the mocha tests in the browser using karma

// @ts-ignore
import proj_db from '../../lib/binding/proj/proj.db'

// @ts-ignore
globalThis.proj_db = fetch(proj_db)
  .then((r) => r.arrayBuffer())
  .then((r) => new Uint8Array(r));

import '../wasm.sync.test.js'; 
import '../wasm.async.test.js';
