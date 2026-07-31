'use strict';
const { test } = require('node:test');
const assert = require('node:assert');
const { dateRange, rangeLength } = require('../src/range.js');

test('range is inclusive of the end date', () => {
  assert.deepStrictEqual(dateRange('2026-07-01', '2026-07-03'), [
    '2026-07-01',
    '2026-07-02',
    '2026-07-03',
  ]);
});

test('single-day range has length 1', () => {
  assert.strictEqual(rangeLength('2026-07-15', '2026-07-15'), 1);
});

test('week is 7 days', () => {
  assert.strictEqual(rangeLength('2026-07-01', '2026-07-07'), 7);
});
