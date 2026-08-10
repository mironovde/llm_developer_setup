'use strict';
const test = require('node:test');
const assert = require('node:assert');
const { slugify, truncate, capitalize, wordCount, titleCase } = require('../src/text');

test('slugify makes url-safe slugs', () => {
  assert.strictEqual(slugify('Hello World'), 'hello-world');
  assert.strictEqual(slugify('  Spaces  everywhere  '), 'spaces-everywhere');
});

test('truncate shortens long strings', () => {
  assert.strictEqual(truncate('abcdefghij', 5), 'abcd…');
  assert.strictEqual(truncate('short', 20), 'short');
});

test('capitalize uppercases the first letter', () => {
  assert.strictEqual(capitalize('word'), 'Word');
  assert.strictEqual(capitalize(''), '');
});

test('wordCount counts words', () => {
  assert.strictEqual(wordCount('one two three'), 3);
  assert.strictEqual(wordCount('   '), 0);
});

test('titleCase preserves known acronyms', () => {
  assert.strictEqual(titleCase('the http api'), 'The HTTP API');
});
