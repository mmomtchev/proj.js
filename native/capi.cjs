/**
 * Native module for the C API
 */
const process = require('node:process');
const path = require('node:path');
const os = require('node:os');
process.env['PROJ_DATA'] = path.resolve(__dirname, '..', 'lib', 'binding', 'proj');
module.exports = require(path.resolve(__dirname, '..', 'lib', 'binding', `${os.platform()}-${os.arch()}`, 'proj_capi.node'));


// Iterators are best implemented in JavaScript
const container_iterator = require('../lib/capi-iterators.cjs');

module.exports.PROJ_UNIT_INFO_CONTAINER.prototype[Symbol.iterator] = container_iterator;
module.exports.PROJ_CELESTIAL_BODY_INFO_CONTAINER.prototype[Symbol.iterator] = container_iterator;
module.exports.PROJ_CRS_INFO_CONTAINER.prototype[Symbol.iterator] = container_iterator;
