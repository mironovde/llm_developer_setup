#!/usr/bin/env node
'use strict';

const fs = require('node:fs');
const path = require('node:path');
const { parseCsv } = require('../src/parse');
const { buildReport, formatReport } = require('../src/report');

const file = process.argv[2] || path.join(__dirname, '..', 'data', 'transactions.csv');
const records = parseCsv(fs.readFileSync(file, 'utf8'));
console.log(formatReport(buildReport(records)));
