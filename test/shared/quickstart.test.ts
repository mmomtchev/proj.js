import qPROJ from 'proj.js';
const PROJ = await qPROJ;

import quickstart from './quickstart.js';
describe('quickstart with automatic import', () => {
  quickstart(PROJ);
});
