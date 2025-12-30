/**
 * WASM module exported asynchronously as ES6, imported as:
 * import qPROJ from 'proj.js';
 * const PROJ = await qPROJ;
 * 
 * This is the browser specific WASM bundle
 */
import bindings from '../lib/binding/emscripten-wasm32/proj_capi.mjs';
import emnapi from './emnapi.mjs';
import { install_iterators } from '../lib/capi-iterators.cjs';

const result = emnapi(bindings).then(install_iterators);

export default result;
