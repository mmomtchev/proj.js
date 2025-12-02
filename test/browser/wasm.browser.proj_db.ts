// This loads proj.db into globalThis for the mocha tests
// It is the entry point for the browser test webpack bundle
import qPROJ from 'proj.js';

// This together with the related item in the webpack.config.cjs
// allows to bundle proj.db and returns its URL
// Maybe you won't be doing this in real life and maybe you will
// be loading your own proj.db from your own URL
// Or you may be using the WASM bundle with the proj.db inlined
// @ts-ignore
import proj_db_url from 'proj.js/proj.db';

mocha.setup({
  rootHooks: {
    beforeAll: async () => {
      const PROJ = await qPROJ;
      if (!PROJ.proj_js_inline_projdb) {
        console.log(`Loading proj.db from ${proj_db_url}`);
        const proj_db = await fetch(proj_db_url);
        const proj_db_data = new Uint8Array(await proj_db.arrayBuffer());
        PROJ.loadDatabase(proj_db_data);
      }
    }
  }
});
