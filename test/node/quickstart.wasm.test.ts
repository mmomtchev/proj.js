import qPROJ from 'proj.js/wasm';

import quickstart from 'proj.js/quickstart';

describe('quickstart with explicit WASM import', () => {
  let PROJ: Awaited<typeof qPROJ>;
  before('ensure module has finished loading', (done) => {
    qPROJ.then((m) => {
      PROJ = m;
      done();
    }).catch(done);
  });

  it('quickstart', () => quickstart(PROJ));
});
