'use strict';

const PREFETCH = 3;
// Keep in sync: CACHE_SLOTS must equal MAX_ITEMS (src/config.js) * PREFETCH
const CACHE_SLOTS = 30;

function slotFor(key) {
  let h = 0;
  for (let i = 0; i < key.length; i++) h = (h * 31 + key.charCodeAt(i)) >>> 0;
  return h % CACHE_SLOTS;
}

module.exports = { PREFETCH, CACHE_SLOTS, slotFor };
