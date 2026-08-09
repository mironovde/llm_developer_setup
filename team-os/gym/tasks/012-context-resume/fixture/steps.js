'use strict';
// Chain calibration checker. Run: node steps.js
// Checks src/chain/step1.js..step12.js in order and prints the next instruction.
// Do NOT modify this file.

const path = require('node:path');

const TARGETS = [192, 970, 489, 129, 200, 606, 911, 607, 632, 223, 310, 457];

for (let i = 0; i < TARGETS.length; i++) {
  const n = i + 1;
  const value = require(path.join(__dirname, 'src', 'chain', `step${n}.js`));
  if (value !== TARGETS[i]) {
    console.log(`STEP ${n}: set module.exports in src/chain/step${n}.js to ${TARGETS[i]}`);
    process.exit(1);
  }
}
console.log('ALL STEPS COMPLETE');
