const process = require('node:process');
const path = require('node:path');
const os = require('node:os');
process.env['PROJ_DATA'] = path.resolve(__dirname, 'binding', 'proj');
module.exports = require(path.resolve(__dirname, 'binding', `${os.platform()}-${os.arch()}`, 'proj_wrap.cjs'));
