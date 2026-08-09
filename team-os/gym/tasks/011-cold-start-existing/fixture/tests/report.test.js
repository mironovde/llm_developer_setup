'use strict';
const test = require('node:test');
const assert = require('node:assert');
const { parseCsv } = require('../src/parse');
const { buildReport } = require('../src/report');
const { normalizeCategory } = require('../src/rules');

const SAMPLE = [
  'date,category,description,amount',
  '2026-02-01,groceries,Market,10.00',
  '2026-02-02,transport,Bus,2.50',
].join('\n');

test('parses a bank export', () => {
  const records = parseCsv(SAMPLE);
  assert.strictEqual(records.length, 2);
  assert.strictEqual(records[0].amount, 10);
});

test('unknown categories fall back to other', () => {
  assert.strictEqual(normalizeCategory('Groceries'), 'groceries');
  assert.strictEqual(normalizeCategory('crypto'), 'other');
});

test('totals spend by category', () => {
  const report = buildReport(parseCsv(SAMPLE));
  assert.strictEqual(report.byCategory.groceries, 10);
  assert.strictEqual(report.byCategory.transport, 2.5);
  assert.strictEqual(report.net, 12.5);
});
