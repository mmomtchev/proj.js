/**
 * Karma for the main browser unit tests set
 */

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
    files: [
      { pattern: 'build/bundle-mocha.js', included: true },
      { pattern: 'build/*', served: true, included: false }
    ],
    exclude: [
    ],
    preprocessors: {
    },
    reporters: ['verbose'],
    port: 9876,
    colors: true,
    logLevel: config.LOG_INFO,
    autoWatch: false,
    browsers: ['Chrome'],
    singleRun: true,
    concurrency: Infinity,
    failOnEmptyTestSuite: true
  });
};
