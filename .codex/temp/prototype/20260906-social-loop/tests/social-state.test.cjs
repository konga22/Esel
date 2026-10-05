const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const state = require('../src/social-state.js');

const photo = { src: 'assets/my-outfit.jpg', alt: '오늘의 착장' };
const friendPhoto = { src: 'assets/friend-outfit.jpg', alt: '친구의 착장' };

function deepFreeze(value) {
  Object.freeze(value);
  for (const child of Object.values(value)) {
    if (child && typeof child === 'object') deepFreeze(child);
  }
  return value;
}

test('new state has the fixed mock date, four persistent records, and two restore credits', () => {
  const initial = state.create();
  assert.equal(state.TODAY, '2026-09-06');
  assert.equal(state.MONTH, '2026-09');
  assert.equal(initial.date, state.TODAY);
  assert.equal(initial.selected, 'sage');
  assert.equal(initial.confirmed, false);
  assert.equal(initial.rareEligible, false);
  assert.equal(initial.post, null);
  assert.equal(initial.restoreCredits, 2);
  assert.deepEqual(initial.history.map((entry) => [entry.date, entry.paletteId, entry.kind]), [
    ['2026-09-01', 'sage', 'posted'],
    ['2026-09-02', 'butter', 'posted'],
    ['2026-09-04', 'blue', 'posted'],
    ['2026-09-05', 'sage', 'posted'],
  ]);
  assert.deepEqual(initial.twin, { status: 'none', friendPosted: false, friendPhoto: null, paletteId: null });
});

test('each new state owns independent seed history and twin objects', () => {
  const first = state.create();
  const second = state.create();
  first.history[0].paletteId = 'blue';
  first.twin.status = 'invited';
  assert.equal(second.history[0].paletteId, 'sage');
  assert.equal(second.twin.status, 'none');
});

test('rare eligibility selects the rare palette and rejects unauthorized choices', () => {
  const initial = state.create();
  assert.throws(() => state.choose(initial, 'rare'), /무작위 추첨/);
  assert.throws(() => state.choose(initial, 'unknown'), /팔레트/);
  const rare = state.create({ rare: true });
  assert.equal(rare.rareEligible, true);
  assert.equal(rare.selected, 'rare');
  assert.equal(state.choose(rare, 'butter').selected, 'butter');
  assert.equal(state.choose(rare, 'rare').selected, 'rare');
});

test('rare draw accepts exactly the fixed 3.2 percent sample interval', () => {
  assert.equal(state.isRareDraw(0), true);
  assert.equal(state.isRareDraw(0.0319999999), true);
  assert.equal(state.isRareDraw(0.032), false);
  assert.equal(state.isRareDraw(0.9999999999), false);
});

test('palette selection stays available before confirmation', () => {
  const initial = deepFreeze(state.create());
  assert.equal(state.canChoose(initial), true);
  const selected = state.choose(initial, 'blue');
  assert.equal(selected.selected, 'blue');
  assert.equal(selected.confirmed, false);
  assert.equal(state.canChoose(selected), true);
  assert.equal(state.choose(selected, 'butter').selected, 'butter');
  assert.equal(initial.selected, 'sage');
});

test('confirmation freezes the selected palette without mutating inputs and is idempotent', () => {
  const selected = deepFreeze(state.choose(state.create(), 'blue'));
  const confirmed = deepFreeze(state.confirm(selected));
  assert.equal(confirmed.confirmed, true);
  assert.equal(confirmed.selected, 'blue');
  assert.equal(state.canChoose(confirmed), false);
  assert.throws(() => state.choose(confirmed, 'sage'), /바꿀 수 없어요/);
  assert.equal(selected.confirmed, false);
  assert.equal(state.confirm(confirmed), confirmed);
  assert.throws(() => state.confirm({ ...selected, selected: 'unknown' }), /팔레트/);
  assert.throws(() => state.confirm({ ...selected, selected: 'rare' }), /무작위 추첨/);
});

test('confirmation alone never unlocks today same-palette feed', () => {
  const confirmed = state.confirm(state.create());
  assert.equal(confirmed.post, null);
  assert.equal(state.canView(confirmed, { date: state.TODAY, paletteId: 'sage' }), false);
  assert.equal(state.canView(confirmed, { date: state.TODAY, paletteId: 'blue' }), true);
  const restored = state.restore(confirmed, '2026-09-03', 'blue');
  assert.equal(state.canView(restored, { date: state.TODAY, paletteId: 'sage' }), false);
  assert.equal(state.canChoose(restored), false);
  assert.equal(state.canView(state.publish(restored, photo), { date: state.TODAY, paletteId: 'sage' }), true);
});

test('rare draw rejects out of range or nonnumeric values', () => {
  for (const value of [-0.001, 1, 2, NaN, Infinity, -Infinity, '0.01', null, undefined]) {
    assert.throws(() => state.isRareDraw(value), /0 이상 1 미만/);
  }
});

test('today same-palette feed is locked while other palettes stay public', () => {
  const initial = state.create();
  assert.equal(state.canView(initial, { date: state.TODAY, paletteId: 'sage' }), false);
  for (const paletteId of ['butter', 'blue', 'rare']) {
    assert.equal(state.canView(initial, { date: state.TODAY, paletteId }), true);
  }
  const selected = state.choose(initial, 'blue');
  assert.equal(state.canView(selected, { date: state.TODAY, paletteId: 'blue' }), false);
  assert.equal(state.canView(selected, { date: state.TODAY, paletteId: 'sage' }), true);
});

test('past feed is public, future feed is closed, and malformed dates never open a feed', () => {
  const initial = state.create();
  assert.equal(state.canView(initial, { date: '2026-09-05', paletteId: 'sage' }), true);
  assert.equal(state.canView(initial, { date: '2026-08-01', paletteId: 'rare' }), true);
  assert.equal(state.canView(initial, { date: '2026-09-07', paletteId: 'sage' }), false);
  assert.equal(state.canView(initial, { date: '2026-09-07', paletteId: 'blue' }), false);
  assert.equal(state.canView(initial, { date: '2026-02-30', paletteId: 'sage' }), false);
  assert.equal(state.canView(initial, { date: 'invalid', paletteId: 'sage' }), false);
});

test('publishing opens today same-palette feed and records the photo and color', () => {
  const initial = state.create();
  const published = state.publish(initial, photo);
  assert.deepEqual(published.post, { date: state.TODAY, paletteId: 'sage', photo });
  assert.equal(published.confirmed, true);
  assert.notEqual(published.post.photo, photo);
  assert.equal(state.canView(published, { date: state.TODAY, paletteId: 'sage' }), true);
  assert.equal(published.history.length, 5);
  assert.deepEqual(published.history.at(-1), { date: state.TODAY, paletteId: 'sage', kind: 'posted' });
  assert.equal(initial.post, null);
  assert.equal(initial.history.length, 4);
});

test('a mismatched or old post never unlocks today same-palette feed', () => {
  const initial = state.create();
  for (const post of [
    { date: '2026-09-05', paletteId: 'sage', photo },
    { date: state.TODAY, paletteId: 'butter', photo },
  ]) {
    assert.equal(state.canView({ ...initial, post }, { date: state.TODAY, paletteId: 'sage' }), false);
  }
});

test('a missing photo and duplicate publishing are rejected', () => {
  for (const invalid of [null, undefined, {}, { src: '' }, { src: '   ' }, { src: 2 }]) {
    assert.throws(() => state.publish(state.create(), invalid), /사진/);
  }
  const published = state.publish(state.create(), photo);
  assert.throws(() => state.publish(published, friendPhoto), /이미 게시/);
});

test('publishing permanently freezes today palette selection', () => {
  const published = state.publish(state.create(), photo);
  assert.equal(state.canChoose(published), false);
  assert.throws(() => state.choose(published, 'blue'), /바꿀 수 없어요/);
});

test('restore keeps the month history intact and costs one credit', () => {
  const initial = state.create();
  const restored = state.restore(initial, '2026-09-03', 'blue');
  assert.equal(restored.restoreCredits, 1);
  assert.equal(restored.history.length, 5);
  assert.deepEqual(restored.history[2], { date: '2026-09-03', paletteId: 'blue', kind: 'restored' });
  assert.deepEqual(restored.history.filter((entry) => entry.kind === 'posted'), initial.history);
  assert.equal(initial.restoreCredits, 2);
  assert.equal(initial.history.length, 4);
});

test('restored history is not an own post and does not unlock today feed', () => {
  const restored = state.restore(state.create(), '2026-09-03', 'sage');
  assert.equal(restored.post, null);
  assert.equal(state.canView(restored, { date: state.TODAY, paletteId: 'sage' }), false);
  assert.equal(restored.history.filter((entry) => entry.kind === 'posted').length, 4);
  assert.equal(state.canChoose(restored), true);
});

test('restore rejects today, future dates, other months, and impossible calendar dates', () => {
  for (const date of [state.TODAY, '2026-09-07', '2026-08-03', '2026-10-03', '2026-09-00', '2026-09-31', '2026-9-3', 'invalid']) {
    assert.throws(() => state.restore(state.create(), date, 'sage'), /빈 기록만 복원/);
  }
});

test('restore rejects existing posted and restored dates without charging again', () => {
  const initial = state.create();
  assert.throws(() => state.restore(initial, '2026-09-01', 'sage'), /이미 색/);
  const restored = state.restore(initial, '2026-09-03', 'sage');
  assert.throws(() => state.restore(restored, '2026-09-03', 'butter'), /이미 색/);
  assert.equal(restored.restoreCredits, 1);
});

test('restore allows exactly two monthly credits, never a third', () => {
  const sparseMonth = { ...state.create(), history: [] };
  const first = state.restore(sparseMonth, '2026-09-01', 'sage');
  const second = state.restore(first, '2026-09-02', 'butter');
  assert.equal(second.restoreCredits, 0);
  assert.throws(() => state.restore(second, '2026-09-03', 'blue'), /모두 사용/);
  assert.equal(second.history.length, 2);
});

test('restore validates palette availability and keeps an existing own post unchanged', () => {
  assert.throws(() => state.restore(state.create(), '2026-09-03', 'rare'), /무작위 추첨/);
  assert.throws(() => state.restore(state.create(), '2026-09-03', 'unknown'), /팔레트/);
  const rare = state.restore(state.create({ rare: true }), '2026-09-03', 'rare');
  assert.equal(rare.history[2].paletteId, 'rare');
  const published = state.publish(state.create(), photo);
  const restored = state.restore(published, '2026-09-03', 'butter');
  assert.equal(restored.post, published.post);
  assert.equal(state.canView(restored, { date: state.TODAY, paletteId: 'sage' }), true);
});

test('invite remembers its palette and acceptance selects and freezes that same palette', () => {
  const initial = state.create();
  const invited = state.invite(initial);
  assert.equal(invited.twin.status, 'invited');
  assert.equal(invited.twin.paletteId, 'sage');
  assert.equal(state.canChoose(invited), true);
  const paired = state.acceptTwin(state.choose(invited, 'blue'));
  assert.equal(paired.twin.status, 'paired');
  assert.equal(paired.confirmed, true);
  assert.equal(paired.selected, 'sage');
  assert.equal(state.canChoose(paired), false);
  assert.throws(() => state.choose(paired, 'blue'), /바꿀 수 없어요/);
  const published = state.publish(paired, photo);
  assert.equal(published.post.paletteId, published.twin.paletteId);
});

test('a posted palette cannot be overwritten by accepting an older different-palette invitation', () => {
  const invited = state.invite(state.create());
  const published = state.publish(state.choose(invited, 'blue'), photo);
  assert.throws(() => state.acceptTwin(published), /팔레트가 달라/);
  assert.equal(published.selected, 'blue');
  assert.equal(published.post.paletteId, 'blue');
});

test('a confirmed palette cannot be overwritten by accepting an older different-palette invitation', () => {
  const invited = state.invite(state.create());
  const confirmed = deepFreeze(state.confirm(state.choose(invited, 'blue')));
  assert.throws(() => state.acceptTwin(confirmed), /확정한 팔레트/);
  assert.equal(confirmed.selected, 'blue');
  assert.equal(confirmed.twin.status, 'invited');
  const matching = state.confirm(state.invite(state.create()));
  assert.equal(state.acceptTwin(matching).selected, 'sage');
});

test('pair photos become visible when own photo is first and friend photo arrives second', () => {
  const paired = state.acceptTwin(state.invite(state.create()));
  assert.equal(state.twinVisible(paired), false);
  const ownFirst = state.publish(paired, photo);
  assert.equal(state.twinVisible(ownFirst), false);
  const both = state.simulateFriendPost(ownFirst, friendPhoto);
  assert.equal(state.twinVisible(both), true);
  assert.deepEqual(both.twin.friendPhoto, friendPhoto);
  assert.notEqual(both.twin.friendPhoto, friendPhoto);
  assert.equal(ownFirst.twin.friendPosted, false);
});

test('pair photos become visible when friend photo is first and own photo arrives second', () => {
  const paired = state.acceptTwin(state.invite(state.create()));
  const friendFirst = state.simulateFriendPost(paired, friendPhoto);
  assert.equal(state.twinVisible(friendFirst), false);
  assert.equal(state.canView(friendFirst, { date: state.TODAY, paletteId: 'sage' }), false);
  assert.equal(state.twinVisible(state.publish(friendFirst, photo)), true);
});

test('restoring after friend posted does not reveal pair photos', () => {
  const paired = state.acceptTwin(state.invite(state.create()));
  const friendFirst = state.simulateFriendPost(paired, friendPhoto);
  const restored = state.restore(friendFirst, '2026-09-03', 'sage');
  assert.equal(state.twinVisible(restored), false);
  assert.equal(restored.post, null);
});

test('pair visibility requires the current day and the paired palette', () => {
  const paired = state.simulateFriendPost(state.acceptTwin(state.invite(state.create())), friendPhoto);
  for (const post of [
    { date: '2026-09-05', paletteId: 'sage', photo },
    { date: state.TODAY, paletteId: 'blue', photo },
  ]) {
    assert.equal(state.twinVisible({ ...paired, post }), false);
  }
  assert.equal(state.twinVisible({ ...state.publish(paired, photo), twin: { ...paired.twin, status: 'invited' } }), false);
});

test('invalid twin transitions and empty friend photos are rejected', () => {
  const initial = state.create();
  assert.throws(() => state.acceptTwin(initial), /초대/);
  assert.throws(() => state.simulateFriendPost(initial, friendPhoto), /연결/);
  const invited = state.invite(initial);
  assert.throws(() => state.invite(invited), /진행 중/);
  assert.throws(() => state.simulateFriendPost(invited, friendPhoto), /연결/);
  const paired = state.acceptTwin(invited);
  assert.throws(() => state.acceptTwin(paired), /초대/);
  assert.throws(() => state.invite(paired), /진행 중/);
  assert.throws(() => state.simulateFriendPost(paired, { src: ' ' }), /사진/);
});

test('all state actions accept frozen inputs without mutation', () => {
  const initial = deepFreeze(state.create());
  const selected = deepFreeze(state.choose(initial, 'butter'));
  const restored = deepFreeze(state.restore(selected, '2026-09-03', 'blue'));
  const invited = deepFreeze(state.invite(restored));
  const paired = deepFreeze(state.acceptTwin(invited));
  const withFriend = deepFreeze(state.simulateFriendPost(paired, deepFreeze({ ...friendPhoto })));
  const published = state.publish(withFriend, deepFreeze({ ...photo }));
  assert.equal(state.twinVisible(published), true);
  assert.equal(initial.post, null);
  assert.equal(initial.restoreCredits, 2);
  assert.equal(initial.twin.status, 'none');
  assert.equal(initial.selected, 'sage');
});

test('browser script exports the same API as a global without CommonJS', () => {
  const sandbox = {};
  vm.runInNewContext(fs.readFileSync(require.resolve('../src/social-state.js'), 'utf8'), sandbox);
  assert.ok(sandbox.EselSocialState);
  assert.deepEqual(Object.keys(sandbox.EselSocialState).sort(), Object.keys(state).sort());
  assert.equal(sandbox.EselSocialState.create().date, state.TODAY);
});
