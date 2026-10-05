(() => {
  'use strict';
  if (document.body.hasAttribute('data-compare')) {
    const descriptions = {
      specimen: '색 하나를 표본처럼. 큰 색면과 어긋난 주석, 여백을 가로지르는 색 이름.',
      editorial: '사진 한 장을 화보처럼. 착장과 색면, 큰 글자를 겹쳐 만드는 독립 패션지.'
    };
    const buttons = [...document.querySelectorAll('[data-direction]')];
    function chooseDirection(direction, focus = false) {
      if (!descriptions[direction]) return;
      buttons.forEach(button => {
        const active = button.dataset.direction === direction;
        button.setAttribute('aria-selected', String(active));
        button.tabIndex = active ? 0 : -1;
        if (active && focus) button.focus();
      });
      const frame = document.getElementById('design-preview');
      frame.src = `${direction}.html?device=mock`;
      frame.title = direction === 'specimen' ? '색의 표본실 미리보기' : '독립 패션지 미리보기';
      document.getElementById('direction-note').textContent = descriptions[direction];
    }
    buttons.forEach((button, index) => {
      button.addEventListener('click', () => chooseDirection(button.dataset.direction));
      button.addEventListener('keydown', event => {
        if (!['ArrowLeft', 'ArrowRight'].includes(event.key)) return;
        event.preventDefault();
        chooseDirection(buttons[(index + 1) % buttons.length].dataset.direction, true);
      });
    });
    const initial = new URLSearchParams(location.search).get('view');
    if (initial && descriptions[initial]) chooseDirection(initial);
    else buttons[1].tabIndex = -1;
    return;
  }

  if (!document.body.dataset.variant) return;
  const editorial = document.body.dataset.variant === 'editorial';
  const colors = {
    sage: { name: '세이지', english: 'Sage', index: '01', hex: '#A8B5A0', photo: editorial ? 'assets/green-skirt.jpg' : 'assets/green-blouse.jpg' },
    butter: { name: '버터', english: 'Butter', index: '02', hex: '#E5C982', photo: 'assets/yellow-dress.jpg' },
    'powder-blue': { name: '파우더 블루', english: 'Powder blue', index: '03', hex: '#9BB8CF', photo: 'assets/blue-city.jpg' }
  };
  let selected = 'sage';
  let record = null;
  let previousFocus = null;

  if (new URLSearchParams(location.search).get('device') === 'mock') {
    document.body.dataset.device = 'mock';
    document.body.insertAdjacentHTML('afterbegin', `<div class="mock-status" aria-hidden="true"><span>9:41</span><span class="mock-island"></span><span class="mock-signals"><svg viewBox="0 0 18 14" fill="currentColor"><rect x="1" y="9" width="3" height="4" rx=".5"/><rect x="5" y="6" width="3" height="7" rx=".5"/><rect x="9" y="3" width="3" height="10" rx=".5"/><rect x="13" y="0" width="3" height="13" rx=".5"/></svg><svg viewBox="0 0 18 14" fill="none" stroke="currentColor" stroke-width="1.7"><path d="M1 4q8-6 16 0M4 7q5-4 10 0M7 10q2-2 4 0"/><circle cx="9" cy="12" r=".8" fill="currentColor"/></svg><svg viewBox="0 0 24 14" fill="none" stroke="currentColor"><rect x="1" y="2" width="19" height="10" rx="2"/><rect x="3" y="4" width="15" height="6" rx=".5" fill="currentColor"/><path d="M22 5v4" stroke-width="2"/></svg></span></div><div class="mock-home" aria-hidden="true"></div>`);
  }

  const dialog = document.createElement('dialog');
  dialog.className = 'record-dialog';
  dialog.setAttribute('aria-labelledby', 'record-title');
  dialog.innerHTML = `<form id="record-form"><div class="record-top"><span>코디 기록 / 시안 체험</span><button class="record-close" type="button" aria-label="기록 닫기">×</button></div><h2 id="record-title">입은 색을 남겨요.</h2><img class="record-photo" alt="선택한 색의 샘플 착장"><label class="record-caption-label" for="record-caption">짧은 기록 <span>— 선택</span></label><textarea id="record-caption" maxlength="120" placeholder="오늘의 색을 어디에서 발견했나요?"></textarea><button class="record-submit" type="submit">샘플로 기록하기 ↗</button><p class="record-note">스톡 사진으로 경험하는 시안입니다.<br>외부 전송 없이 체험하며 새로고침하면 기록이 사라져요.</p></form>`;
  document.body.append(dialog);

  function renderColor() {
    const color = colors[selected];
    const colorFor = el => record && el.closest('[data-screen="exhibition"]') ? colors[record.color] : color;
    document.body.style.setProperty('--tone', color.hex);
    document.body.dataset.color = selected;
    document.querySelectorAll('[data-color-name]').forEach(el => el.textContent = colorFor(el).name);
    document.querySelectorAll('[data-color-english]').forEach(el => el.textContent = colorFor(el).english);
    document.querySelectorAll('[data-color-index]').forEach(el => el.textContent = colorFor(el).index);
    document.querySelectorAll('[data-screen="exhibition"]').forEach(el => {
      el.style.setProperty('--tone', colorFor(el).hex);
      el.dataset.recordColor = record?.color || selected;
    });
    document.querySelectorAll('[data-color]').forEach(el => {
      if (el.matches('button')) el.setAttribute('aria-checked', String(el.dataset.color === selected));
    });
    document.querySelectorAll('[data-color-photo]').forEach(img => {
      const photoColor = colorFor(img);
      img.src = photoColor.photo;
      img.alt = `${photoColor.name} 착장 · 스톡 샘플 사진`;
    });
  }

  function showScreen(screen) {
    document.querySelectorAll('[data-screen]').forEach(el => el.hidden = el.dataset.screen !== screen);
    document.querySelectorAll('[data-view]').forEach(button => {
      if (button.dataset.view === screen) button.setAttribute('aria-current', 'page');
      else button.removeAttribute('aria-current');
    });
    const shown = document.querySelector(`[data-screen="${screen}"]`);
    const heading = shown?.querySelector('h1, h2');
    if (heading) { heading.tabIndex = -1; heading.focus({ preventScroll: true }); }
    if (shown) shown.scrollTop = 0;
  }

  const colorButtons = [...document.querySelectorAll('button[data-color]')];
  colorButtons.forEach((button, index) => {
    button.addEventListener('click', () => { selected = button.dataset.color; renderColor(); });
    button.addEventListener('keydown', event => {
      if (!['ArrowLeft','ArrowRight','ArrowUp','ArrowDown'].includes(event.key)) return;
      event.preventDefault();
      const delta = ['ArrowLeft','ArrowUp'].includes(event.key) ? -1 : 1;
      const next = colorButtons[(index + delta + colorButtons.length) % colorButtons.length];
      selected = next.dataset.color; renderColor(); next.focus();
    });
  });
  document.querySelectorAll('[data-view]').forEach(button => button.addEventListener('click', () => showScreen(button.dataset.view)));
  document.querySelectorAll('[data-action="record"]').forEach(button => button.addEventListener('click', () => {
    previousFocus = button;
    dialog.querySelector('img').src = colors[selected].photo;
    dialog.querySelector('img').alt = `${colors[selected].name} 샘플 착장`;
    dialog.showModal();
  }));
  dialog.querySelector('.record-close').addEventListener('click', () => dialog.close());
  dialog.addEventListener('click', event => { if (event.target === dialog) dialog.close(); });
  dialog.addEventListener('close', () => previousFocus?.focus());
  dialog.querySelector('form').addEventListener('submit', event => {
    event.preventDefault();
    record = { color: selected, caption: dialog.querySelector('textarea').value.trim() || `${colors[selected].name}를 입은 하루.` };
    document.querySelectorAll('[data-record-caption]').forEach(el => el.textContent = record.caption);
    document.querySelectorAll('[data-record-status]').forEach(el => el.textContent = '나의 샘플 기록');
    dialog.close();
    renderColor();
    showScreen('exhibition');
  });
  renderColor();
})();
