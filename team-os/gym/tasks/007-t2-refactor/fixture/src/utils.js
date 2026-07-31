'use strict';

// ---------------------------------------------------------------------------
// utils.js — the project's grab-bag helper module. It grew organically:
// string, array, and date helpers all live here in one ~100-line monolith.
// ---------------------------------------------------------------------------

// ----- string helpers -----

function slugify(input) {
  return String(input)
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function truncate(input, maxLength, suffix) {
  const s = String(input);
  const tail = suffix === undefined ? '…' : suffix;
  if (maxLength <= 0) return '';
  if (s.length <= maxLength) return s;
  if (tail.length >= maxLength) return tail.slice(0, maxLength);
  return s.slice(0, maxLength - tail.length) + tail;
}

function capitalize(input) {
  const s = String(input);
  if (s.length === 0) return s;
  return s[0].toUpperCase() + s.slice(1);
}

// ----- array helpers -----

function chunk(items, size) {
  if (!Number.isInteger(size) || size <= 0) {
    throw new RangeError('chunk size must be a positive integer');
  }
  const out = [];
  for (let i = 0; i < items.length; i += size) {
    out.push(items.slice(i, i + size));
  }
  return out;
}

function unique(items) {
  const seen = new Set();
  const out = [];
  for (const item of items) {
    if (!seen.has(item)) {
      seen.add(item);
      out.push(item);
    }
  }
  return out;
}

function groupBy(items, keyFn) {
  const out = {};
  for (const item of items) {
    const key = String(keyFn(item));
    if (!Object.prototype.hasOwnProperty.call(out, key)) {
      out[key] = [];
    }
    out[key].push(item);
  }
  return out;
}

// ----- date helpers -----

const DAY_MS = 24 * 60 * 60 * 1000;

function formatDate(date, style) {
  const d = date instanceof Date ? date : new Date(date);
  if (Number.isNaN(d.getTime())) {
    throw new TypeError('formatDate: invalid date');
  }
  const iso = d.toISOString().slice(0, 10);
  if (style === undefined || style === 'iso') return iso;
  if (style === 'eu') {
    const [y, m, day] = iso.split('-');
    return `${day}.${m}.${y}`;
  }
  throw new RangeError(`formatDate: unknown style "${style}"`);
}

function daysBetween(a, b) {
  const ta = new Date(a + 'T00:00:00Z').getTime();
  const tb = new Date(b + 'T00:00:00Z').getTime();
  if (Number.isNaN(ta) || Number.isNaN(tb)) {
    throw new TypeError('daysBetween: invalid date');
  }
  return Math.round(Math.abs(tb - ta) / DAY_MS);
}

module.exports = {
  slugify,
  truncate,
  capitalize,
  chunk,
  unique,
  groupBy,
  formatDate,
  daysBetween,
};
