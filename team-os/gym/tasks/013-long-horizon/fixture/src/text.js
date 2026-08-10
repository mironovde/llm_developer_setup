'use strict';

// Text utilities. Small on purpose: the interesting part is the backlog, not the code.

const ACRONYMS = new Set(['API', 'HTTP', 'SQL', 'URL', 'CSS']);

function slugify(input) {
  return String(input)
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function truncate(input, maxLength, suffix = '…') {
  const s = String(input);
  if (s.length <= maxLength) return s;
  return s.slice(0, Math.max(0, maxLength - suffix.length)) + suffix;
}

function capitalize(input) {
  const s = String(input);
  if (!s) return s;
  return s[0].toUpperCase() + s.slice(1);
}

function wordCount(input) {
  const s = String(input).trim();
  if (!s) return 0;
  return s.split(/\s+/).length;
}

function titleCase(input) {
  return String(input)
    .split(/\s+/)
    .map((w) => (ACRONYMS.has(w.toUpperCase()) ? w.toUpperCase() : capitalize(w.toLowerCase())))
    .join(' ');
}

module.exports = { slugify, truncate, capitalize, wordCount, titleCase, ACRONYMS };
