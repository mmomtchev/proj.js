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

First successful native build, needs SWIG JSE dev branch, a few functions work
Still lots of work in SWIG JSE needed for `dropbox::nn`
