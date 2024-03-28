const process = require('node:process');
const path = require('node:path');
process.env['PROJ_DATA'] = path.resolve(__dirname, 'binding');
module.exports = require('./binding/proj_wrap.cjs');
