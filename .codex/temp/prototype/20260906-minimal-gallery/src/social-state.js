(function (root, factory) {
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.EselSocialState = api;
})(typeof globalThis !== 'undefined' ? globalThis : this, function () {
  'use strict';

  const TODAY = '2026-09-06';
  const MONTH = '2026-09';
  const PALETTE_IDS = ['sage', 'butter', 'blue', 'rare'];
  // Before today's own publication the same-palette room opens only this many newest covers (2026-10-05 decision).
  const PREVIEW_COUNT = 3;

  function assertPalette(state, paletteId, requireEligibility = true) {
    if (!PALETTE_IDS.includes(paletteId)) {
      throw new Error('사용할 수 없는 팔레트예요.');
    }
    if (requireEligibility && paletteId === 'rare' && !state.rareEligible) {
      throw new Error('희귀 팔레트는 오늘의 무작위 추첨으로 만날 수 있어요.');
    }
  }

  function isCalendarDate(date) {
    if (typeof date !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(date)) return false;
    const parsed = new Date(date + 'T00:00:00.000Z');
    return Number.isFinite(parsed.getTime()) && parsed.toISOString().slice(0, 10) === date;
  }

  function copyPhoto(photo) {
    if (!photo || typeof photo.src !== 'string' || photo.src.trim() === '') {
      throw new Error('게시할 사진을 먼저 골라 주세요.');
    }
    return { ...photo };
  }

  function create({ rare = false, minor = false } = {}) {
    return {
      date: TODAY,
      selected: rare ? 'rare' : 'sage',
      confirmed: false,
      rareEligible: Boolean(rare),
      minor: Boolean(minor),
      post: null,
      history: [
        { date: '2026-09-01', paletteId: 'sage', kind: 'posted' },
        { date: '2026-09-02', paletteId: 'butter', kind: 'posted' },
        { date: '2026-09-04', paletteId: 'blue', kind: 'posted' },
        { date: '2026-09-05', paletteId: 'sage', kind: 'posted' },
      ],
      restoreCredits: 2,
      twin: { status: 'none', proposalId: null, paletteId: null, ownPost: null, friendPost: null },
    };
  }

  function canChoose(state) {
    return !state.confirmed && !state.post;
  }

  function choose(state, paletteId) {
    assertPalette(state, paletteId);
    if (!canChoose(state)) {
      throw new Error('팔레트를 확정하거나 게시한 뒤에는 오늘의 팔레트를 바꿀 수 없어요.');
    }
    return { ...state, selected: paletteId };
  }

  function confirm(state) {
    assertPalette(state, state.selected);
    return state.confirmed ? state : { ...state, confirmed: true };
  }

  function publish(state, photo) {
    if (state.post) throw new Error('오늘의 사진을 이미 게시했어요.');
    assertPalette(state, state.selected);
    const post = { date: TODAY, paletteId: state.selected, photo: copyPhoto(photo) };
    const history = [
      ...state.history.filter((entry) => entry.date !== TODAY),
      { date: TODAY, paletteId: state.selected, kind: 'posted' },
    ].sort((left, right) => left.date.localeCompare(right.date));
    return { ...state, confirmed: true, post, history };
  }

  // The palettes this person may publish with today. Rare joins only after a winning draw.
  function candidates(state) {
    return PALETTE_IDS.filter((id) => id !== 'rare' || state.rareEligible);
  }

  // Every candidate room stays at the preview until today's own publication (2026-10-15 decision),
  // so switching the selected palette back and forth before publishing never opens a room.
  function canView(state, { date, paletteId }) {
    assertPalette(state, paletteId, false);
    if (!isCalendarDate(date)) return false;
    if (date < TODAY) return true;
    if (date > TODAY) return false;
    if (!candidates(state).includes(paletteId)) return true;
    if (state.minor) return true;
    return Boolean(state.post && state.post.date === TODAY);
  }

  const newestFirst = (a, b) => (b.minute || 0) - (a.minute || 0) || String(a.id).localeCompare(String(b.id));

  // canView answers "is the whole room open"; this also gives the partial room before publishing.
  // Hidden covers are returned only as a count so their names and photos never reach the screen.
  function sameColorRoom(state, posts, { date, paletteId }) {
    assertPalette(state, paletteId, false);
    const access = !isCalendarDate(date) || date > TODAY ? 'closed' : canView(state, { date, paletteId }) ? 'open' : 'preview';
    const room = (Array.isArray(posts) ? posts : [])
      .filter((post) => post && post.date === date && post.paletteId === paletteId)
      .sort(newestFirst);
    const shown = access === 'open' ? room : access === 'preview' ? room.slice(0, PREVIEW_COUNT) : [];
    return { access, open: shown, hiddenCount: room.length - shown.length };
  }

  function restore(state, date, paletteId) {
    if (!isCalendarDate(date) || date.slice(0, 7) !== MONTH || date >= TODAY) {
      throw new Error('이번 달에 지나간 날짜의 빈 기록만 복원할 수 있어요.');
    }
    if (state.history.some((entry) => entry.date === date)) {
      throw new Error('이미 색이 남아 있는 날짜예요.');
    }
    assertPalette(state, paletteId);
    if (state.restoreCredits <= 0) throw new Error('이번 달의 복원 기회를 모두 사용했어요.');
    const history = [
      ...state.history,
      { date, paletteId, kind: 'restored' },
    ].sort((left, right) => left.date.localeCompare(right.date));
    return { ...state, history, restoreCredits: state.restoreCredits - 1 };
  }

  function invite(state) {
    if (state.twin.status !== 'none') throw new Error('이미 진행 중인 트윈 초대가 있어요.');
    return {
      ...state,
      twin: { ...state.twin, status: 'invited' },
    };
  }

  function acceptTwin(state, random = Math.random) {
    if (state.twin.status !== 'invited') throw new Error('먼저 친구에게 트윈 초대를 보내 주세요.');
    const pool=['sage','butter','blue','coral','violet'];
    for(let i=pool.length-1;i>0;i--){const value=random();if(!Number.isFinite(value)||value<0||value>=1)throw new Error('올바른 추첨값이 필요해요.');const j=Math.floor(value*(i+1));[pool[i],pool[j]]=[pool[j],pool[i]];}
    const recommendations={own:[pool[0],pool[1],pool[2]],friend:[pool[0],pool[3],pool[4]]};
    return {
      ...state,
      twin: { ...state.twin, status: 'paired', sharedId:pool[0], recommendations },
    };
  }

  function proposeTwinColor(state, paletteId) {
    if (!['paired', 'proposed'].includes(state.twin.status)) throw new Error('친구 참여 후, 색 확정 전에 제안할 수 있어요.');
    if (!state.twin.recommendations.own.includes(paletteId)) throw new Error('나에게 추천된 색 하나를 골라 주세요.');
    return { ...state, twin: { ...state.twin, status: 'proposed', proposalId: paletteId } };
  }

  function approveTwinColor(state, friendColor = state.twin.sharedId) {
    if (state.twin.status !== 'proposed') throw new Error('먼저 내 색을 선택해 주세요.');
    if (!state.twin.recommendations.friend.includes(friendColor)) throw new Error('친구에게 추천된 색을 골라 주세요.');
    return { ...state, twin: { ...state.twin, status: 'ready', paletteId: state.twin.proposalId, friendPaletteId:friendColor, proposalId: null } };
  }

  function declineTwinColor(state) {
    if (state.twin.status !== 'proposed') throw new Error('검토할 공통색 제안이 없어요.');
    return { ...state, twin: { ...state.twin, status: 'paired', proposalId: null } };
  }

  function publishTwin(state, photo) {
    if (state.twin.status !== 'ready') throw new Error('공통색을 함께 확정한 뒤 게시해 주세요.');
    if (state.twin.ownPost) throw new Error('트윈 사진을 이미 게시했어요.');
    return { ...state, twin: { ...state.twin, ownPost: { date: TODAY, paletteId: state.twin.paletteId, photo: copyPhoto(photo) } } };
  }

  function simulateFriendPost(state, photo) {
    if (state.twin.status !== 'ready') throw new Error('공통색을 함께 확정한 뒤 게시해 주세요.');
    if (state.twin.friendPost) throw new Error('친구가 트윈 사진을 이미 게시했어요.');
    return {
      ...state,
      twin: { ...state.twin, friendPost: { date: TODAY, paletteId: state.twin.friendPaletteId, photo: copyPhoto(photo) } },
    };
  }

  function twinVisible(state) {
    return Boolean(
      state.twin.status === 'ready' &&
      ['own','friend'].every(actor => state.twin.recommendations?.[actor]?.includes(actor==='own'?state.twin.paletteId:state.twin.friendPaletteId)) &&
      [state.twin.ownPost, state.twin.friendPost].every((post,index) =>
        post && post.photo && typeof post.photo.src === 'string' && post.photo.src.trim() &&
        post.date === TODAY && post.paletteId === (index===0?state.twin.paletteId:state.twin.friendPaletteId))
    );
  }

  function isRareDraw(randomValue) {
    if (typeof randomValue !== 'number' || !Number.isFinite(randomValue) || randomValue < 0 || randomValue >= 1) {
      throw new Error('추첨값은 0 이상 1 미만의 숫자여야 해요.');
    }
    // Fixed probability for this mock draw; this is not a measured population rate.
    return randomValue < 0.032;
  }

  return { TODAY, MONTH, PREVIEW_COUNT, create, choose, confirm, publish, candidates, canView, sameColorRoom, restore, invite, acceptTwin, proposeTwinColor, approveTwinColor, declineTwinColor, publishTwin, simulateFriendPost, twinVisible, canChoose, isRareDraw };
});
