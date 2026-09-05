(function (root, factory) {
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.EselHeaderState = api;
})(typeof globalThis !== 'undefined' ? globalThis : this, function () {
  'use strict';
  const TOP = 12;
  const HIDE_DISTANCE = 18;
  const REVEAL_DISTANCE = 48;

  function create(y = 0) {
    return { y: Math.max(0, y), direction: 0, distance: 0, mode: y <= TOP ? 'top' : 'hidden' };
  }

  function advance(state, rawY, maxY = Infinity) {
    const y = Math.min(Math.max(0, rawY), Math.max(0, maxY));
    if (y <= TOP) return create(y);
    const delta = y - state.y;
    // Ignore fractional scroll noise, but keep it available for the next sample.
    if (Math.abs(delta) < 1) return state;
    const direction = Math.sign(delta);
    const distance = direction === state.direction ? state.distance + Math.abs(delta) : Math.abs(delta);
    let mode = state.mode;
    if (direction > 0 && distance >= HIDE_DISTANCE) mode = 'hidden';
    if (direction < 0 && distance >= REVEAL_DISTANCE) mode = 'floating';
    return { y, direction, distance, mode };
  }
  return { create, advance, TOP, HIDE_DISTANCE, REVEAL_DISTANCE };
});
