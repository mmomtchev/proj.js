import * as emnapi from '@emnapi/runtime';
import bindings from './binding/proj.mjs';

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
        return mod;
    });

export default result;
