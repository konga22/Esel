const { test } = require('node:test');
const assert = require('node:assert/strict');
const { create, advance } = require('../src/header-state.js');

test('initial top and 18px downward hide threshold', () => {
  const start = create();
  assert.equal(start.mode, 'top');
  assert.equal(advance(start, 17).mode, 'top');
  assert.equal(advance(start, 18).mode, 'hidden');
});
test('48px cumulative upward distance reveals the floating logo', () => {
  let state = advance(create(), 300);
  state = advance(state, 280);
  assert.equal(state.mode, 'hidden');
  state = advance(state, 253);
  assert.equal(state.mode, 'hidden');
  assert.equal(advance(state, 252).mode, 'floating');
});
test('direction reversal resets the threshold instead of counting old distance', () => {
  let state = advance(create(), 300);
  state = advance(state, 270);
  state = advance(state, 276);
  state = advance(state, 256);
  assert.equal(state.mode, 'hidden');
  assert.equal(advance(state, 228).mode, 'floating');
});
test('a tiny downward reversal does not immediately hide a revealed logo', () => {
  let state = advance(advance(create(), 300), 252);
  assert.equal(advance(state, 262).mode, 'floating');
  assert.equal(advance(state, 270).mode, 'hidden');
});
test('returning to the top restores the initial header and negative bounce clamps', () => {
  const state = advance(create(), 300);
  assert.equal(advance(state, 12).mode, 'top');
  assert.deepEqual(advance(state, -50), create());
});
test('bottom rubber band cannot manufacture upward reveal distance', () => {
  let state = advance(create(), 700, 500);
  assert.equal(state.y, 500);
  state = advance(state, 501, 500);
  assert.equal(state.y, 500);
  assert.equal(advance(state, 499, 500).mode, 'hidden');
});
test('fractional event noise does not change direction', () => {
  const state = advance(create(), 300);
  assert.equal(advance(state, 299.8), state);
});
