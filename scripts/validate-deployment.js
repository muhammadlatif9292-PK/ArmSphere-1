#!/usr/bin/env node

/**
 * Deployment Validation Script
 * Validates all critical components before production deployment
 */

import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  cyan: '\x1b[36m',
};

const log = {
  pass: (msg) => console.log(`${colors.green}✓${colors.reset} ${msg}`),
  fail: (msg) => console.log(`${colors.red}✗${colors.reset} ${msg}`),
  warn: (msg) => console.log(`${colors.yellow}⚠${colors.reset} ${msg}`),
  info: (msg) => console.log(`${colors.cyan}ℹ${colors.reset} ${msg}`),
};

const checks = {
  passed: 0,
  failed: 0,
  warnings: 0,
};

// Helper functions
const fileExists = (filePath) => {
  try {
    return fs.statSync(filePath).isFile();
  } catch {
    return false;
  }
};

const dirExists = (dirPath) => {
  try {
    return fs.statSync(dirPath).isDirectory();
  } catch {
    return false;
  }
};

const getFileSize = (filePath) => {
  try {
    const bytes = fs.statSync(filePath).size;
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(2)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
  } catch {
    return 'unknown';
  }
};

console.log(`\n${colors.cyan}ArmSphere Deployment Validation${colors.reset}\n`);

// 1. Check build artifacts
console.log(`${colors.cyan}=== Build Artifacts ===${colors.reset}`);

const apiBundle = 'apps/api/dist/server.js';
if (fileExists(apiBundle)) {
  log.pass(`API bundle: ${getFileSize(apiBundle)}`);
  checks.passed++;
} else {
  log.fail('API bundle missing');
  checks.failed++;
}

const adminWeb = 'dist/index.html';
if (fileExists(adminWeb)) {
  log.pass(`Admin web: ${getFileSize(adminWeb)}`);
  checks.passed++;
} else {
  log.fail('Admin web index missing');
  checks.failed++;
}

const adminWebAssets = 'dist/assets';
if (dirExists(adminWebAssets)) {
  const assetCount = fs.readdirSync(adminWebAssets).length;
  log.pass(`Admin web assets: ${assetCount} files`);
  checks.passed++;
} else {
  log.fail('Admin web assets missing');
  checks.failed++;
}

// 2. Check deployment files
console.log(`\n${colors.cyan}=== Deployment Configuration ===${colors.reset}`);

const deploymentFiles = [
  'Dockerfile.api',
  'Dockerfile.admin-web',
  'docker-compose.yml',
  'nginx.conf',
  '.dockerignore',
];

for (const file of deploymentFiles) {
  if (fileExists(file)) {
    log.pass(`${file} present`);
    checks.passed++;
  } else {
    log.fail(`${file} missing`);
    checks.failed++;
  }
}

// 3. Check documentation
console.log(`\n${colors.cyan}=== Documentation ===${colors.reset}`);

const docFiles = [
  'DEPLOYMENT.md',
  'README.md',
  'ArmSphere_Architecture_Freeze_v1.0.md',
];

for (const file of docFiles) {
  if (fileExists(file)) {
    log.pass(`${file} present`);
    checks.passed++;
  } else {
    log.fail(`${file} missing`);
    checks.failed++;
  }
}

// 4. Check package configuration
console.log(`\n${colors.cyan}=== Package Configuration ===${colors.reset}`);

try {
  const rootPkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
  
  if (rootPkg.scripts?.build) {
    log.pass('Build script configured');
    checks.passed++;
  } else {
    log.fail('Build script missing');
    checks.failed++;
  }

  if (rootPkg.scripts?.start) {
    log.pass('Start script configured');
    checks.passed++;
  } else {
    log.fail('Start script missing');
    checks.failed++;
  }
} catch {
  log.fail('Failed to read package.json');
  checks.failed++;
}

// 5. Check API package
console.log(`\n${colors.cyan}=== API Package ===${colors.reset}`);

try {
  const apiPkgPath = path.resolve('apps/api/package.json');
  const apiPkgContent = fs.readFileSync(apiPkgPath, 'utf8');
  const apiPkg = JSON.parse(apiPkgContent);
  
  if (apiPkg.scripts?.build) {
    log.pass('API build script configured');
    checks.passed++;
  } else {
    log.fail('API build script missing');
    checks.failed++;
  }

  if (apiPkg.scripts?.['db:migrate'] || apiPkg.scripts?.migrate) {
    log.pass('Database migrations configured');
    checks.passed++;
  } else {
    log.warn('Database migrations script missing');
    checks.warnings++;
  }

  if (apiPkg.dependencies?.['drizzle-orm']) {
    log.pass('Database ORM configured');
    checks.passed++;
  } else {
    log.fail('Database ORM missing');
    checks.failed++;
  }
} catch (error) {
  log.fail(`Failed to read apps/api/package.json: ${error.message}`);
  checks.failed++;
}

// 6. Environment configuration
console.log(`\n${colors.cyan}=== Environment Configuration ===${colors.reset}`);

if (fileExists('apps/api/src/config/env.ts')) {
  log.pass('Environment validation configured');
  checks.passed++;
} else {
  log.fail('Environment validation missing');
  checks.failed++;
}

// 7. Security checks
console.log(`\n${colors.cyan}=== Security Checks ===${colors.reset}`);

if (fileExists('apps/api/src/middlewares/auth.ts')) {
  log.pass('Authentication middleware present');
  checks.passed++;
} else {
  log.fail('Authentication middleware missing');
  checks.failed++;
}

if (fileExists('apps/api/src/middlewares/security.ts')) {
  log.pass('Security middleware present');
  checks.passed++;
} else {
  log.fail('Security middleware missing');
  checks.failed++;
}

// 8. Test configuration
console.log(`\n${colors.cyan}=== Test Configuration ===${colors.reset}`);

if (fileExists('apps/api/vitest.config.ts')) {
  log.pass('Test suite configured');
  checks.passed++;
} else {
  log.fail('Test suite missing');
  checks.failed++;
}

if (dirExists('apps/api/src/tests')) {
  const testCount = fs.readdirSync('apps/api/src/tests').filter(f => f.endsWith('.test.ts')).length;
  log.pass(`Test files: ${testCount} suites`);
  checks.passed++;
} else {
  log.fail('Test directory missing');
  checks.failed++;
}

// Summary
console.log(`\n${colors.cyan}=== Summary ===${colors.reset}`);
console.log(`${colors.green}Passed: ${checks.passed}${colors.reset}`);
if (checks.warnings > 0) {
  console.log(`${colors.yellow}Warnings: ${checks.warnings}${colors.reset}`);
}
if (checks.failed > 0) {
  console.log(`${colors.red}Failed: ${checks.failed}${colors.reset}`);
}

// Deployment readiness
console.log(`\n${colors.cyan}=== Deployment Readiness ===${colors.reset}`);

if (checks.failed === 0) {
  console.log(
    `${colors.green}✓ Application is production-ready!${colors.reset}\n` +
    `Next steps:\n` +
    `1. Review DEPLOYMENT.md for deployment options\n` +
    `2. Configure environment variables\n` +
    `3. Run: docker-compose up -d\n`
  );
  process.exit(0);
} else {
  console.log(
    `${colors.red}✗ Deployment blockers detected!${colors.reset}\n` +
    `Please fix the above issues before deploying.\n`
  );
  process.exit(1);
}
