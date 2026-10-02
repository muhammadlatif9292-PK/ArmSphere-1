import { createRequire } from 'node:module';

if (typeof (globalThis as any).Iterator === 'undefined') {
  const IteratorClass = class Iterator {
    static from(it: any) {
      return it;
    }
  };
  (globalThis as any).Iterator = IteratorClass;
  if (typeof (global as any) !== 'undefined') {
    (global as any).Iterator = IteratorClass;
  }
}

const require = createRequire(import.meta.url);
const wt = require('node:worker_threads');
if (typeof wt.markAsUncloneable !== 'function') {
  wt.markAsUncloneable = () => {};
}
