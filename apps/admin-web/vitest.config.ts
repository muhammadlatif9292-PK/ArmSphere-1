import './polyfill.cjs';
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import path from 'path';

const polyfillPath = path.resolve(__dirname, './polyfill.cjs');

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
    setupFiles: [polyfillPath],
    include: ['src/test/**/*.test.tsx', 'src/test/**/*.test.ts'],
    testTimeout: 20000,
    pool: 'forks',
    poolOptions: {
      forks: {
        singleFork: true,
        execArgv: ['--require', polyfillPath],
      },
    },
  },
});
