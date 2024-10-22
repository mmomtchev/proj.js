# proj.js

This is `proj.js` - `PROJ` bindings for JavaScript with a native port for Node.js and WASM port for the browser using SWIG JSE.

This project is completely separate from `proj4js` which is a separate (and partial) ***reimplementation*** in JavaScript.

# Current status

Alpha quality. Most basic functions work as intended. Mostly tested for leaks on the nominal code paths.

Keep in mind that I am only a very occasional user of a very small fraction of `PROJ` and my main interest is JavaScript bindings - Node.js and browser - for C/C++ projects. If you find methods that are not usable in the current version and submit unit tests for it, I will make them work.

# Usage

This package is a `magickwand.js`-style `npm` package with an automatic import that resolves to either the native module or the WASM module depending on the environment.

The following code will import the module:

```js
import qPROJ from 'proj.js';
const PROJ = await qPROJ;
console.log(`proj.db is inlined: ${PROJ.proj_js_inline_projdb}`);
if (!PROJ.proj_js_inline_projdb) {
  const proj_db = new Uint8Array(await (await fetch(proj_db_url)).arrayBuffer());
  PROJ.loadDatabase(proj_db);
}
```

Node.js will pick up the native binary, while a modern bundler such as `webpack` or `rollup` with support for Node.js 16 exports will pick up the WASM module.

This requires ES6, Node.js 16 and a recent `webpack` or `rollup`. If using TypeScript, you will have to transpile to ES6. Most major web components were updated with those features in 2022.

If importing in a legacy CJS environment, you will be limited to using the native module in Node.js only:
```ts
const PROJ = require('proj.js/native');
console.log(`proj.db is inlined: ${PROJ.proj_js_inline_projdb}`);
```

When using the native module, `proj.db` is always external and automatically loaded from `require.resolve('proj.js/lib/binding/proj/proj.db')`.

If using TypeScript, you will need to explicitly import the types in the `PROJ` namespace because `PROJ` is a variable:

```ts
import qPROJ from 'proj.js';
import type * as PROJ from 'proj.js';
const PROJ = await qPROJ;
console.log(`proj.db is inlined: ${PROJ.proj_js_inline_projdb}`);
if (!PROJ.proj_js_inline_projdb) {
  const proj_db = new Uint8Array(await (await fetch(proj_db_url)).arrayBuffer());
  PROJ.loadDatabase(proj_db);
}
```

# Developer build

```shell
npm install 
# Checkout from git
git clone https://github.com/mmomtchev/proj.js.git

# Install all the npm dependencies (this will also pull the latest prebuilt binaries)
cd proj.js
npm install

# If you do not have SWIG JSE installed, download the SWIG generated files
# from a recent GHA run: https://github.com/mmomtchev/proj.js/actions
# (download swig-generated and unzip it in proj.js/swig)
mkdir -p swig && cd swig && unzip ~/Downloads/swig-generated.zip

# If you have SWIG JSE installed, generate the wrappers yourself
npm run swig

# Build the native version (requires a working C++ compiler)
npx xpm run prepare --config native && npx xpm run build --config native

# Build the WASM version (requires emsdk in path)
npx xpm run prepare --config wasm && npx xpm run build --config wasm

# Run the tests (Node.js and browser)
npm test

# Run the web demo
cd test/browser && npx webpack serve --mode=production
# then open http://localhost:8030/
```

# WASM size considerations

When using WASM, `proj.db` can either be inlined in the WASM bundle or it can be loaded from an `Uint8Array` before use.

Currently, the bundle size remains an issue.

| Component | raw | brotli |
| --- | --- | --- |
| `proj.wasm` w/  TIFF w/o `proj.db` | 8593K | 1735K |
| `proj.wasm` w/o TIFF w/o `proj.db` | 7082K | 1302K |
| `proj.db` | 9240K | 1320K |

It should be noted that while using `-Os` in `emscripten` can lead to a two-fold reduction of the raw size, the size of the compressed build will always remain the same. Sames goes for optimizing with `binaryen` - despite the very significant raw size gain, the compressed size gain is relatively insignificant.

`curl` support is enabled only in the native build - there is no simple solution to networking for the WASM build.

Linking with my own `sqlite-wasm-http` project to access a remote `proj.db`, using SQL over HTTP, is a very significant project that will further increase the bundle size to the point nullifying the gains from `proj.db`. It does not seem to be a logical option at the moment.

Currently the biggest contributor to raw code size is SWIG JSE which produces large amounts of identical code for each function. This may me improved in a future version, but bear in mind that SWIG-generated code has the best compression ratio. It is also worth investigating what can be gained from modularization of the SWIG wrappers and if it is really necessary to wrap separately all derived classes.

## WASM Splitting

Starting from version 0.9.1, `proj.js` supports WASM code splitting. This allows to split the module in two parts, a main part that is loaded when the module is initially imported and a secondary part that is lazy-loaded when any function not present in the main part is called. The splitting is performed along the lines of a JavaScript program - any function called by that program will be part of the main part, everything else will remain in the secondary module. A sample JavaScript program that performs only the quickstart is included, using this program results a very decent 40%:60% split:

| Component | raw | brotli |
| --- | --- | --- |
| `proj.wasm` w/ TIFF w/o `proj.db` | 4518K | 766K |
| `proj.deferred.wasm` w/ TIFF w/o `proj.db` | 5152K | 1213K |
| `proj.wasm` w/o TIFF w/o `proj.db` | 3859K | 716K |
| `proj.deferred.wasm` w/o TIFF w/o `proj.db` | 4278K | 829K |
| `proj.db` | 9240K | 1320K |

To split using the default quickstart, run:

```shell
node src/proj-wasm-split.js
```

To split using any other user program, run:

```shell
node src/proj-wasm-split.js <program>
```

# Performance

Initial crude benchmarks, tested on i7 9700K @ 3.6 GHz with the C++ [quickstart](https://proj.org/en/latest/development/quickstart_cpp.html):

| Test | Native | WASM in V8 |
| --- | --- | --- |
| `DatabaseContext.create()` | 0.171ms | 16.316ms |
| `AuthorityFactory.create('string')` | 0.071ms | 0.44ms |
| `CoordinateOperationContext.create()` | 0.052ms | 0.397ms |
| `AuthorityFactory.create('EPSG')` | 0.011ms | 0.274ms |
| `createFromUserInput()`  | 0.283ms | 0.617ms |
| `CoordinateOperationFactory.create().createOperations()` | 0.588ms | 1.885ms |
| `coordinateTransformer()` | 0.29ms | 19.117ms |
| `transform()` | 0.014ms | 0.234ms |

Globally, the first impression is that the library is usable both on the backend and in the browser in fully synchronous mode. The only real hurdle at the moment remains the WASM bundle size.
