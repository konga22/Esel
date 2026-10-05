(() => {
  'use strict';
  const colors = {
    sage: { name: '세이지', hex: '#A8B5A0', paint: 'assets/paint-sage.png', photo: 'assets/green-blouse.jpg' },
    butter: { name: '버터', hex: '#E5C982', paint: 'assets/paint-butter.png', photo: 'assets/yellow-street.jpg' },
    'powder-blue': { name: '파우더 블루', hex: '#9BB8CF', paint: 'assets/paint-powder-blue.png', photo: 'assets/blue-outfit.jpg' }
  };
  const posts = [
    { id: 'sora', author: 'sora', color: 'sage', photo: 'assets/green-blouse.jpg', avatar: 'assets/green-skirt.jpg', ratio: .8 },
    { id: 'elle', author: 'elle', color: 'butter', photo: 'assets/yellow-street.jpg', avatar: 'assets/yellow-street.jpg', ratio: .76 },
    { id: 'haru', author: 'haru', color: 'powder-blue', photo: 'assets/blue-outfit.jpg', avatar: 'assets/blue-outfit.jpg', ratio: .87 }
  ];
  const heart = '<svg aria-hidden="true" viewBox="0 0 24 24"><path class="heart-shape" d="M20.8 4.8a5.5 5.5 0 0 0-7.8 0L12 5.9l-1.1-1.1a5.5 5.5 0 0 0-7.8 7.8L12 21l8.8-8.4a5.5 5.5 0 0 0 0-7.8Z" stroke-linejoin="round"/></svg>';
  const share = '<svg aria-hidden="true" viewBox="0 0 24 24"><path d="m21 3-7.2 18-3.9-7.1L3 10.1 21 3Zm0 0L9.9 13.9" stroke-linecap="round" stroke-linejoin="round"/></svg>';
  let selectedColor = 'sage';
  let ownPost = null;
  let noticeTimer;

  function postMarkup(post) {
    const color = colors[post.color];
    return `<article class="post" id="post-${post.id}" aria-label="${post.author}의 샘플 착장"><header class="post-header"><img class="avatar" src="${post.avatar}" alt="${post.author} 샘플 프로필"><span class="username">${post.author}</span><button class="paint-button" data-show-color="${post.color}" aria-label="${post.author}의 오늘의 색: ${color.name}"><img class="paint-image" src="${color.paint}" alt=""></button></header><img class="post-photo" style="--ratio:${post.ratio}" src="${post.photo}" alt="${color.name} 포인트 착장 · 스톡 샘플 사진" loading="${post.id === 'sora' ? 'eager' : 'lazy'}"><div class="post-actions"><button class="icon-button" data-like="${post.id}" aria-label="${post.author} 좋아요" aria-pressed="false">${heart}</button><button class="icon-button" data-share="${post.id}" aria-label="${post.author} 공유">${share}</button></div></article>`;
  }
  document.getElementById('post-list').innerHTML = posts.map(postMarkup).join('');

  function notify(text) {
    const notice = document.getElementById('notice');
    clearTimeout(noticeTimer); notice.textContent = text; notice.hidden = false;
    noticeTimer = setTimeout(() => { notice.hidden = true; }, 2500);
  }
  function navigate(screen) {
    document.querySelectorAll('[data-screen]').forEach(el => el.hidden = el.dataset.screen !== screen);
    document.querySelectorAll('[role="tab"][data-nav]').forEach(el => el.setAttribute('aria-selected', String(el.dataset.nav === screen)));
  }
  document.querySelectorAll('[data-nav]').forEach(button => button.addEventListener('click', () => navigate(button.dataset.nav)));

  document.addEventListener('click', event => {
    const button = event.target.closest('button');
    if (!button) return;
    if (button.hasAttribute('data-like')) {
      const liked = button.getAttribute('aria-pressed') !== 'true';
      button.setAttribute('aria-pressed', String(liked));
      button.classList.toggle('liked', liked);
    }
    if (button.hasAttribute('data-show-color')) {
      const color = colors[button.dataset.showColor];
      const dialog = document.getElementById('color-dialog');
      dialog.querySelector('img').src = color.paint;
      dialog.querySelector('img').alt = `${color.name} 아크릴 물감`;
      dialog.querySelector('h2').textContent = color.name;
      dialog.querySelector('.reference-swatch').style.backgroundColor = color.hex;
      dialog.showModal();
    }
    if (button.hasAttribute('data-share')) {
      const url = new URL(location.href); url.hash = `post-${button.dataset.share}`;
      document.getElementById('share-link').value = url.href;
      document.getElementById('share-dialog').showModal();
    }
    if (button.hasAttribute('data-close')) button.closest('dialog').close();
  });
  document.querySelectorAll('dialog').forEach(dialog => dialog.addEventListener('click', event => { if (event.target === dialog) dialog.close(); }));
  document.getElementById('copy-link').addEventListener('click', async () => {
    const input = document.getElementById('share-link');
    try { await navigator.clipboard.writeText(input.value); notify('시안 링크를 복사했어요.'); }
    catch { input.focus(); input.select(); notify('링크를 선택했어요. 직접 복사해주세요.'); }
  });

  const colorButtons = [...document.querySelectorAll('[data-select-color]')];
  colorButtons.forEach((button, index) => {
    function select() {
      selectedColor = button.dataset.selectColor;
      colorButtons.forEach(el => el.setAttribute('aria-checked', String(el.dataset.selectColor === selectedColor)));
    }
    button.addEventListener('click', select);
    button.addEventListener('keydown', event => {
      if (!['ArrowUp','ArrowDown','ArrowLeft','ArrowRight'].includes(event.key)) return;
      event.preventDefault();
      const delta = ['ArrowUp','ArrowLeft'].includes(event.key) ? -1 : 1;
      const next = colorButtons[(index + delta + colorButtons.length) % colorButtons.length];
      next.click(); next.focus();
    });
  });
  document.getElementById('sample-record').addEventListener('click', () => {
    const color = colors[selectedColor];
    ownPost = { id: 'my-sample', author: '나의 샘플', color: selectedColor, photo: color.photo, avatar: color.photo, ratio: .8 };
    document.getElementById('own-post').innerHTML = postMarkup(ownPost);
    notify('외부 전송 없이 샘플을 남겼어요.');
  });
  const target = document.getElementById(location.hash.slice(1));
  if (target?.classList.contains('post')) requestAnimationFrame(() => target.scrollIntoView({ block: 'start' }));
})();
