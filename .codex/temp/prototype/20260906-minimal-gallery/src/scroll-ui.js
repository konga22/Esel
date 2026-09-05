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
  preview.textContent = '로컬 데모 · 사진·기록·친구는 예시입니다';

  let state = EselHeaderState.create(feed.scrollTop);
  let scrollFrame = 0;
  let animationFrame = 0;
  let value = 1;
  let velocity = 0;
  let target = 1;
  let lastTime = 0;
  let activeScreen = document.querySelector('[data-screen]:not([hidden])').dataset.screen;
  const activeElement = () => document.querySelector(`[data-screen="${activeScreen}"]`);

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
    if (mode === 'hidden' && header.querySelector(':focus-visible')) mode = 'floating';
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
  document.querySelectorAll('[data-screen]').forEach(screen => screen.addEventListener('scroll', () => {
    if (scrollFrame || activeScreen !== screen.dataset.screen) return;
    scrollFrame = requestAnimationFrame(() => {
      scrollFrame = 0;
      if (activeScreen !== screen.dataset.screen) return;
      state = EselHeaderState.advance(state, screen.scrollTop, screen.scrollHeight - screen.clientHeight);
      render(state.mode);
    });
  }, { passive: true }));

  document.addEventListener('esel:navigate', event => {
    const nextScreen = event.detail.screen;
    if (nextScreen === 'feed' && event.detail.reset) {
      feed.scrollTo({ top: 0, behavior: 'instant' });
      state = EselHeaderState.create();
    }
    activeScreen = nextScreen;
    const top = activeElement().scrollTop;
    state = { ...EselHeaderState.create(top), mode: top <= 12 ? 'top' : 'floating' };
    render(state.mode, true);
  });
  logo.addEventListener('focus', () => render(activeElement().scrollTop <= 12 ? 'top' : 'floating', true));
  motion.addEventListener('change', () => render(state.mode, true));
  window.addEventListener('pagehide', () => { cancelAnimationFrame(animationFrame); cancelAnimationFrame(scrollFrame); });
  window.addEventListener('pageshow', () => { animationFrame = 0; scrollFrame = 0; render(state.mode, true); });
  render(state.mode, true);
})();
