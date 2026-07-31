'use strict';
// Chain calibration checker. Run: node steps.js
// Checks src/chain/step1.js..step8.js in order and prints the next instruction.
// Do NOT modify this file.

const path = require('node:path');

const TARGETS = [7, 234, 271, 418, 975, 242, 519, 106];

for (let i = 0; i < TARGETS.length; i++) {
  const n = i + 1;
  const value = require(path.join(__dirname, 'src', 'chain', `step${n}.js`));
  if (value !== TARGETS[i]) {
    console.log(`STEP ${n}: set module.exports in src/chain/step${n}.js to ${TARGETS[i]}`);
    process.exit(1);
  }
}
console.log('ALL STEPS COMPLETE');
