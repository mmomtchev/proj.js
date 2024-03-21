import { assert } from 'chai';
import type Bindings from '..';

// These are all the asynchronous tests
// They are shared between the Node.js native version and the WASM version
// (the only difference being that WASM must be loaded by resolving its Promise)

export default function (dll: (typeof Bindings) | Promise<typeof Bindings>, no_async: boolean) {
  let bindings: typeof Bindings;
  if (dll instanceof Promise) {
    before('load WASM', (done) => {
      dll.then((loaded) => {
        bindings = loaded;
        done();
      });
    });
  } else {
    bindings = dll;
  }

  it(`async is ${no_async ? 'disabled' : 'enabled'}`, () => {
  });

  describe('async', () => {
    bindings;
  });
}
