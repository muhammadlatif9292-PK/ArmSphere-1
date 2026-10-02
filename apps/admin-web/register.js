import { createRequire } from 'node:module';

if (typeof globalThis.Iterator === 'undefined') {
  const IteratorClass = class Iterator {
    static from(it) {
      return it;
    }
  };
  globalThis.Iterator = IteratorClass;
  if (typeof global !== 'undefined') {
    global.Iterator = IteratorClass;
  }
}

const require = createRequire(import.meta.url);
const wt = require('node:worker_threads');
if (typeof wt.markAsUncloneable !== 'function') {
  wt.markAsUncloneable = () => {};
}
