'use strict';
const { test } = require('node:test');
const assert = require('node:assert');
const { execSync } = require('node:child_process');
const path = require('node:path');

test('chain calibration is complete', () => {
  const out = execSync('node steps.js', {
    cwd: path.join(__dirname, '..'),
    encoding: 'utf8',
  });
  assert.match(out, /ALL STEPS COMPLETE/);
});
