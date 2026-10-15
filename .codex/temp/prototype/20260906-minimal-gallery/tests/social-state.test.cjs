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
  assert.deepEqual(initial.twin, { status: 'none', proposalId: null, paletteId: null, ownPost: null, friendPost: null });
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
  assert.equal(state.canView(confirmed, { date: state.TODAY, paletteId: 'blue' }), false);
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

test('before publishing every candidate room is locked and non-candidate rooms stay public', () => {
  const initial = state.create();
  assert.deepEqual(state.candidates(initial), ['sage', 'butter', 'blue']);
  for (const paletteId of ['sage', 'butter', 'blue']) {
    assert.equal(state.canView(initial, { date: state.TODAY, paletteId }), false);
  }
  assert.equal(state.canView(initial, { date: state.TODAY, paletteId: 'rare' }), true);
  const rare = state.create({ rare: true });
  assert.deepEqual(state.candidates(rare), ['sage', 'butter', 'blue', 'rare']);
  assert.equal(state.canView(rare, { date: state.TODAY, paletteId: 'rare' }), false);
});

test('switching palettes before publishing never opens a room (review H2)', () => {
  let viewer = state.create();
  for (const paletteId of ['butter', 'blue', 'sage', 'butter']) {
    viewer = state.choose(viewer, paletteId);
    for (const room of ['sage', 'butter', 'blue']) {
      assert.equal(state.canView(viewer, { date: state.TODAY, paletteId: room }), false);
    }
  }
  const published = state.publish(viewer, photo);
  assert.equal(published.post.paletteId, 'butter');
  for (const room of ['sage', 'butter', 'blue', 'rare']) {
    assert.equal(state.canView(published, { date: state.TODAY, paletteId: room }), true);
  }
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

test('an old post never unlocks today rooms, and today own post opens every room', () => {
  const initial = state.create();
  assert.equal(state.canView({ ...initial, post: { date: '2026-09-05', paletteId: 'sage', photo } }, { date: state.TODAY, paletteId: 'sage' }), false);
  const todayPost = { ...initial, post: { date: state.TODAY, paletteId: 'butter', photo } };
  for (const paletteId of ['sage', 'butter', 'blue']) assert.equal(state.canView(todayPost, { date: state.TODAY, paletteId }), true);
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

// Five sage covers today (minute = time of day, larger is newer) plus noise from other palettes and days.
const room = [
  { id: 'ana', date: state.TODAY, paletteId: 'sage', minute: 540 },
  { id: 'bo', date: state.TODAY, paletteId: 'sage', minute: 610 },
  { id: 'cy', date: state.TODAY, paletteId: 'sage', minute: 480 },
  { id: 'di', date: state.TODAY, paletteId: 'sage', minute: 700 },
  { id: 'ed', date: state.TODAY, paletteId: 'sage', minute: 655 },
  { id: 'fo', date: state.TODAY, paletteId: 'butter', minute: 720 },
  { id: 'gu', date: '2026-09-05', paletteId: 'sage', minute: 900 },
];
const ids = (result) => result.open.map((post) => post.id);
const today = (paletteId = 'sage') => ({ date: state.TODAY, paletteId });

test('before publishing, today same-palette room shows only the three newest covers', () => {
  const initial = state.create();
  const result = state.sameColorRoom(initial, room, today());
  assert.equal(state.PREVIEW_COUNT, 3);
  assert.equal(result.access, 'preview');
  assert.deepEqual(ids(result), ['di', 'ed', 'bo']);
  assert.equal(result.hiddenCount, 2);
  assert.equal(state.canView(initial, today()), false);
});

test('hidden covers are a count only, never names or photos', () => {
  const result = state.sameColorRoom(state.create(), room, today());
  assert.deepEqual(Object.keys(result).sort(), ['access', 'hiddenCount', 'open']);
  for (const hidden of ['ana', 'cy']) assert.equal(JSON.stringify(result).includes(hidden), false);
});

test('publishing opens the whole same-palette room, newest first', () => {
  const result = state.sameColorRoom(state.publish(state.create(), photo), room, today());
  assert.equal(result.access, 'open');
  assert.deepEqual(ids(result), ['di', 'ed', 'bo', 'ana', 'cy']);
  assert.equal(result.hiddenCount, 0);
});

test('confirmation, restore and twin publication keep the room at the preview', () => {
  const confirmed = state.confirm(state.create());
  const restored = state.restore(confirmed, '2026-09-03', 'sage');
  const twinBoth = state.simulateFriendPost(state.publishTwin(readyTwin(state.create(), 'sage'), photo), friendPhoto);
  for (const viewer of [confirmed, restored, twinBoth]) {
    const result = state.sameColorRoom(viewer, room, today());
    assert.equal(result.access, 'preview');
    assert.equal(result.open.length, 3);
    assert.equal(result.hiddenCount, 2);
  }
});

test('after midnight the room is fully open, future rooms and bad dates stay closed', () => {
  const initial = state.create();
  const yesterday = state.sameColorRoom(initial, room, { date: '2026-09-05', paletteId: 'sage' });
  assert.equal(yesterday.access, 'open');
  assert.deepEqual(ids(yesterday), ['gu']);
  for (const date of ['2026-09-07', '2026-02-30', 'invalid']) {
    const closed = state.sameColorRoom(initial, [...room, { id: 'zz', date, paletteId: 'sage', minute: 1 }], { date, paletteId: 'sage' });
    assert.equal(closed.access, 'closed');
    assert.deepEqual(closed.open, []);
  }
});

test('other candidate rooms are also at the preview, non-candidate rooms are open', () => {
  const butter = state.sameColorRoom(state.choose(state.create(), 'blue'), room, today('butter'));
  assert.equal(butter.access, 'preview');
  assert.deepEqual(ids(butter), ['fo']);
  const rareRoom = [{ id: 'ra', date: state.TODAY, paletteId: 'rare', minute: 1 }, { id: 'rb', date: state.TODAY, paletteId: 'rare', minute: 2 }, { id: 'rc', date: state.TODAY, paletteId: 'rare', minute: 3 }, { id: 'rd', date: state.TODAY, paletteId: 'rare', minute: 4 }];
  const rare = state.sameColorRoom(state.create(), rareRoom, today('rare'));
  assert.equal(rare.access, 'open');
  assert.equal(rare.hiddenCount, 0);
});

test('minors see the whole room without the publishing lock', () => {
  const minor = state.create({ minor: true });
  assert.equal(minor.minor, true);
  assert.equal(state.create().minor, false);
  assert.equal(state.canView(minor, today()), true);
  const result = state.sameColorRoom(minor, room, today());
  assert.equal(result.access, 'open');
  assert.equal(result.open.length, 5);
  assert.equal(result.hiddenCount, 0);
});

test('a small room shows every cover, ties stay stable, and inputs are not mutated', () => {
  const small = deepFreeze(room.slice(0, 2).map((post) => ({ ...post })));
  const result = state.sameColorRoom(deepFreeze(state.create()), small, today());
  assert.deepEqual(ids(result), ['bo', 'ana']);
  assert.equal(result.hiddenCount, 0);
  const tied = [{ id: 'b', date: state.TODAY, paletteId: 'sage', minute: 600 }, { id: 'a', date: state.TODAY, paletteId: 'sage', minute: 600 }];
  assert.deepEqual(ids(state.sameColorRoom(state.create(), tied, today())), ['a', 'b']);
  assert.deepEqual(state.sameColorRoom(state.create(), null, today()), { access: 'preview', open: [], hiddenCount: 0 });
  assert.throws(() => state.sameColorRoom(state.create(), room, { date: state.TODAY, paletteId: 'unknown' }), /팔레트/);
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

const readyTwin = (initial = state.create(), color = 'butter') => state.approveTwinColor(state.proposeTwinColor(state.acceptTwin(state.invite(initial),()=>.999), color));

test('invite and acceptance carry no color and do not lock personal choice', () => {
  const invited = state.invite(state.create());
  assert.equal(invited.twin.paletteId, null);
  assert.equal(invited.twin.proposalId, null);
  const paired = state.acceptTwin(invited,()=>.999);
  assert.equal(paired.twin.status, 'paired');
  assert.equal(paired.confirmed, false);
  assert.equal(state.canChoose(paired), true);
  assert.equal(state.choose(paired, 'blue').selected, 'blue');
});

test('proposal requires acceptance and approval requires a proposal', () => {
  for (const initial of [state.create(), state.invite(state.create())]) {
    assert.throws(()=>state.proposeTwinColor(initial, 'sage'), /친구 참여/);
    assert.throws(()=>state.approveTwinColor(initial), /선택|제안/);
    assert.throws(()=>state.publishTwin(initial, photo), /확정/);
  }
  const paired=state.acceptTwin(state.invite(state.create()),()=>.999);
  assert.throws(()=>state.approveTwinColor(paired), /선택|제안/);
  for(const color of ['rare','unknown',null]) assert.throws(()=>state.proposeTwinColor(paired,color), /하나/);
  const proposed=state.proposeTwinColor(paired,'blue');
  assert.equal(proposed.twin.paletteId,null);
  assert.throws(()=>state.publishTwin(proposed,photo), /확정/);
  assert.throws(()=>state.simulateFriendPost(proposed,friendPhoto), /확정/);
  const ready=state.approveTwinColor(proposed);
  assert.equal(ready.twin.paletteId,'blue');
  assert.equal(ready.twin.proposalId,null);
  assert.throws(()=>state.proposeTwinColor(ready,'sage'), /확정 전에/);
});

test('friend can request another color before agreement', () => {
  const proposed=state.proposeTwinColor(state.acceptTwin(state.invite(state.create()),()=>.999),'sage');
  const declined=state.declineTwinColor(proposed);
  assert.equal(declined.twin.status,'paired');
  assert.equal(declined.twin.proposalId,null);
  assert.equal(state.approveTwinColor(state.proposeTwinColor(declined,'blue')).twin.paletteId,'blue');
  assert.throws(()=>state.declineTwinColor(declined),/선택|제안/);
});

test('personal confirmed color and existing post survive the full twin flow', () => {
  for(const initial of [state.confirm(state.choose(state.create(),'blue')),state.publish(state.choose(state.create(),'blue'),photo)]) {
    const ready=readyTwin(initial,'butter');
    const both=state.simulateFriendPost(state.publishTwin(ready,photo),friendPhoto);
    assert.equal(both.selected,'blue');
    assert.equal(both.confirmed,initial.confirmed);
    assert.equal(both.post,initial.post);
    assert.equal(both.history,initial.history);
    assert.equal(both.restoreCredits,initial.restoreCredits);
    assert.equal(both.rareEligible,initial.rareEligible);
    assert.equal(state.twinVisible(both),true);
  }
});

test('personal publication cannot count as a twin publication', () => {
  const ready=readyTwin(state.create(),'sage');
  const personal=state.publish(ready,photo);
  const friend=state.simulateFriendPost(personal,friendPhoto);
  assert.equal(friend.twin.ownPost,null);
  assert.equal(state.twinVisible(friend),false);
  assert.equal(state.twinVisible(state.publishTwin(friend,photo)),true);
});

test('own then friend reveals only twin photos and never personal same-color feed', () => {
  const ready=readyTwin(state.create(),'sage');
  const own=state.publishTwin(ready,photo);
  assert.equal(state.twinVisible(own),false);
  const both=state.simulateFriendPost(own,friendPhoto);
  assert.equal(state.twinVisible(both),true);
  assert.equal(both.post,null);
  assert.equal(both.history.length,4);
  assert.equal(state.canView(both,{date:state.TODAY,paletteId:'sage'}),false);
  assert.equal(state.canChoose(both),true);
  assert.notEqual(both.twin.ownPost.photo,photo);
  assert.notEqual(both.twin.friendPost.photo,friendPhoto);
});

test('friend then own uses the same reveal rule and restore is not a twin post', () => {
  const friend=state.simulateFriendPost(readyTwin(),friendPhoto);
  const restored=state.restore(friend,'2026-09-03','blue');
  assert.equal(state.twinVisible(restored),false);
  assert.equal(state.twinVisible(state.publishTwin(restored,photo)),true);
});

test('both twin posts must have their selected color, current date, and photo', () => {
  const both=state.simulateFriendPost(state.publishTwin(readyTwin(),photo),friendPhoto);
  for(const field of ['ownPost','friendPost']) {
    for(const bad of [{...both.twin[field],date:'2026-09-05'}, {...both.twin[field],paletteId:'blue'}, {...both.twin[field],photo:null}]) {
      assert.equal(state.twinVisible({...both,twin:{...both.twin,[field]:bad}}),false);
    }
  }
  assert.equal(state.twinVisible({...both,twin:{...both.twin,status:'proposed'}}),false);
});

test('invalid transitions, empty photos and duplicate twin posts are rejected', () => {
  assert.throws(()=>state.acceptTwin(state.create()),/초대/);
  const invited=state.invite(state.create());
  assert.throws(()=>state.invite(invited),/진행 중/);
  const ready=readyTwin();
  assert.throws(()=>state.acceptTwin(ready),/초대/);
  for(const invalid of [null,undefined,{}, {src:' '}, {src:3}]) {
    assert.throws(()=>state.publishTwin(ready,invalid),/사진/);
    assert.throws(()=>state.simulateFriendPost(ready,invalid),/사진/);
  }
  assert.throws(()=>state.publishTwin(state.publishTwin(ready,photo),photo),/이미 게시/);
  assert.throws(()=>state.simulateFriendPost(state.simulateFriendPost(ready,friendPhoto),friendPhoto),/이미 게시/);
});

test('all state actions accept frozen inputs without mutation', () => {
  const initial=deepFreeze(state.create());
  const restored=deepFreeze(state.restore(deepFreeze(state.choose(initial,'blue')),'2026-09-03','sage'));
  const invited=deepFreeze(state.invite(restored));
  const paired=deepFreeze(state.acceptTwin(invited,()=>.999));
  const proposed=deepFreeze(state.proposeTwinColor(paired,'butter'));
  const declined=deepFreeze(state.declineTwinColor(proposed));
  const ready=deepFreeze(state.approveTwinColor(deepFreeze(state.proposeTwinColor(declined,'sage'))));
  const friend=deepFreeze(state.simulateFriendPost(ready,deepFreeze({...friendPhoto})));
  const both=deepFreeze(state.publishTwin(friend,deepFreeze({...photo})));
  const personal=state.publish(both,photo);
  assert.equal(state.twinVisible(personal),true);
  assert.equal(initial.post,null);
  assert.equal(initial.restoreCredits,2);
  assert.equal(initial.twin.status,'none');
});

test('browser script exports the same API as a global without CommonJS', () => {
  const sandbox = {};
  vm.runInNewContext(fs.readFileSync(require.resolve('../src/social-state.js'), 'utf8'), sandbox);
  assert.ok(sandbox.EselSocialState);
  assert.deepEqual(Object.keys(sandbox.EselSocialState).sort(), Object.keys(state).sort());
  assert.equal(sandbox.EselSocialState.create().date, state.TODAY);
});
