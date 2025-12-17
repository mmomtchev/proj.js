function container_iterator() {
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

module.exports = {
  container_iterator
};
