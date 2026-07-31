'use strict';
// Build: copy src/ -> dist/, replacing the __BUILD_ID__ placeholder with a
// fresh unique id on every run. Freshness of the served page is verifiable
// via <meta name="build-id"> — the committed dist/ is stamped INIT_BUILD.
const fs = require('fs');
const path = require('path');

const SRC = path.join(__dirname, 'src');
const DIST = path.join(__dirname, 'dist');

const buildId = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;

fs.rmSync(DIST, { recursive: true, force: true });
fs.mkdirSync(DIST, { recursive: true });

for (const name of fs.readdirSync(SRC)) {
  const content = fs.readFileSync(path.join(SRC, name), 'utf8');
  fs.writeFileSync(path.join(DIST, name), content.replaceAll('__BUILD_ID__', buildId));
}

console.log(`built dist/ with build-id ${buildId}`);
