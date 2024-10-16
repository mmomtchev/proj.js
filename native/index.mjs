/**
 * Native module exported asynchronously as ES6, imported as:
 * import qPROJ from 'proj.js';
 * const PROJ = await qPROJ;
 */
import _PROJ from '../swig/proj_wrap.cjs';

const PROJ = Promise.resolve(_PROJ);

export default PROJ;
