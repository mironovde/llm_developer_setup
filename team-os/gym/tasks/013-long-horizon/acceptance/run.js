'use strict';
// Hidden acceptance for 013-long-horizon. The agent never sees this file: it works from BACKLOG.md,
// which describes behaviour, so it cannot aim at the assertions instead of the requirement.
// Prints one line per criterion: "<id>\t<pass|fail>\t<detail>".
// Usage: node run.js /path/to/workspace

const path = require('node:path');
const assert = require('node:assert');

const ws = process.argv[2];
if (!ws) { console.error('usage: run.js <workspace>'); process.exit(2); }

let T;
try {
  T = require(path.join(ws, 'src', 'text.js'));
} catch (err) {
  for (const id of ['cyrillic-slug', 'truncate-word-boundary', 'word-count-markdown', 'reading-time',
                    'escape-html', 'acronyms-configurable', 'excerpt', 'already-done-capitalize']) {
    console.log(`${id}\tfail\tsrc/text.js does not load: ${err.message}`);
  }
  process.exit(0);
}

const criteria = {
  'cyrillic-slug': () => {
    assert.strictEqual(T.slugify('Привет мир'), 'privet-mir');
    assert.strictEqual(T.slugify('Hello World'), 'hello-world', 'latin behaviour must be unchanged');
  },
  'truncate-word-boundary': () => {
    const r = T.truncate('the quick brown fox', 12, '…', { wordBoundary: true });
    assert.ok(!/\S$/.test(r.replace(/…$/, '')) || /^(the quick|the)…?$/.test(r.replace(/…$/, '').trim() + '…'),
      `expected a cut on a word boundary, got ${JSON.stringify(r)}`);
    assert.ok(r.length <= 12, `result longer than max: ${JSON.stringify(r)}`);
    assert.ok(!/brow$|quic$/.test(r.replace(/…$/, '')), `cut mid-word: ${JSON.stringify(r)}`);
    assert.strictEqual(T.truncate('abcdefghij', 5), 'abcd…', 'default behaviour must be unchanged');
  },
  'word-count-markdown': () => {
    assert.strictEqual(T.wordCount('**bold** text'), 2);
    assert.strictEqual(T.wordCount('[click here](http://example.com)'), 2, 'link text counts, url does not');
    assert.strictEqual(T.wordCount('# Heading'), 1);
    assert.strictEqual(T.wordCount('- item one'), 2);
  },
  'reading-time': () => {
    assert.strictEqual(T.readingTime(''), 0);
    assert.strictEqual(T.readingTime('word'), 1, 'any non-empty text is at least one minute');
    assert.strictEqual(T.readingTime(Array(400).fill('word').join(' ')), 2);
  },
  'escape-html': () => {
    assert.strictEqual(T.escapeHtml('<a href="x">'), '&lt;a href=&quot;x&quot;&gt;');
    assert.strictEqual(T.escapeHtml('a & b'), 'a &amp; b');
    assert.strictEqual(T.escapeHtml('&lt;'), '&amp;lt;', 'ampersand must be escaped first, not twice');
    assert.strictEqual(T.escapeHtml("it's"), 'it&#39;s');
  },
  'acronyms-configurable': () => {
    assert.strictEqual(T.titleCase('the http api'), 'The HTTP API', 'built-in list stays the default');
    const custom = new Set(['ABC']);
    assert.strictEqual(T.titleCase('my abc tool', custom), 'My ABC Tool');
  },
  'excerpt': () => {
    assert.strictEqual(T.excerpt('one two three four', 2), 'one two…');
    assert.strictEqual(T.excerpt('one two', 5), 'one two', 'no suffix when nothing was cut');
  },
  'already-done-capitalize': () => {
    assert.strictEqual(T.capitalize('word'), 'Word');
    assert.strictEqual(T.capitalize(''), '');
    assert.strictEqual(T.capitalize('hello world'), 'Hello world', 'only the first character changes');
  },
};

for (const [id, fn] of Object.entries(criteria)) {
  try {
    fn();
    console.log(`${id}\tpass\t`);
  } catch (err) {
    console.log(`${id}\tfail\t${String(err.message).split('\n')[0].slice(0, 160)}`);
  }
}
