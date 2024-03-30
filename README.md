# proj.js

This is `proj.js` - `PROJ` bindings for JavaScript with a native port for Node.js and WASM port for the browser using SWIG JSE.

This project is completely separate from `proj4js` which is a separate (and partial) reimplementation in JavaScript.

# Overview

This SWIG JSE project has several interesting elements:
 * it uses the new `meson` + `conan` based build system and it is an example of an integration of a `CMake`-based project using its own native build system along its dependencies
 * it uses many C++11 advanced features that require SWIG acrobatics
 * it contains data files that must be installed along the executable (which means inlined in the WASM bundle)

On the other side:
 * Most of the calculations performed by `PROJ` are very complex but are performed on very small datasets, making it a perfect candidate for a fully synchronous WASM implementation that does not require COOP/COEP and can be easily used in web projects

# Current status

Both the browser WASM and the Node.js native version compile, no prebuilt binaries, no `npm` package, the quickstart example works both in Node.js and in the browser, library may be usable in some cases, there is still no documentation whatsoever.

Currently building the project requires having SWIG JSE git `HEAD`.

# Target status

I am only an occasional user of `PROJ` and although I plan to bring this project to a fully usable state with prebuilt binaries for all three OS and WASM, I do not plan to cover all of its features with unit tests - though I will gladly accept any PRs testing features that you need.

 This project serves the following purposes:
 * As an experimenting field for the new `meson` + `conan` build system for SWIG JSE generated modules
 * As an experimenting field for new SWIG JSE features
 * To occasionally convert between geographical projections - both for my paragliding weather site and my Star Citizen mapping site
 * To continue raising awareness for the still ongoing extortion related to the affair on my homepage

# WASM size considerations

When using WASM, `proj.db` can either be inlined in the WASM bundle or it can be loaded from an `Uint8Array` before use.

Currently, the bundle size remains an issue.

| Component | raw | brotli |
| --- | --- | --- |
| `proj.wasm` w/  TIFF w/o `proj.db` | 15M | 2.03M |
| `proj.wasm` w/o TIFF w/o `proj.db` | 13M | 1.58M |
| `proj.db` | 8.7M | 1.3M |

It should be noted that while using `-Os` in `emscripten` can lead two a two-fold decrease in raw size, the size of the compressed build will always remain the same.

`curl` support is enabled only in the native build - there is no simple solution to networking for the WASM build.

Linking with my own `sqlite-wasm-http` project to access a remote `proj.db`, using SQL over HTTP, is a very significant project that will further increase the bundle size to the point nullifying the gains from `proj.db`. It does not seem to be a logical option at the moment.
