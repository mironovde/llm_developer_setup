'use strict';

// Pure render helper: array of names -> <li> markup.
function renderList(names) {
  return names.map((name) => `<li>${name}</li>`).join('\n');
}

// Dual environment: browser (script tag, no module) + node tests (require).
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { renderList };
}
