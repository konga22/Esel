(() => {
  'use strict';
  const Model = EselSocialState;
  const params = new URLSearchParams(location.search);
  const palettes = {
    sage: { name: '세이지', hex: '#A8B5A0', paints: ['sage'], photo: 'green-blouse.jpg', count: 428 },
    butter: { name: '버터', hex: '#E5C982', paints: ['butter'], photo: 'yellow-street.jpg', count: 316 },
    blue: { name: '파우더 블루', hex: '#9BB8CF', paints: ['powder-blue'], photo: 'blue-outfit.jpg', count: 224 },
    rare: { name: '세이지 × 버터', hex: 'linear-gradient(135deg,#A8B5A0 50%,#E5C982 50%)', paints: ['sage','butter'], photo: 'green-skirt.jpg', count: 32 }
  };
  const scenario = params.get('scenario');
  const rare = scenario === 'rare' || params.get('twin') === 'rare' || (scenario === 'random' && Model.isRareDraw(Math.random()));
  let state = Model.create({ rare });
  if (Object.hasOwn(palettes, params.get('twin'))) {
    state = Model.acceptTwin(Model.invite(Model.choose(state, params.get('twin'))));
  }
  let feedFilter = ['same','past'].includes(params.get('feed')) ? params.get('feed') : 'other';
  let profileView = 'photos';
  let currentScreen = 'today';
  let composeReturn = 'feed';
  let draft = null;
  let draftReady = false;
  let localPhotoUrl = null;
  let restoreDate = null;
  let restorePalette = state.selected;
  let timer;
  let keyboardNavigation = false;
  const liked = new Set();
  document.addEventListener('keydown', event => { if (event.key === 'Tab') keyboardNavigation = true; });
  document.addEventListener('pointerdown', () => { keyboardNavigation = false; });
  const $ = id => document.getElementById(id);
  const esc = value => String(value).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  const asset = filename => `assets/${filename}`;
  const heart = '<svg aria-hidden="true" viewBox="0 0 24 24"><path class="heart-shape" d="M20.8 4.8a5.5 5.5 0 0 0-7.8 0L12 5.9l-1.1-1.1a5.5 5.5 0 0 0-7.8 7.8L12 21l8.8-8.4a5.5 5.5 0 0 0 0-7.8Z" stroke-linejoin="round"/></svg>';
  const share = '<svg aria-hidden="true" viewBox="0 0 24 24"><path d="m21 3-7.2 18-3.9-7.1L3 10.1 21 3Zm0 0L9.9 13.9" stroke-linecap="round" stroke-linejoin="round"/></svg>';
  const people = [
    { id:'sora', author:'sora', paletteId:'sage', photo:{src:asset('green-blouse.jpg')}, avatar:asset('green-skirt.jpg'), ratio:.8 },
    { id:'elle', author:'elle', paletteId:'butter', photo:{src:asset('yellow-street.jpg')}, avatar:asset('yellow-street.jpg'), ratio:.76 },
    { id:'haru', author:'haru', paletteId:'blue', photo:{src:asset('blue-outfit.jpg')}, avatar:asset('blue-outfit.jpg'), ratio:.87 },
    { id:'mina', author:'mina', paletteId:'rare', photo:{src:asset('green-skirt.jpg')}, avatar:asset('green-skirt.jpg'), ratio:.8 }
  ];
  const allPosts = () => people.map(p => ({...p, date:Model.TODAY}));
  function paint(id, large = false) {
    return `<span class="paint-pair${large ? ' large' : ''}">${palettes[id].paints.map(p => `<img src="${asset(`paint-${p}.png`)}" alt="">`).join('')}</span>`;
  }
  function notify(message) {
    clearTimeout(timer); $('notice').textContent = message; $('notice').hidden = false;
    timer = setTimeout(() => { $('notice').hidden = true; }, 3200);
  }
  function navigate(screen) {
    const previous = currentScreen;
    if (screen === 'feed' && !state.confirmed) { state = Model.confirm(state); renderToday(); }
    currentScreen = screen;
    document.querySelectorAll('[data-screen]').forEach(el => { el.hidden = el.dataset.screen !== screen; });
    const parent = screen === 'twin' ? 'profile' : screen === 'compose' ? 'today' : screen;
    document.querySelectorAll('.app-nav [data-nav]').forEach(el => {
      if (el.dataset.nav === parent) el.setAttribute('aria-current', 'page');
      else el.removeAttribute('aria-current');
    });
    document.dispatchEvent(new CustomEvent('esel:navigate', {detail:{screen, reset:screen === 'feed' && previous === 'feed'}}));
    if (keyboardNavigation) {
      const main = document.querySelector(`[data-screen="${screen}"]`);
      main.tabIndex = -1;
      main.focus({preventScroll:true});
    }
  }
  function postMarkup(post, own = false) {
    const p = palettes[post.paletteId];
    const id = `${post.id}-${post.date}`;
    return `<article class="post" id="post-${id}" data-palette="${post.paletteId}" aria-label="${esc(post.author)}의 ${p.name} 착장"><header class="post-header"><img class="avatar" src="${esc(post.avatar)}" alt="${esc(post.author)} 프로필 · 샘플"><span class="username">${esc(post.author)}</span><button class="paint-button" data-color="${post.paletteId}" aria-label="${esc(post.author)}의 색: ${p.name}">${paint(post.paletteId)}</button>${post.date !== Model.TODAY ? '<span class="post-date">9. 5.</span>' : ''}</header><img class="post-photo" style="--ratio:${post.ratio || .8}" src="${esc(post.photo.src)}" alt="${p.name} 착장 ${own ? '내 사진' : '샘플'}" loading="lazy"><div class="post-actions"><button class="icon-button${liked.has(id) ? ' liked' : ''}" data-like="${id}" aria-label="${esc(post.author)} 좋아요" aria-pressed="${liked.has(id)}">${heart}</button>${own ? '' : `<button class="icon-button" data-share="${id}" aria-label="${esc(post.author)} 공유">${share}</button>`}</div></article>`;
  }
  function renderFeed() {
    document.querySelectorAll('[data-filter]').forEach(el => el.setAttribute('aria-pressed', String(el.dataset.filter === feedFilter)));
    const p = palettes[state.selected];
    if (feedFilter === 'same' && !Model.canView(state, {date:Model.TODAY,paletteId:state.selected})) {
      $('post-list').innerHTML = `<section class="lock-panel" aria-label="오늘의 같은 팔레트 잠금">${paint(state.selected,true)}<h2>내 색을 먼저 남겨요.</h2><p>게시하면 같은 색의 착장이 열려요.</p><button class="primary" data-action="compose">착장 남기기</button><span class="count">같은 팔레트 ${p.count}명 · 예시</span></section>`;
      return;
    }
    let posts = feedFilter === 'past' ? allPosts().map(p => ({...p,date:'2026-09-05'})) : allPosts().filter(p => feedFilter === 'same' ? p.paletteId === state.selected : p.paletteId !== state.selected);
    posts = posts.filter(p => Model.canView(state,p));
    $('post-list').innerHTML = posts.map(p => postMarkup(p)).join('');
  }
  function renderToday() {
    const locked = !Model.canChoose(state);
    const options = state.rareEligible ? ['sage','rare','blue'] : ['sage','butter','blue'];
    let content = '<div class="today-heading"><h1>오늘의 색</h1><button class="info-button" data-action="palette-info" aria-label="오늘의 색 선택 안내">ⓘ</button></div>';
    content += `<div class="palette-stage"><div class="today-options" role="group" aria-label="오늘 사용할 팔레트">${options.map(id => `<button class="today-option" data-select="${id}" aria-label="${palettes[id].name} 선택" aria-pressed="${state.selected === id}" ${locked ? 'disabled' : ''}>${paint(id)}<span class="option-name">${palettes[id].name}</span></button>`).join('')}</div>${state.selected === 'rare' ? '<button class="palette-note" data-action="rare-info">특별 조합 · 자세히</button>' : '<span class="palette-note" aria-hidden="true"></span>'}</div>`;
    content += `<div class="today-bottom">${state.post ? '<button class="primary" data-action="show-same">같은 색 감상하기 <span aria-hidden="true">↗</span></button>' : '<button class="primary" data-action="compose">착장 남기기 <svg aria-hidden="true" viewBox="0 0 24 24"><path d="M8 5h8l2 3h3v12H3V8h3l2-3Z"/><circle cx="12" cy="13" r="3.5"/></svg></button>'}<p class="today-status">${state.post ? '오늘의 색이 기록됐어요.' : locked ? '오늘의 색이 정해졌어요.' : '둘러보기를 시작하면 오늘의 색이 정해져요.'}</p></div>`;
    $('today-content').innerHTML = content;
  }
  function renderProfile() {
    const postCount = state.history.filter(h => h.kind === 'posted').length;
    const calendar = Array.from({length:30},(_,i) => {
      const day = i + 1; const date = `${Model.MONTH}-${String(day).padStart(2,'0')}`;
      const entry = state.history.find(h => h.date === date);
      const style = entry ? ` style="--day-color:${palettes[entry.paletteId].hex}"` : '';
      const label = `${day}일 ${entry ? `${palettes[entry.paletteId].name} ${entry.kind === 'restored' ? '복구 기록' : '게시 기록'}` : day === 6 ? '오늘의 빈칸' : day < 6 ? '빈칸 복구' : '아직 오지 않은 날'}`;
      return `<span class="calendar-day ${day === 6 ? 'today-day ' : ''}${!entry && day < 6 ? 'empty-past' : ''}${day > 6 ? ' future-day' : ''}" role="img" data-day="${date}" data-kind="${entry?.kind || 'empty'}" aria-label="${label}"${style}>${day}</span>`;
    }).join('');
    const records = state.history.filter(h => h.kind === 'posted').slice().reverse();
    const collection = records.map(h => {
      const src = h.date === Model.TODAY && state.post ? state.post.photo.src : asset(palettes[h.paletteId].photo);
      return `<figure class="collection-piece"><img src="${esc(src)}" alt="9월 ${Number(h.date.slice(-2))}일 ${palettes[h.paletteId].name} 착장 ${h.date === Model.TODAY ? '내 사진' : '샘플'}" loading="lazy"><figcaption><span>9. ${Number(h.date.slice(-2))}.</span><span class="record-color" style="--record-color:${palettes[h.paletteId].hex}" aria-label="${palettes[h.paletteId].name}"></span></figcaption></figure>`;
    }).join('');
    const content = profileView === 'photos' ? `<div class="collection-grid" aria-label="나의 착장 컬렉션">${collection}</div>` : `<div class="month-heading"><h2>2026. 9.</h2><span>${postCount}일의 착장</span></div><div class="weekdays" aria-hidden="true">${['일','월','화','수','목','금','토'].map(d=>`<span>${d}</span>`).join('')}</div><div class="calendar" aria-label="2026년 9월 색상 기록"><span></span><span></span>${calendar}</div><div class="record-footer"><span>쌓인 색은 사라지지 않아요.</span><button data-action="restore-empty">기록 관리 ↗</button></div>${state.history.some(h=>h.kind==='restored')?'<p class="calendar-legend">점선은 복구한 색이에요.</p>':''}`;
    $('profile-content').innerHTML = `<div class="profile-head"><img class="avatar" src="${asset('green-skirt.jpg')}" alt="내 프로필 · 샘플"><h1>나의 전시</h1>${state.rareEligible ? `<button class="paint-button" data-action="rare-info" aria-label="받은 특별 팔레트 보기">${paint('rare')}</button>` : ''}<button class="twin-entry" data-action="open-twin" aria-label="팔레트 트윈">트윈 ↗</button></div><div class="profile-switch" role="group" aria-label="내 전시 보기"><button data-profile-view="photos" aria-pressed="${profileView==='photos'}">착장</button><button data-profile-view="colors" aria-pressed="${profileView==='colors'}">색 기록</button></div>${content}`;
  }
  function renderCompose() {
    $('compose-content').innerHTML = `<div class="compose-label">${paint(state.selected)}<span>${palettes[state.selected].name}</span></div>${draft ? `<img id="draft-photo" class="compose-photo" src="${esc(draft.src)}" alt="게시할 착장 미리보기">` : '<div class="photo-placeholder">오늘의 착장을 한 장.</div>'}<div class="upload-actions"><button data-action="choose-photo">사진 고르기</button><button data-action="use-sample">샘플로 체험</button></div><button class="primary" data-action="publish" ${draftReady && draft ? '' : 'disabled'}>게시하기</button><p class="compose-caption">기기 안에서만 처리하는 데모예요.</p>`;
    const image = $('draft-photo');
    if (image) {
      const imageDraft = draft;
      const isCurrent = () => image === $('draft-photo') && imageDraft === draft;
      const ready = () => { if (!isCurrent()) return; draftReady = true; $('compose-content').querySelector('[data-action="publish"]').disabled = false; };
      image.addEventListener('load', ready);
      image.addEventListener('error', () => { if (!isCurrent()) return; draft = null; draftReady = false; renderCompose(); notify('이 사진을 열지 못했어요. 다른 사진을 골라주세요.'); });
      if (image.complete && image.naturalWidth) ready();
    }
  }
  function inviteUrl() {
    const url = new URL(location.href); url.search = ''; url.hash = '';
    url.searchParams.set('twin',state.twin.paletteId || state.selected);
    return url.href;
  }
  function renderTwin() {
    const visible = Model.twinVisible(state);
    const paired = state.twin.status === 'paired';
    const id = state.twin.paletteId || state.selected;
    const person = (name,complete,photo) => `<div><div class="twin-frame">${visible ? `<img src="${esc(photo.src)}" alt="${name}의 ${palettes[id].name} 착장">` : '<span class="waiting-mark" aria-hidden="true"></span>'}</div><div class="twin-person"><span>${name}</span><small>${complete ? '게시 완료' : '기다리는 중'}</small></div></div>`;
    let content = `<div class="twin-palette">${paint(id)}<span>${palettes[id].name}</span></div><p class="twin-caption">${visible ? '같은 색, 다른 해석.' : '둘 다 남기면, 나란히 열려요.'}</p><div class="twin-grid" aria-label="${visible ? '완성된 트윈 착장' : '두 사람 게시 전 비공개'}">${person('나',!!state.post,state.post?.photo)}${person('친구 · 샘플',state.twin.friendPosted,state.twin.friendPhoto)}</div>`;
    if (state.twin.status === 'none') content += '<button class="primary" data-action="invite">친구 초대하기 <span aria-hidden="true">↗</span></button>';
    if (state.twin.status === 'invited') content += `<label class="fine-print" for="twin-link">같은 색으로 연결되는 로컬 초대</label><input id="twin-link" class="twin-link-input" value="${esc(inviteUrl())}" readonly><button class="quiet-action" data-action="copy-twin">초대 링크 복사 <span>↗</span></button>`;
    if (paired && !state.post) content += '<button class="primary" data-action="twin-compose">내 착장 남기기</button>';
    if (paired && state.post && !state.twin.friendPosted) content += '<p class="twin-finish">친구가 남기면 함께 열려요.</p>';
    if (visible) content += '<p class="twin-finish">두 사람의 오늘이 모였어요.</p>';
    if (state.twin.status === 'invited' || (paired && !state.twin.friendPosted)) content += '<button class="quiet-action" data-action="demo-settings">친구 역할 시연 <span>↗</span></button>';
    $('twin-content').innerHTML = content;
  }
  function renderAll() { renderFeed(); renderToday(); renderProfile(); renderTwin(); }
  function openCompose(from = currentScreen) {
    if (state.post) { notify('오늘은 이미 게시했어요.'); return; }
    state=Model.confirm(state); renderToday();
    composeReturn = from === 'twin' ? 'twin' : 'feed';
    draft = null; draftReady = false; renderCompose(); navigate('compose');
  }
  function openRestore(date) {
    restoreDate = date; restorePalette = state.selected;
    if (!date) {
      $('restore-content').innerHTML = `<p class="fine-print">이번 달 복구권 ${state.restoreCredits}장 / 월 2장</p><p class="fine-print">지나간 날의 빈칸이 모두 채워졌어요.<br>새로운 기록은 그대로 이어집니다.</p>`;
      $('restore-dialog').showModal();
      return;
    }
    $('restore-content').innerHTML = `<p class="fine-print">이번 달 복구권 ${state.restoreCredits}장 / 월 2장<br>쉬어 간 날에도 이전 기록은 그대로 남아요.</p><p class="restore-date">9월 ${Number(date.slice(-2))}일의 빈칸</p><div class="restore-palette-options" role="group" aria-label="복구할 색">${['sage','butter','blue',...(state.rareEligible ? ['rare'] : [])].map(id=>`<button data-restore-color="${id}" aria-pressed="${id === restorePalette}">${palettes[id].name}</button>`).join('')}</div><button class="primary" data-action="restore-save" ${state.restoreCredits===0?'disabled':''}>복구권 1장 사용</button><p class="dialog-hint">점선으로 표시하며 실제 게시로 세지 않아요. 오늘의 같은 색 잠금도 풀리지 않아요.</p>`;
    $('restore-dialog').showModal();
  }
  async function copy(text) {
    try { await navigator.clipboard.writeText(text); notify('데모 링크를 복사했어요.'); }
    catch { notify('자동 복사가 안 돼요. 링크를 직접 선택해 복사해주세요.'); }
  }
  function showPaletteInfo(rareOnly = false) {
    $('color-title').textContent = rareOnly ? '특별 팔레트' : '오늘의 색';
    $('color-preview').innerHTML = paint(rareOnly ? 'rare' : state.selected, true) + (rareOnly ? '<p class="fine-print">가끔 만나는 두 색의 조합이에요. 받은 특별 팔레트는 내 전시에 남아요.</p><p class="fine-print">결제나 가입 기간과 관계없이 무작위로 배정합니다. 이 데모의 3.2%는 예시값이에요.</p>' : '<p class="fine-print">세 가지 중 오늘 입고 싶은 색을 골라요. 작은 포인트 하나여도 괜찮아요.</p><p class="fine-print">둘러보기·사진 준비·초대를 시작하면 오늘의 색이 정해져요. 내 착장을 게시하면 같은 색의 사진이 열리고, 다른 색과 지난 전시는 먼저 볼 수 있어요.</p>');
    $('color-dialog').showModal();
  }
  function showDemoSettings() {
    $('demo-twin-tools').innerHTML = state.twin.status === 'invited' ? '<div class="demo-step"><h3>친구 역할 시연</h3><button data-action="accept-twin">친구 참여 시연 ↗</button></div>' : state.twin.status === 'paired' && !state.twin.friendPosted ? '<div class="demo-step"><h3>친구 역할 시연</h3><button data-action="friend-post">친구 게시 시연 ↗</button></div>' : '';
    $('demo-dialog').showModal();
  }
  function restoreKeyboardFocus(selector) {
    if (!keyboardNavigation) return;
    const main = document.querySelector(`[data-screen="${currentScreen}"]`);
    const target = main.querySelector(selector) || main;
    if (target === main) main.tabIndex = -1;
    target.focus({preventScroll:true});
  }
  document.addEventListener('click', async event => {
    const button = event.target.closest('button');
    if (!button || button.disabled) return;
    try {
      if (button.dataset.nav) { navigate(button.dataset.nav); return; }
      if (button.hasAttribute('data-close')) { button.closest('dialog').close(); return; }
      if (button.dataset.filter) { feedFilter = button.dataset.filter; renderFeed(); return; }
      if (button.dataset.profileView) { profileView = button.dataset.profileView; renderProfile(); if(keyboardNavigation) document.querySelector(`[data-profile-view="${profileView}"]`).focus({preventScroll:true}); return; }
      if (button.dataset.select) { state = Model.choose(state,button.dataset.select); renderAll(); if(keyboardNavigation) document.querySelector(`[data-select="${state.selected}"]`).focus({preventScroll:true}); return; }
      if (button.dataset.like) { const id=button.dataset.like; liked.has(id) ? liked.delete(id) : liked.add(id); button.setAttribute('aria-pressed',String(liked.has(id))); button.classList.toggle('liked',liked.has(id)); return; }
      if (button.dataset.color) { const id=button.dataset.color; $('color-preview').innerHTML=paint(id,true); $('color-title').textContent=palettes[id].name; $('color-dialog').showModal(); return; }
      if (button.dataset.share) { const url=new URL(location.href); url.searchParams.set('feed',feedFilter); url.hash=`post-${button.dataset.share}`; $('share-link').value=url.href; $('share-dialog').showModal(); return; }
      if (button.dataset.restoreColor) { restorePalette=button.dataset.restoreColor; document.querySelectorAll('[data-restore-color]').forEach(el=>el.setAttribute('aria-pressed',String(el.dataset.restoreColor===restorePalette))); return; }
      switch (button.dataset.action) {
        case 'compose': openCompose(); break;
        case 'twin-compose': openCompose('twin'); break;
        case 'cancel-compose': navigate(composeReturn); break;
        case 'choose-photo': $('photo-input').click(); break;
        case 'use-sample': draft={src:asset(palettes[state.selected].photo),kind:'sample'}; draftReady=false; renderCompose(); restoreKeyboardFocus('[data-action="use-sample"]'); break;
        case 'publish':
          if (!draft || !draftReady) return;
          state=Model.publish(state,draft); feedFilter='same'; renderAll(); navigate(composeReturn); notify('데모에 게시했어요. 같은 팔레트가 열렸어요.'); break;
        case 'show-same': feedFilter='same'; renderFeed(); navigate('feed'); break;
        case 'open-twin': renderTwin(); navigate('twin'); break;
        case 'palette-info': showPaletteInfo(); break;
        case 'rare-info': showPaletteInfo(true); break;
        case 'invite': state=Model.invite(Model.confirm(state)); renderToday(); renderTwin(); restoreKeyboardFocus('[data-action="copy-twin"]'); break;
        case 'accept-twin': state=Model.acceptTwin(state); $('demo-dialog').close(); renderAll(); restoreKeyboardFocus('[data-action="demo-settings"]'); notify('같은 팔레트로 연결했어요.'); break;
        case 'friend-post': state=Model.simulateFriendPost(state,{src:asset(state.selected==='blue'?'blue-outfit.jpg':state.selected==='butter'?'yellow-street.jpg':state.selected==='rare'?'green-blouse.jpg':'green-skirt.jpg'),kind:'sample'}); $('demo-dialog').close(); renderAll(); restoreKeyboardFocus('[data-action="twin-compose"]'); notify(Model.twinVisible(state)?'두 사람의 전시가 열렸어요.':'친구 기록이 도착했어요.'); break;
        case 'restore-empty': { const day=['01','02','03','04','05'].map(d=>`${Model.MONTH}-${d}`).find(date=>!state.history.some(h=>h.date===date)); openRestore(day || null); break; }
        case 'restore-save': state=Model.restore(state,restoreDate,restorePalette); $('restore-dialog').close(); renderAll(); if(keyboardNavigation) document.querySelector('[data-action="restore-empty"]')?.focus({preventScroll:true}); notify('지나간 날의 색을 복구했어요.'); break;
        case 'demo-settings': showDemoSettings(); break;
        case 'copy-twin': await copy(inviteUrl()); break;
        case 'copy-share': await copy($('share-link').value); break;
      }
    } catch (error) { notify(error.message); }
  });
  $('photo-input').addEventListener('change', event => {
    const file=event.target.files[0]; if (!file) return;
    if (!file.type.startsWith('image/') || file.size>15*1024*1024) { notify('15MB 이하의 이미지 파일을 골라주세요.'); event.target.value=''; return; }
    if (localPhotoUrl && localPhotoUrl!==state.post?.photo.src) URL.revokeObjectURL(localPhotoUrl);
    localPhotoUrl=URL.createObjectURL(file); draft={src:localPhotoUrl,kind:'local'}; draftReady=false; renderCompose(); event.target.value='';
  });
  document.querySelectorAll('dialog').forEach(dialog=>dialog.addEventListener('click',event=>{if(event.target===dialog) dialog.close();}));
  renderAll();
  navigate(params.has('twin') ? 'twin' : params.has('feed') ? 'feed' : 'today');
  const target=document.getElementById(location.hash.slice(1));
  if (target) requestAnimationFrame(()=>target.scrollIntoView({block:'start'}));
})();
