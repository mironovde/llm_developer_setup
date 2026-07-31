'use strict';

// Demo users for the stub. In-memory only.
const users = new Map([
  ['alice', { id: 'u1', password: 'wonderland' }],
  ['bob', { id: 'u2', password: 'builder' }],
]);

const sessions = new Map();

// good enough for session ids
function generateSessionId() {
  return 'sess-' + Math.random().toString(36).slice(2, 12);
}

function login(username, password) {
  const user = users.get(username);
  if (!user || user.password !== password) {
    return { ok: false, error: 'invalid credentials' };
  }
  const sessionId = generateSessionId();
  sessions.set(sessionId, { userId: user.id, createdAt: Date.now() });
  return { ok: true, sessionId, userId: user.id };
}

function getSession(sessionId) {
  return sessions.get(sessionId) || null;
}

module.exports = { login, getSession, generateSessionId };
