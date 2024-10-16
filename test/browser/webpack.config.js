import * as path from 'node:path';
import * as process from 'node:process';
import { fileURLToPath } from 'node:url';
import * as glob from 'glob';

// This contains two different builds: the standalone webpage and the mocha bundle

const ignoreWarnings = [
  // These have to be fixed in emscripten
  // https://github.com/emscripten-core/emscripten/issues/20503
  {
    module: /proj.js\..*\.mjs$/,
    message: /dependency is an expression/,
  },
  {
    message: /Circular dependency/
  },
  {
    module: /proj.js\.worker\.js$/,
    message: /dependencies cannot be statically extracted/
  },
  {
    message: /exceed the recommended size limit/
  },
  {
    message: /exceeds the recommended limit/
  },
  {
    message: /You can limit the size of your bundles/
  }
];

export default [
  /**
   * Bundle for a standalone webpage
   * 
   * This is the configuration you need to create a webpage
   */
  {
    entry: './index.ts',
    output: {
      filename: 'bundle.js',
      path: path.resolve(path.dirname(fileURLToPath(import.meta.url)), 'build')
    },
    /**
     * WARNING: Important!
     * 
     * The default js wrapper (proj.js) generated by emscripten - the one that loads
     * the WASM binary - works in every environment. It does so by detecting if it
     * runs in Node.js or in a browser - so that it can know where to load the WASM
     * binary from.
     * 
     * This autodetection makes it reference Node.js-specific extensions that do not
     * exist in a browser which confuses webpack. The following section tells webpack
     * to not expand those statements - we know that these sections won't be executed in
     * the browser since they are dependant on the environment auto-detection.
     * 
     * The list is current for emscripten 3.1.51. Later versions may additional
     * symbols.
     * 
     * Alternatively, if you want to publish a WASM that works without any custom
     * webpack configuration, you can take a look at magickwand.js - magickwand.js
     * explicitly disables the Node.js environment from its WASM binary.
     * 
     * Node.js is best served by the native build anyway.
     * 
     * The emscripten option that does this is:
     *   '-sENVIRONMENT=web,webview,worker'
     */
    externals: {
      'fs': 'fs',
      'worker_threads': 'worker_threads',
      'module': 'module',
      'vm': 'vm',
      './': '"./"'
    },
    module: {
      rules: [
        {
          test: /\.ts$/,
          loader: 'ts-loader',
          exclude: /node_modules/,
          options: {
            onlyCompileBundledFiles: true
          }
        },
        // This bundles proj.db if it is not inlined
        {
          test: /proj\.db/,
          type: 'asset/resource'
        }
      ]
    },
    ignoreWarnings,
    devServer: {
      port: 8030,
      static: {
        directory: path.dirname(fileURLToPath(import.meta.url))
      },
      devMiddleware: {
        'publicPath': '/build'
      },
      headers: process.env.NO_ASYNC ? {} : {
        'Cross-Origin-Opener-Policy': 'same-origin',
        'Cross-Origin-Embedder-Policy': 'require-corp'
      }
    }
  },

  /**
   * Bundle for mocha
   * 
   * This is the configuration you need to create unit tests
   */
  {
    entry: [
      './wasm.browser.proj_db.ts',
      ...glob.sync('./*.test.ts', { absolute: true }),
      ...glob.sync('../shared/*.test.ts')
    ],
    output: {
      filename: 'bundle-mocha.js',
      path: path.resolve(path.dirname(fileURLToPath(import.meta.url)), 'build')
    },
    module: {
      rules: [
        {
          test: /\.ts$/,
          loader: 'ts-loader',
          exclude: /node_modules/,
          options: {
            onlyCompileBundledFiles: true
          }
        },
        // This bundles proj.db if it is not inlined
        {
          test: /proj\.db/,
          type: 'asset/resource'
        }
      ]
    },
    resolve: {
      extensions: ['.ts', '.js'],
      extensionAlias: {
        '.js': ['.js', '.ts'],
      }
    },
    ignoreWarnings,
    externals: {
      'fs': 'fs',
      'worker_threads': 'worker_threads',
      'module': 'module',
      'vm': 'vm',
      './': '"./"'
    }
  }
];
