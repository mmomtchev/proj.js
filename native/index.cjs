/**
 * Native module exported synchronously as CJS, imported as:
 * const PROJ = require('proj.js')
 */
const process = require('node:process');
const path = require('node:path');
const os = require('node:os');
process.env['PROJ_DATA'] = path.resolve(__dirname, '..', 'lib', 'binding', 'proj');
module.exports = require(path.resolve(__dirname, '..', 'lib', 'binding', `${os.platform()}-${os.arch()}`, 'proj.node'));
