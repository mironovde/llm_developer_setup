'use strict';

function slugify(title) {
  return String(title)
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

if (require.main === module) {
  const args = process.argv.slice(2);
  const verbose = args.includes('--verbose');
  const title = args.filter((a) => a !== '--verbose').join(' ');
  if (verbose) {
    console.error(`input:  ${JSON.stringify(title)}`);
  }
  console.log(slugify(title));
}

module.exports = { slugify };
