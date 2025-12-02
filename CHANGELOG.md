# 0.9.1

* Migrate to the new `hadron` build system
* Integrate SWIG JSE in the build and support regenerating the wrappers on all supported platforms
* Test the integration of the published package in various environments - you can check the `test/integration` directory for working examples for using this package from Node.js, Webpack, React, Vite and etc...
* New style WASM bundle with separate WASM binaries for Node.js and browsers - the goal is to avoid using Node.js-specific imports in the WASM loader that make using the module with a bundler much harder

# 0.9.0 2025-10-20

* Early preview release
