/**
 * Native module for the C API
 */
const process = require('node:process');
const path = require('node:path');
const os = require('node:os');
process.env['PROJ_DATA'] = path.resolve(__dirname, '..', 'lib', 'binding', 'proj');
module.exports = require(path.resolve(__dirname, '..', 'lib', 'binding', `${os.platform()}-${os.arch()}`, 'proj_capi.node'));


// Iterators are best implemented in JavaScript

function container_iterator () {
  const iter = this.iterator();
  const parent = this;
  const r = {
    next() {
      const v = iter.next();
      if (v !== null) {
        // container elements are just pointers in the container
        // keep a reference to the container, otherwise they may become invalid
        Object.defineProperty(v, 'parent', { writable: false, value: parent });
        return { value: v, done: false };
      }
      return { done: true };
    }
  };
  Object.defineProperty(r, 'parent', { writable: false, value: parent });
  return r;
};

module.exports.PROJ_UNIT_INFO_CONTAINER.prototype[Symbol.iterator] = container_iterator;
module.exports.PROJ_CELESTIAL_BODY_INFO_CONTAINER.prototype[Symbol.iterator] = container_iterator;
module.exports.PROJ_CRS_INFO_CONTAINER.prototype[Symbol.iterator] = container_iterator;
