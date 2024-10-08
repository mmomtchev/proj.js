# proj.js

This is `proj.js` - `PROJ` bindings for JavaScript with a native port for Node.js and WASM port for the browser using SWIG JSE.

This project is completely separate from `proj4js` which is a separate (and partial) ***reimplementation*** in JavaScript.

# Overview

This SWIG JSE project has several interesting elements:
 * it uses many C++11 advanced features that test the limits of SWIG
 * most of the calculations performed by `PROJ` are very complex but are performed on very small datasets, making it a perfect candidate for a fully synchronous WASM implementation that does not require COOP/COEP and can be easily used in web projects - and a very good optimization target

# Current status

Early prototype.

Both the browser WASM and the Node.js native version compile, there are no prebuilt binaries, no `npm` package, the quickstart example works both in Node.js and in the browser, library may be usable in some cases, there is still no documentation whatsoever.

# Try it yourself

```shell
# Checkout from git
git clone https://github.com/mmomtchev/proj.js.git

# Install all the npm dependencies
cd proj.js
npm install
npx xpm install

# If you do not have SWIG JSE installed, download the SWIG generated files
# from a recent GHA run: https://github.com/mmomtchev/proj.js/actions
# (download swig-generated and unzip it in proj.js/swig)
mkdir -p swig && cd swig && unzip ~/Downloads/swig-generated.zip

# If you have SWIG JSE installed, generated the wrappers yourself
npm run swig

# Build the native version (requires a working C++ compiler)
npm run build:native

# Built the WASM version (requires emscripten in path)
npm run build:wasm

# Run the tests (Node.js and browser)
npm test
```

# WASM size considerations

When using WASM, `proj.db` can either be inlined in the WASM bundle or it can be loaded from an `Uint8Array` before use.

Currently, the bundle size remains an issue.

| Component | raw | brotli |
| --- | --- | --- |
| `proj.wasm` w/  TIFF w/o `proj.db` | 15M | 3187K |
| `proj.wasm` w/o TIFF w/o `proj.db` | 13M | 1580K |
| `proj.db` | 9240K | 1320K |

It should be noted that while using `-Os` in `emscripten` can lead to a two-fold reduction of the raw size, the size of the compressed build will always remain the same.

`curl` support is enabled only in the native build - there is no simple solution to networking for the WASM build.

Linking with my own `sqlite-wasm-http` project to access a remote `proj.db`, using SQL over HTTP, is a very significant project that will further increase the bundle size to the point nullifying the gains from `proj.db`. It does not seem to be a logical option at the moment.
