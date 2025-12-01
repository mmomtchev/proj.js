const path = require('path');

module.exports = {
  entry: './index.js',
  output: {
    filename: 'bundle.js',
    path: path.resolve(__dirname, 'build')
  },
  module: {
    rules: [
      // This bundles proj.db if it is not inlined
      {
        test: /proj\.db/,
        type: 'asset/resource'
      }
    ],
  },
  devServer: {
    port: 8030,
    static: {
      directory: __dirname,
    },
    headers: {
      'Cross-Origin-Opener-Policy': 'same-origin',
      'Cross-Origin-Embedder-Policy': 'require-corp'
    }
  }
};
