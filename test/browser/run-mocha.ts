// This runs the mocha tests
import qPROJ from 'proj.js';

// refer to the webpack configuration to ses how this works
// @ts-ignore
import proj_db_url from '../../lib/binding/proj/proj.db';

import quickstart from '../shared/quickstart.js'; 

describe('quickstart from browser', () => {
  before('init', async () => {
    const PROJ = await qPROJ;
    if (!PROJ.proj_js_inline_projdb) {
      console.log(`Loading proj.db from ${proj_db_url}`);
      const proj_db = await fetch(proj_db_url);
      const proj_db_data = new Uint8Array(await proj_db.arrayBuffer());
      PROJ.loadDatabase(proj_db_data);
    }
  });

  quickstart(qPROJ);
});
