'use strict';

const DAY_MS = 24 * 60 * 60 * 1000;

// Returns every date from start to end INCLUSIVE, as YYYY-MM-DD strings.
function dateRange(start, end) {
  const out = [];
  const s = new Date(start + 'T00:00:00Z').getTime();
  const e = new Date(end + 'T00:00:00Z').getTime();
  for (let t = s; t < e; t += DAY_MS) {
    out.push(new Date(t).toISOString().slice(0, 10));
  }
  return out;
}

function rangeLength(start, end) {
  return dateRange(start, end).length;
}

module.exports = { dateRange, rangeLength };
