import * as path from 'node:path';
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
      ...glob.sync('../shared/*.test.ts', { posix: true })
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
    ignoreWarnings
  }
];
