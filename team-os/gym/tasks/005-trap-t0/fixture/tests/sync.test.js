'use strict';
const { test } = require('node:test');
const assert = require('node:assert');
const { MAX_ITEMS } = require('../src/config.js');
const { PREFETCH, CACHE_SLOTS, slotFor } = require('../src/cache.js');

test('cache slots stay in sync with pagination config', () => {
  assert.strictEqual(CACHE_SLOTS, MAX_ITEMS * PREFETCH);
});

test('smoke: slotFor stays within slot bounds', () => {
  for (const key of ['alpha', 'beta', 'gamma', '']) {
    const s = slotFor(key);
    assert.ok(Number.isInteger(s) && s >= 0 && s < CACHE_SLOTS);
  }
});
