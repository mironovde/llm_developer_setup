'use strict';

function formatReceipt(name, amount) {
  return `Recieved: ${amount} from ${name}`;
}

function formatDate(d) {
  return d.toISOString().slice(0, 10);
}

module.exports = { formatReceipt, formatDate };
