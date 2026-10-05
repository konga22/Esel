(function (root, factory) {
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.EselSocialState = api;
})(typeof globalThis !== 'undefined' ? globalThis : this, function () {
  'use strict';

  const TODAY = '2026-09-06';
  const MONTH = '2026-09';
  const PALETTE_IDS = ['sage', 'butter', 'blue', 'rare'];

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

  function create({ rare = false } = {}) {
    return {
      date: TODAY,
      selected: rare ? 'rare' : 'sage',
      confirmed: false,
      rareEligible: Boolean(rare),
      post: null,
      history: [
        { date: '2026-09-01', paletteId: 'sage', kind: 'posted' },
        { date: '2026-09-02', paletteId: 'butter', kind: 'posted' },
        { date: '2026-09-04', paletteId: 'blue', kind: 'posted' },
        { date: '2026-09-05', paletteId: 'sage', kind: 'posted' },
      ],
      restoreCredits: 2,
      twin: { status: 'none', friendPosted: false, friendPhoto: null, paletteId: null },
    };
  }

  function canChoose(state) {
    return !state.confirmed && !state.post && state.twin.status !== 'paired';
  }

  function choose(state, paletteId) {
    assertPalette(state, paletteId);
    if (!canChoose(state)) {
      throw new Error('팔레트를 확정하거나 게시하거나 트윈으로 연결한 뒤에는 오늘의 팔레트를 바꿀 수 없어요.');
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
    if (state.twin.status === 'paired' && state.selected !== state.twin.paletteId) {
      throw new Error('트윈과 같은 팔레트로 게시해 주세요.');
    }
    const post = { date: TODAY, paletteId: state.selected, photo: copyPhoto(photo) };
    const history = [
      ...state.history.filter((entry) => entry.date !== TODAY),
      { date: TODAY, paletteId: state.selected, kind: 'posted' },
    ].sort((left, right) => left.date.localeCompare(right.date));
    return { ...state, confirmed: true, post, history };
  }

  function canView(state, { date, paletteId }) {
    assertPalette(state, paletteId, false);
    if (!isCalendarDate(date)) return false;
    if (date < TODAY) return true;
    if (date > TODAY) return false;
    if (paletteId !== state.selected) return true;
    return Boolean(state.post && state.post.date === TODAY && state.post.paletteId === paletteId);
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
    assertPalette(state, state.selected);
    return {
      ...state,
      twin: { ...state.twin, status: 'invited', paletteId: state.selected },
    };
  }

  function acceptTwin(state) {
    if (state.twin.status !== 'invited') throw new Error('먼저 친구에게 트윈 초대를 보내 주세요.');
    if (state.confirmed && state.selected !== state.twin.paletteId) {
      throw new Error('오늘 확정한 팔레트와 초대한 팔레트가 달라 연결할 수 없어요.');
    }
    if (state.post && state.post.paletteId !== state.twin.paletteId) {
      throw new Error('오늘 게시한 팔레트와 초대한 팔레트가 달라 연결할 수 없어요.');
    }
    assertPalette(state, state.twin.paletteId);
    return {
      ...state,
      selected: state.twin.paletteId,
      confirmed: true,
      twin: { ...state.twin, status: 'paired' },
    };
  }

  function simulateFriendPost(state, photo) {
    if (state.twin.status !== 'paired') throw new Error('트윈 연결을 먼저 완료해 주세요.');
    return {
      ...state,
      twin: { ...state.twin, friendPosted: true, friendPhoto: copyPhoto(photo) },
    };
  }

  function twinVisible(state) {
    return Boolean(
      state.twin.status === 'paired' &&
      state.twin.friendPosted &&
      state.post &&
      state.post.date === TODAY &&
      state.post.paletteId === state.twin.paletteId
    );
  }

  function isRareDraw(randomValue) {
    if (typeof randomValue !== 'number' || !Number.isFinite(randomValue) || randomValue < 0 || randomValue >= 1) {
      throw new Error('추첨값은 0 이상 1 미만의 숫자여야 해요.');
    }
    // Fixed probability for this mock draw; this is not a measured population rate.
    return randomValue < 0.032;
  }

  return { TODAY, MONTH, create, choose, confirm, publish, canView, restore, invite, acceptTwin, simulateFriendPost, twinVisible, canChoose, isRareDraw };
});
