(() => {
  'use strict';
  const params = new URLSearchParams(location.search);
  if (params.get('layout') === 'original') return;
  const phone = document.querySelector('.phone');
  const feed = document.querySelector('.feed');
  const header = document.querySelector('.app-header');
  const logo = header.querySelector('.wordmark');
  const motion = matchMedia('(prefers-reduced-motion: reduce)');
  phone.dataset.layout = params.get('layout') === 'glass' ? 'glass' : 'quiet';
  phone.dataset.header = 'top';
  feed.tabIndex = 0;
  const preview = document.querySelector('.preview-note');
  preview.textContent = `${phone.dataset.layout === 'glass' ? '사진형 · 유리 도크' : '여백형 · 텍스트 내비게이션'} · 사진은 샘플 · 기기 표시는 모의 화면`;

  let state = EselHeaderState.create(feed.scrollTop);
  let scrollFrame = 0;
  let animationFrame = 0;
  let value = 1;
  let velocity = 0;
  let target = 1;
  let lastTime = 0;
  let activeScreen = 'feed';

  function paint() {
    header.style.opacity = String(Math.min(1, Math.max(0, value)));
    header.style.transform = motion.matches ? 'none' : `translate3d(0, ${(1 - value) * -14}px, 0)`;
  }
  function tick(time) {
    const dt = Math.min((time - lastTime) / 1000 || 1 / 60, .032);
    lastTime = time;
    const omega = 24;
    const displacement = value - target;
    const impulse = velocity + omega * displacement;
    const decay = Math.exp(-omega * dt);
    value = target + (displacement + impulse * dt) * decay;
    velocity = (velocity - omega * impulse * dt) * decay;
    if (Math.abs(value - target) < .001 && Math.abs(velocity) < .01) {
      value = target; velocity = 0; animationFrame = 0; paint(); return;
    }
    paint();
    animationFrame = requestAnimationFrame(tick);
  }
  function render(mode, immediate = false) {
    // Do not remove a keyboard user's currently focused control.
    if (mode === 'hidden' && logo.matches(':focus-visible')) mode = 'floating';
    if (!immediate && phone.dataset.header === mode) return;
    phone.dataset.header = mode;
    target = mode === 'hidden' ? 0 : 1;
    header.inert = mode === 'hidden';
    logo.tabIndex = mode === 'hidden' ? -1 : 0;
    header.setAttribute('aria-hidden', String(mode === 'hidden'));
    if (motion.matches || immediate) {
      cancelAnimationFrame(animationFrame); animationFrame = 0;
      value = target; velocity = 0; paint();
    } else if (!animationFrame) {
      lastTime = performance.now();
      animationFrame = requestAnimationFrame(tick);
    }
  }
  feed.addEventListener('scroll', () => {
    if (scrollFrame || activeScreen !== 'feed') return;
    scrollFrame = requestAnimationFrame(() => {
      scrollFrame = 0;
      state = EselHeaderState.advance(state, feed.scrollTop, feed.scrollHeight - feed.clientHeight);
      render(state.mode);
    });
  }, { passive: true });

  document.querySelectorAll('[data-nav]').forEach(button => button.addEventListener('click', () => {
    const nextScreen = button.dataset.nav;
    if (nextScreen === 'feed' && activeScreen === 'feed') {
      feed.scrollTo({ top: 0, behavior: 'instant' });
      state = EselHeaderState.create();
    } else if (nextScreen === 'feed') {
      state = { ...EselHeaderState.create(feed.scrollTop), mode: feed.scrollTop <= 12 ? 'top' : 'floating' };
    }
    activeScreen = nextScreen;
    render(nextScreen === 'feed' ? state.mode : 'top', true);
  }));
  logo.addEventListener('focus', () => render(feed.scrollTop <= 12 ? 'top' : 'floating', true));
  motion.addEventListener('change', () => render(activeScreen === 'feed' ? state.mode : 'top', true));
  window.addEventListener('pagehide', () => { cancelAnimationFrame(animationFrame); cancelAnimationFrame(scrollFrame); });
  window.addEventListener('pageshow', () => { animationFrame = 0; scrollFrame = 0; render(activeScreen === 'feed' ? state.mode : 'top', true); });
  render(state.mode, true);
})();
