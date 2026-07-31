'use strict';

const { MAX_ITEMS } = require('./config.js');

// Splits a flat item count into pages of MAX_ITEMS each.
function pageCount(totalItems) {
  return Math.ceil(totalItems / MAX_ITEMS);
}

function pageOf(index) {
  return Math.floor(index / MAX_ITEMS);
}

module.exports = { pageCount, pageOf };
