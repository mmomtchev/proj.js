const { nodeResolve } = require('@rollup/plugin-node-resolve');
const { importMetaAssets } = require('@web/rollup-plugin-import-meta-assets');
const copy = require('rollup-plugin-copy');

module.exports = {
  input: 'proj.js',
  output: {
    dir: 'build',
    format: 'umd',
    name: 'proj_js'
  },
  plugins: [
    nodeResolve({ browser: true }),
    // This is what bundles the WASM
    importMetaAssets(),
    // This is what copies proj.db
    copy({
      targets: [
        { src: require.resolve('proj.js/proj.db'), dest: 'build/assets' }
      ],
      verbose: true
    })
  ]
};
