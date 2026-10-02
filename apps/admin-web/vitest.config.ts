import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import path from 'path';
import { createRequire } from 'node:module';

if (typeof globalThis.Iterator === 'undefined') {
  (globalThis as any).Iterator = class Iterator {};
}

const require = createRequire(import.meta.url);
const wt = require('node:worker_threads');
if (typeof wt.markAsUncloneable !== 'function') {
  wt.markAsUncloneable = () => {};
}

import { pathToFileURL } from 'node:url';

const registerUrl = pathToFileURL(path.resolve(__dirname, './register.js')).href;

if (!process.env.NODE_OPTIONS || !process.env.NODE_OPTIONS.includes(registerUrl)) {
  process.env.NODE_OPTIONS = `${process.env.NODE_OPTIONS || ''} --import ${registerUrl}`.trim();
}

export default defineConfig({
  root: path.resolve(__dirname),
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: [path.resolve(__dirname, './src/test/setup.ts')],
    include: ['src/test/**/*.test.tsx', 'src/test/**/*.test.ts'],
    testTimeout: 20000,
    pool: 'forks',
    poolOptions: {
      execArgv: ['--import', registerUrl],
      forks: {
        singleFork: true,
        execArgv: ['--import', registerUrl],
      },
    },
  },
});
