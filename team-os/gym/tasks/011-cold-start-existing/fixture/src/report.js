'use strict';

const { normalizeCategory, signedAmount } = require('./rules');

function buildReport(records) {
  const byCategory = {};
  for (const record of records) {
    const category = normalizeCategory(record.category);
    byCategory[category] = round2((byCategory[category] || 0) + signedAmount(record));
  }
  const net = round2(Object.values(byCategory).reduce((a, b) => a + b, 0));
  return { byCategory, net };
}

function formatReport(report) {
  const rows = Object.keys(report.byCategory)
    .sort()
    .map((c) => `${c.padEnd(12)} ${report.byCategory[c].toFixed(2).padStart(9)}`);
  return [...rows, '-'.repeat(22), `${'Net'.padEnd(12)} ${report.net.toFixed(2).padStart(9)}`].join('\n');
}

function round2(n) {
  return Math.round(n * 100) / 100;
}

module.exports = { buildReport, formatReport, round2 };
