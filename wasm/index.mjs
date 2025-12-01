/**
 * WASM module exported asynchronously as ES6, imported as:
 * import qPROJ from 'proj.js';
 * const PROJ = await qPROJ;
 * 
 * This is the browser specific WASM bundle
 */
import bindings from '../lib/binding/emscripten-wasm32/proj.mjs';
import emnapi from './emnapi.mjs';

const result = emnapi(bindings);

export default result;
