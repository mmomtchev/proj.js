import qPROJ from 'proj.js/wasm';
const PROJ = await qPROJ;

import quickstart from '../shared/quickstart.js';
describe('quickstart with explicit WASM import', () => {
  quickstart(PROJ);
});
