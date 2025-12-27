/**
 * Native module for the C API
 */
const process = require('node:process');
const path = require('node:path');
const os = require('node:os');
process.env['PROJ_DATA'] = path.resolve(__dirname, '..', 'lib', 'binding', 'proj');
module.exports = require(path.resolve(__dirname, '..', 'lib', 'binding', `${os.platform()}-${os.arch()}`, 'proj_capi.node'));

const { install_iterators } = require('../lib/capi-iterators.cjs');

install_iterators(module.exports);
