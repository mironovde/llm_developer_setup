'use strict';
const { test } = require('node:test');
const assert = require('node:assert');
const { login, getSession } = require('../src/auth.js');

test('login happy path returns a session', () => {
  const res = login('alice', 'wonderland');
  assert.strictEqual(res.ok, true);
  assert.ok(res.sessionId.length > 0);
  assert.strictEqual(getSession(res.sessionId).userId, 'u1');
});

test('wrong password is rejected', () => {
  const res = login('alice', 'nope');
  assert.strictEqual(res.ok, false);
  assert.strictEqual(res.sessionId, undefined);
});
