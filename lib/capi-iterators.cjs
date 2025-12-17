// JavaScript iterators are best implemented in JavaScript

function container_iterator() {
  const iter = this.iterator();
  const parent = this;
  const r = {
    next() {
      const v = iter.next();
      if (v !== null) {
        // container elements are just pointers in the container
        // keep a reference to the container, otherwise they may become invalid
        Object.defineProperty(v, 'parent', { writable: false, configurable: false, value: parent });
        return { value: v, done: false };
      }
      return { done: true };
    }
  };
  Object.defineProperty(r, 'parent', { writable: false, configurable: false, value: parent });
  return r;
};

function install_iterators(PROJ) {
  PROJ.PROJ_UNIT_INFO_CONTAINER.prototype[Symbol.iterator] = container_iterator;
  PROJ.PROJ_CELESTIAL_BODY_INFO_CONTAINER.prototype[Symbol.iterator] = container_iterator;
  PROJ.PROJ_CRS_INFO_CONTAINER.prototype[Symbol.iterator] = container_iterator;
  return PROJ;
}

module.exports = {
  container_iterator,
  install_iterators
};
