'use strict';
const { test } = require('node:test');
const assert = require('node:assert');
const { renderList } = require('../src/lib.js');

test('renderList renders one <li> per name', () => {
  const html = renderList(['Ada Lovelace', 'Grace Hopper', 'Linus Torvalds']);
  const items = html.match(/<li>/g) || [];
  assert.strictEqual(items.length, 3);
});

test('renderList keeps the name text', () => {
  assert.match(renderList(['Ada Lovelace']), /Ada Lovelace/);
});

test('renderList of empty array is empty', () => {
  assert.strictEqual(renderList([]), '');
});
