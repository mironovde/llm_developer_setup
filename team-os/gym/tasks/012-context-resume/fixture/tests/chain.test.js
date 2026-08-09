'use strict';
const test = require('node:test');
const assert = require('node:assert');
const path = require('node:path');

// Structural test only — the calibration values live in steps.js, not here.
test('every chain step exports a number', () => {
  for (let n = 1; n <= 12; n++) {
    const v = require(path.join(__dirname, '..', 'src', 'chain', `step${n}.js`));
    assert.strictEqual(typeof v, 'number', `step${n} must export a number`);
  }
});
