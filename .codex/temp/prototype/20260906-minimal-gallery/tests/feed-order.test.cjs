const test = require('node:test');
const assert = require('node:assert/strict');
const Feed = require('../src/feed-order.js');
const Model = require('../src/social-state.js');
const posts = Array.from({length:12}, (_, i) => ({id:String(i), date:i < 4 ? Model.TODAY : '2026-09-05', minute:720-i, likes:i * 10, paletteId:i % 2 ? 'blue' : 'sage'}));

test('initial feed is chronological, including past posts in the same list', () => {
  assert.deepEqual(Feed.next(posts.slice().reverse(), [], 0).map(p=>p.id), ['0','1','2','3']);
  assert.deepEqual(Feed.next(posts, ['0','1','2','3'].map(id=>Feed.key(posts[Number(id)])), 0).map(p=>p.id), ['4','5','6','7']);
});
test('after 30 seconds only the fourth new slot is popular; rendered prefix is untouched', () => {
  const seen = posts.slice(0,4).map(Feed.key);
  assert.deepEqual(Feed.next(posts, seen, 29999).map(p=>p.id), ['4','5','6','7']);
  assert.deepEqual(Feed.next(posts, seen, 30000).map(p=>p.id), ['4','5','6','11']);
  assert.deepEqual(seen, posts.slice(0,4).map(Feed.key));
});
test('first four stay newest even after extended viewing', () => {
  assert.deepEqual(Feed.next(posts, [], 60000).map(p=>p.id), ['0','1','2','3']);
});
test('pagination exhausts once without duplicate identities or input mutation', () => {
  const original = JSON.stringify(posts); const seen=[];
  for (let i=0;i<5;i++) seen.push(...Feed.next(posts,seen,30000).map(Feed.key));
  assert.equal(seen.length,12); assert.equal(new Set(seen).size,12);
  assert.equal(JSON.stringify(posts),original);
  assert.deepEqual(Feed.next([],[],0),[]);
});
test('visibility filtering precedes ranking; popularity cannot unlock today same color', () => {
  const state = Model.confirm(Model.create());
  const visible = posts.filter(p=>Model.canView(state,p));
  const seen=[]; const rendered=[];
  for(let i=0;i<5;i++) { const page=Feed.next(visible,seen,60000); rendered.push(...page); seen.push(...page.map(Feed.key)); }
  assert.ok(rendered.every(p=>p.date!==Model.TODAY || p.paletteId!==state.selected));
  assert.ok(rendered.some(p=>p.date!==Model.TODAY && p.paletteId===state.selected));
  const published=Model.publish(state,{src:'sample.jpg',kind:'sample'});
  assert.ok(posts.filter(p=>Model.canView(published,p)).some(p=>p.date===Model.TODAY && p.paletteId===state.selected));
});
