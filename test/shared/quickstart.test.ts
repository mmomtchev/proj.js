// This is the mocha entry point for the default tests.
// These tests are shared between Node.js and the browser.
import qPROJ from 'proj.js';

import quickstart from 'proj.js/quickstart';

describe('quickstart with automatic import', () => {
  let PROJ: Awaited<typeof qPROJ>;
  before('ensure module has finished loading', (done) => {
    qPROJ.then((m) => {
      PROJ = m;
      done();
    }).catch(done);
  });

  it('quickstart', () => quickstart(PROJ));
});
