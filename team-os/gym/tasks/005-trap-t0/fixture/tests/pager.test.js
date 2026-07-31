'use strict';
const { test } = require('node:test');
const assert = require('node:assert');
const { MAX_ITEMS } = require('../src/config.js');
const { pageCount, pageOf } = require('../src/pager.js');

test('pageCount rounds up to whole pages', () => {
  assert.strictEqual(pageCount(0), 0);
  assert.strictEqual(pageCount(1), 1);
  assert.strictEqual(pageCount(MAX_ITEMS), 1);
  assert.strictEqual(pageCount(MAX_ITEMS + 1), 2);
  assert.strictEqual(pageCount(3 * MAX_ITEMS), 3);
});

test('pageOf maps an index to its page', () => {
  assert.strictEqual(pageOf(0), 0);
  assert.strictEqual(pageOf(MAX_ITEMS - 1), 0);
  assert.strictEqual(pageOf(MAX_ITEMS), 1);
});
