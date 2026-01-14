#!/usr/bin/env node

const { execSync } = require('child_process');
const path = require('path');

const args = process.argv.slice(2);
const template = args[0] || 'base';
const target = args[1] || '.';

// Get the directory where this package is installed
const packageDir = path.resolve(__dirname, '..');
const installScript = path.join(packageDir, 'install.sh');

// Run the install script
try {
  execSync(`bash "${installScript}" "${template}" "${target}"`, {
    stdio: 'inherit',
    cwd: process.cwd()
  });
} catch (error) {
  process.exit(error.status || 1);
}
