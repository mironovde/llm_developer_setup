'use strict';
const { test } = require('node:test');
const assert = require('node:assert');
const { formatReceipt, formatDate } = require('../src/format.js');

test('receipt says Received', () => {
  assert.strictEqual(formatReceipt('Alice', 10), 'Received: 10 from Alice');
});

test('date formats as YYYY-MM-DD', () => {
  assert.strictEqual(formatDate(new Date('2026-07-31T12:00:00Z')), '2026-07-31');
});
