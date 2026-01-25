## 0.9.2 2026-01-25

* Update `PROJ` to 9.7.1
* Render the 3rd and 4rd arguments to the `PJ_COORD` constructor optional
* Accept an array of 2, 3 or 4 numbers for each method expecting a `PJ_COORD`
* Redesign the `proj_get_crs_info_list_from_database` wrapper to accept a single JS object argument with all the search settings
* Update `hadron` to the official 1.1 release and fix compilation with the latest `emsdk`

# 0.9.1 2026-01-03

* Include a second entry point, `proj.js/capi` with the old C API - this module is smaller and the setup is slightly faster
* Migrate to the new `hadron` build system
* Integrate SWIG JSE in the build and support regenerating the wrappers on all supported platforms
* Test the integration of the published package in various environments - you can check the `test/integration` directory for working examples for using this package from Node.js, Webpack, React, Vite and etc...
* New style WASM bundle with separate WASM binaries for Node.js and browsers - the goal is to avoid using Node.js-specific imports in the WASM loader that make using the module with a bundler much harder

# 0.9.0 2025-10-20

* Early preview release
