#!/usr/bin/env node

const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const args = process.argv.slice(2);
const template = args[0] || 'base';
const target = args[1] || '.';

// Get the directory where this package is installed
const packageDir = path.resolve(__dirname, '..');
const installScript = path.join(packageDir, 'install.sh');

console.log(`claude-parallel-templates v0.3.0`);
console.log(`Template: ${template}`);
console.log(`Target: ${path.resolve(target)}`);
console.log(`Install script: ${installScript}`);

// Check if install script exists
if (!fs.existsSync(installScript)) {
  console.error(`Error: install.sh not found at ${installScript}`);
  process.exit(1);
}

// Run the install script
try {
  execSync(`bash "${installScript}" "${template}" "${target}"`, {
    stdio: 'inherit',
    cwd: process.cwd()
  });
} catch (error) {
  process.exit(error.status || 1);
}
