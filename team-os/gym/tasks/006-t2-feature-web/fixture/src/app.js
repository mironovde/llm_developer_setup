'use strict';
/* global renderList */

const TEAM = [
  'Alice Johnson',
  'Boris Petrov',
  'Carol Nguyen',
  'David Okafor',
  'Elena Sokolova',
  'Frank Miller',
];

document.addEventListener('DOMContentLoaded', () => {
  document.getElementById('list').innerHTML = renderList(TEAM);
});
