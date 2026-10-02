import { createRequire } from 'node:module';

if (typeof globalThis.Iterator === 'undefined') {
  globalThis.Iterator = class Iterator {};
}

const require = createRequire(import.meta.url);
const wt = require('node:worker_threads');
if (typeof wt.markAsUncloneable !== 'function') {
  wt.markAsUncloneable = () => {};
}
