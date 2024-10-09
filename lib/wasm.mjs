/**
 * WASM module exported asynchronously as ES6, imported as:
 * import qPROJ from 'proj.js';
 * const PROJ = await qPROJ;
 */
import * as emnapi from '@emnapi/runtime';
import bindings from './binding/emscripten-wasm32/proj.mjs';

const result = bindings()
    .then((m) => {
        const mod = m.emnapiInit({ context: emnapi.getDefaultContext() });
        // Optional, allows the calling JS code to interact with
        // the embedded file system
        Object.defineProperty(mod, 'FS', {
            value: m.FS,
            enumerable: true,
            configurable: false,
            writable: false
        });

        mod.loadDatabase = (db) => {
            if (!(db instanceof Uint8Array)) {
                throw new Error('Expected Uint8Array');
            }
            mod.loadDatabase = () => {
                throw new Error('loadDatabase() can be called only once');
            };
            mod.FS.writeFile('/proj.db', db, { encoding: 'binary' });
        };

        return mod;
    });

export default result;
