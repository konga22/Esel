(function (root, factory) {
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.EselFeedOrder = api;
})(typeof globalThis !== 'undefined' ? globalThis : this, function () {
  'use strict';
  const POPULAR_AFTER_MS = 30000;
  const key = post => `${post.id}-${post.date}`;
  const newest = (a, b) => b.date.localeCompare(a.date) || (b.minute || 0) - (a.minute || 0) || key(a).localeCompare(key(b));
  // Callers apply visibility first. Return only unseen items; never reorder rendered posts.
  function next(posts, seen, elapsedMs, size = 4) {
    const pool = posts.filter(p => !seen.includes(key(p))).sort(newest);
    const page = [];
    while (pool.length && page.length < size) {
      const popular = elapsedMs >= POPULAR_AFTER_MS && seen.length + page.length >= 4 && (seen.length + page.length + 1) % 4 === 0;
      let index = 0;
      if (popular) {
        for (let i = 1; i < pool.length; i++) {
          if ((pool[i].likes || 0) > (pool[index].likes || 0)) index = i;
        }
      }
      page.push(pool.splice(index, 1)[0]);
    }
    return page;
  }
  return { key, next, POPULAR_AFTER_MS };
});
