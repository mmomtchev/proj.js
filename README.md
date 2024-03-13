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

Does not build

# To trigger the `meson` `cmake` module problem:

Checkout (with submodules), then run in the project root (you don't need SWIG, it bombs out in the dependencies):

```
npm install
python3 -m conans.conan install . -pr:b=default -pr:h=./hadron/system-linux.profile --build=missing -of build/native
meson setup --backend ninja --buildtype release build/native . --native-file build/napi.ini --native-file hadron/system-linux.ini --native-file build/native/conan_meson_native.ini
```

main `meson` build that includes a `CMake` subproject
`conan` produces the dependencies
`CMake` consumes `CMake` config files (via `CMAKE_PREFIX_PATH` from `meson`)
`meson` consumes `pkg-config` files

the `CMake` imported target in `meson` looks like this:

```
TARGET CMake TARGET:
  -- name:      CURL::libcurl
  -- type:      INTERFACE
  -- imported:  True
  -- properties: {
      'INTERFACE_LINK_LIBRARIES': ['CURL::libcurl', 'APPEND']
      'INTERFACE_LINK_OPTIONS': ['', 'APPEND']
      'INTERFACE_INCLUDE_DIRECTORIES': ['', 'APPEND']
      'INTERFACE_LINK_DIRECTORIES': ['', 'APPEND']
      'INTERFACE_COMPILE_DEFINITIONS': ['', 'APPEND']
      'INTERFACE_COMPILE_OPTIONS': ['', 'APPEND']
     }
  -- tline: CMake TRACE: /home/mmom/src/proj.js/build/native/CURLTargets.cmake:11 add_library(['CURL::libcurl', 'INTERFACE', 'IMPORTED'])
```

`APPEND`s appear in the final `meson.build` and prevent the link

Only targets coming from `conan` have this `APPEND` and only when the target is imported in `meson`:

From this `conan` statement:

```
set_property(TARGET sqlite3_SQLite_SQLite3_DEPS_TARGET
              PROPERTY INTERFACE_LINK_LIBRARIES
              $<$<CONFIG:Release>:${sqlite3_SQLite_SQLite3_FRAMEWORKS_FOUND_RELEASE}>
              $<$<CONFIG:Release>:${sqlite3_SQLite_SQLite3_SYSTEM_LIBS_RELEASE}>
              $<$<CONFIG:Release>:${sqlite3_SQLite_SQLite3_DEPENDENCIES_RELEASE}>
              APPEND)
```

`meson` produces:

```
TARGET = [ 'SQLite::SQLite3', 'APPEND' ]
```
