'use strict';
const { test } = require('node:test');
const assert = require('node:assert');
const { slugify } = require('../src/slug.js');

test('lowercases and hyphenates words', () => {
  assert.strictEqual(slugify('Hello World'), 'hello-world');
});

test('strips punctuation and trims dashes', () => {
  assert.strictEqual(slugify('  Node.js -- Quick Start!  '), 'node-js-quick-start');
});
