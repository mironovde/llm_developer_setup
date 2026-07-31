'use strict';
const { test } = require('node:test');
const assert = require('node:assert');
const utils = require('../src/utils.js');

test('public API surface is exactly the documented set', () => {
  assert.deepStrictEqual(Object.keys(utils).sort(), [
    'capitalize',
    'chunk',
    'daysBetween',
    'formatDate',
    'groupBy',
    'slugify',
    'truncate',
    'unique',
  ]);
});

// ----- string helpers -----

test('slugify lowercases, trims, and dashes', () => {
  assert.strictEqual(utils.slugify('  Hello, World!  '), 'hello-world');
});

test('slugify collapses runs of separators', () => {
  assert.strictEqual(utils.slugify('a -- b__c'), 'a-b-c');
});

test('truncate keeps short strings intact', () => {
  assert.strictEqual(utils.truncate('short', 10), 'short');
});

test('truncate cuts long strings with default ellipsis', () => {
  assert.strictEqual(utils.truncate('abcdefghij', 5), 'abcd…');
});

test('truncate honors a custom suffix', () => {
  assert.strictEqual(utils.truncate('abcdefghij', 6, '...'), 'abc...');
});

test('capitalize uppercases the first letter only', () => {
  assert.strictEqual(utils.capitalize('claude code'), 'Claude code');
  assert.strictEqual(utils.capitalize(''), '');
});

// ----- array helpers -----

test('chunk splits into fixed-size groups', () => {
  assert.deepStrictEqual(utils.chunk([1, 2, 3, 4, 5], 2), [[1, 2], [3, 4], [5]]);
});

test('chunk rejects non-positive sizes', () => {
  assert.throws(() => utils.chunk([1], 0), RangeError);
});

test('unique preserves first-seen order', () => {
  assert.deepStrictEqual(utils.unique([3, 1, 3, 2, 1]), [3, 1, 2]);
});

test('groupBy groups by the computed key', () => {
  assert.deepStrictEqual(
    utils.groupBy(['apple', 'avocado', 'banana'], (w) => w[0]),
    { a: ['apple', 'avocado'], b: ['banana'] }
  );
});

// ----- date helpers -----

test('formatDate defaults to ISO', () => {
  assert.strictEqual(utils.formatDate(new Date('2026-07-31T12:00:00Z')), '2026-07-31');
});

test('formatDate supports eu style', () => {
  assert.strictEqual(utils.formatDate('2026-07-31T00:00:00Z', 'eu'), '31.07.2026');
});

test('formatDate rejects unknown styles', () => {
  assert.throws(() => utils.formatDate(new Date(), 'us'), RangeError);
});

test('daysBetween counts calendar days symmetrically', () => {
  assert.strictEqual(utils.daysBetween('2026-07-01', '2026-07-31'), 30);
  assert.strictEqual(utils.daysBetween('2026-07-31', '2026-07-01'), 30);
});
