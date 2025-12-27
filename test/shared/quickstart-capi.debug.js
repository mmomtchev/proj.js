// This is the debugging target, see launch.json

import quickstart from './quickstart-capi.mjs';
import qPROJ from 'proj.js/capi';

qPROJ.then((PROJ) => quickstart(PROJ));

