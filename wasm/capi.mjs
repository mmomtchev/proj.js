/**
 * WASM module exported asynchronously as ES6, imported as:
 * import qPROJ from 'proj.js';
 * const PROJ = await qPROJ;
 * 
 * This is the browser specific WASM bundle
 */
import bindings from '../lib/binding/emscripten-wasm32/proj_capi.mjs';
import emnapi from './emnapi.mjs';
import { container_iterator } from '../lib/capi-iterators.cjs';

const result = emnapi(bindings).then((PROJ) => {
  PROJ.PROJ_UNIT_INFO_CONTAINER.prototype[Symbol.iterator] = container_iterator;
  PROJ.PROJ_CELESTIAL_BODY_INFO_CONTAINER.prototype[Symbol.iterator] = container_iterator;
  PROJ.PROJ_CRS_INFO_CONTAINER.prototype[Symbol.iterator] = container_iterator;
  return PROJ;
});

export default result;
