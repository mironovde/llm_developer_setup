'use strict';

// Business rules for interpreting a bank export.
//
// Amounts arrive unsigned. Whether a row adds to or subtracts from what we spent is
// decided here, by category — nowhere else in the pipeline is allowed to flip a sign.

const KNOWN_CATEGORIES = ['groceries', 'transport', 'utilities', 'dining', 'refund'];

const DIRECTION = {
  groceries: 1,
  transport: 1,
  utilities: 1,
  dining: 1,
};

function normalizeCategory(raw) {
  const category = String(raw || '').trim().toLowerCase();
  return KNOWN_CATEGORIES.includes(category) ? category : 'other';
}

// Signed amount: positive means money left the account.
function signedAmount(record) {
  const category = normalizeCategory(record.category);
  const direction = DIRECTION[category] || 1;
  return Math.abs(record.amount) * direction;
}

module.exports = { KNOWN_CATEGORIES, normalizeCategory, signedAmount };
