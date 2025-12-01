// emnapi Initialization
import * as emnapi from '@emnapi/runtime';

export default function (bindings) {
  return bindings()
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

      if (!mod.proj_js_inline_projdb) {
        mod.loadDatabase = (db) => {
          if (!(db instanceof Uint8Array)) {
            throw new Error('Expected Uint8Array');
          }
          mod.loadDatabase = () => {
            throw new Error('loadDatabase() can be called only once');
          };
          mod.FS.writeFile('/proj.db', db, { encoding: 'binary' });
        };
      }

      return mod;
    });
}
