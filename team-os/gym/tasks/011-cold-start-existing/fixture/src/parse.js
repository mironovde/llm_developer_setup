'use strict';

// CSV → records. The export format is fixed by the bank; amounts always arrive unsigned,
// the direction of the money is carried by the category (see rules.js).
function parseCsv(text) {
  const lines = text.trim().split('\n');
  const header = lines[0].split(',').map((h) => h.trim());
  return lines.slice(1).map((line) => {
    const cells = splitLine(line);
    const record = {};
    header.forEach((key, i) => {
      record[key] = cells[i];
    });
    record.amount = Number.parseFloat(record.amount);
    if (Number.isNaN(record.amount)) {
      throw new TypeError(`parseCsv: bad amount in line: ${line}`);
    }
    return record;
  });
}

function splitLine(line) {
  return line.split(',').map((c) => c.trim());
}

module.exports = { parseCsv };
