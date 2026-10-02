import { createRequire } from 'node:module';

if (typeof (globalThis as any).Iterator === 'undefined') {
  (globalThis as any).Iterator = class Iterator {
    static from(it: any) {
      return it;
    }
  };
}

const require = createRequire(import.meta.url);
const wt = require('node:worker_threads');
if (typeof wt.markAsUncloneable !== 'function') {
  wt.markAsUncloneable = () => {};
}
