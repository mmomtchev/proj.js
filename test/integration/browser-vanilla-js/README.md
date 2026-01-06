# Using proj.js from vanilla JS without any bundler

This setup uses `rollup` to create single JS bundle out of the code necessary to use `proj.js`.

Just run the `build` script and `rollup` will produce `build/index.js` which contains `proj.js` registered as `window.proj_js`.
