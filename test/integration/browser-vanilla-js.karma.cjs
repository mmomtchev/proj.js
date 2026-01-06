//
// rollup + ESM
//

module.exports = function (config) {
  config.set({
    basePath: '',
    frameworks: ['mocha'],
    client: {
      mocha: {
        reporter: 'html',
        timeout: 40000
      }
    },
    // Order is important here
    files: [
      { pattern: 'browser-vanilla-js/build/index.js', included: true },
      { pattern: 'browser-vanilla-js/index.js', included: true },
      { pattern: 'browser-vanilla-js/build/assets/*', served: true, included: false }
    ],
    exclude: [
    ],
    preprocessors: {
    },
    reporters: ['progress'],
    port: 9876,
    colors: true,
    logLevel: config.LOG_INFO,
    autoWatch: false,
    browsers: ['ChromeHeadless'],
    singleRun: true,
    concurrency: Infinity
  });
};
