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
  let currentScreen = 'today';
  let composeReturn = 'feed';
  let draft = null;
  let draftReady = false;
  let localPhotoUrl = null;
  let restoreDate = null;
  let restorePalette = state.selected;
  let timer;
  const liked = new Set();
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
    document.querySelectorAll('[role="tab"][data-nav]').forEach(el => el.setAttribute('aria-selected', String(el.dataset.nav === parent)));
    document.dispatchEvent(new CustomEvent('esel:navigate', {detail:{screen, reset:screen === 'feed' && previous === 'feed'}}));
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
      $('post-list').innerHTML = `<section class="lock-panel" aria-label="오늘의 같은 팔레트 잠금">${paint(state.selected,true)}<span class="fine-print">같은 팔레트 ${p.count}명 · 데모</span><h2>당신의 해석을 먼저.</h2><p>오늘의 착장을 남기면<br>같은 팔레트의 전시가 열려요.</p><button class="primary" data-action="compose">내 착장 남기기</button></section>`;
      return;
    }
    let posts = feedFilter === 'past' ? allPosts().map(p => ({...p,date:'2026-09-05'})) : allPosts().filter(p => feedFilter === 'same' ? p.paletteId === state.selected : p.paletteId !== state.selected);
    posts = posts.filter(p => Model.canView(state,p));
    $('post-list').innerHTML = `<p class="feed-note">${feedFilter === 'past' ? '지난 날짜의 전시는 누구나 · 샘플' : feedFilter === 'same' ? `${p.name}의 다른 해석 · 게시 후 공개` : '다른 색의 오늘 · 샘플 전시'}</p>${posts.map(p => postMarkup(p)).join('')}`;
  }
  function renderToday() {
    const locked = !Model.canChoose(state);
    const options = state.rareEligible ? ['rare','sage','butter','blue'] : ['sage','butter','blue'];
    let content = state.rareEligible ? '<div class="rare-intro"><span class="rare-tag">오늘의 특별 팔레트</span><p>무작위 배정 3.2% · 데모 예시</p></div>' : '';
    content += `<div class="today-options" role="radiogroup" aria-label="오늘 사용할 팔레트">${options.map(id => `<button class="today-option" role="radio" data-select="${id}" aria-label="${palettes[id].name} 선택" aria-checked="${state.selected === id}" ${locked ? 'disabled' : ''}>${paint(id)}<span>${palettes[id].name}</span></button>`).join('')}</div>`;
    content += `<div class="today-summary"><span>${palettes[state.selected].name}</span><span class="muted">${state.post ? '게시 완료' : state.twin.status === 'paired' ? '트윈과 같은 팔레트' : '오늘의 선택'}</span></div>`;
    content += state.post ? '<button class="primary" data-action="show-same">같은 팔레트 감상하기</button>' : '<button class="primary" data-action="compose">이 팔레트로 남기기</button>';
    if (!state.post) content += '<button class="quiet-action" data-nav="feed">이 팔레트로 먼저 둘러보기 <span>↗</span></button>';
    content += `<button class="quiet-action" data-action="open-twin">팔레트 트윈 <span>↗</span></button><p class="fine-print">${locked ? '오늘의 팔레트가 확정됐어요.' : '기록하거나 둘러보기를 시작하면 오늘의 팔레트가 확정돼요.'}</p><button class="quiet-action" data-action="demo-settings"><span class="fine-print">배정 시연 설정</span><span>↗</span></button>`;
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
    $('profile-content').innerHTML = `<div class="profile-head"><img class="avatar" src="${asset('green-skirt.jpg')}" alt="내 프로필 · 샘플"><div><p>나의 색</p><small>9월 6일 기준 · 기록은 데모</small></div></div>${state.rareEligible ? `<div class="profile-rare">${paint('rare')}<span class="rare-tag">오늘 받은 특별 팔레트</span></div>` : ''}<div class="section-heading"><h2>9월의 색</h2><span>${postCount}번의 게시</span></div><div class="weekdays" aria-hidden="true">${['일','월','화','수','목','금','토'].map(d=>`<span>${d}</span>`).join('')}</div><div class="calendar" aria-label="2026년 9월 색상 기록"><span></span><span></span>${calendar}</div><div class="restore-row"><span>빈칸 복구권 ${state.restoreCredits}장 / 월 2장</span><button data-action="restore-empty">빈칸 복구 ↗</button></div><p class="calendar-legend">점선은 복구한 기록 · 하루 쉬어도 이전 색은 남아요.</p><div class="profile-links"><button class="quiet-action" data-action="open-twin">팔레트 트윈 <small>${Model.twinVisible(state) ? '함께 완성' : state.twin.status === 'none' ? '같은 색, 다른 해석' : '함께 기록 중'}</small><span>↗</span></button><button class="quiet-action" data-action="demo-settings">시연 설정 <span>↗</span></button></div>${state.post ? `<section class="profile-post"><h2>오늘 남긴 색</h2>${postMarkup({id:'me',author:'나',paletteId:state.post.paletteId,date:state.post.date,photo:state.post.photo,avatar:state.post.photo.src},true)}</section>` : ''}`;
  }
  function renderCompose() {
    $('compose-content').innerHTML = `<div class="compose-label">${paint(state.selected)}<span>${palettes[state.selected].name}</span></div>${draft ? `<img id="draft-photo" class="compose-photo" src="${esc(draft.src)}" alt="게시할 착장 미리보기">` : '<div class="photo-placeholder">오늘의 착장을 한 장 남겨요.</div>'}<div class="upload-actions"><button data-action="choose-photo">기기 사진 고르기</button><button data-action="use-sample">샘플 사진 사용</button></div><button class="primary" data-action="publish" ${draftReady && draft ? '' : 'disabled'}>이 사진을 데모에 게시</button>`;
    const image = $('draft-photo');
    if (image) {
      const ready = () => { draftReady = true; $('compose-content').querySelector('[data-action="publish"]').disabled = false; };
      image.addEventListener('load', ready);
      image.addEventListener('error', () => { draft = null; draftReady = false; renderCompose(); notify('이 사진을 열지 못했어요. 다른 사진을 골라주세요.'); });
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
    const person = (name,complete,photo) => `<div><div class="twin-frame">${visible ? `<img src="${esc(photo.src)}" alt="${name}의 ${palettes[id].name} 착장">` : '<span class="waiting-mark" aria-hidden="true">·</span>'}</div><div class="twin-person"><span>${name}</span><small>${complete ? '게시 완료' : '기다리는 중'}</small></div></div>`;
    let content = `<div class="twin-palette">${paint(id)}<span>${palettes[id].name}</span></div><p class="twin-caption">${visible ? '같은 색, 다른 해석.' : '둘 다 남기면, 나란히 열려요.'}</p><div class="twin-grid" aria-label="${visible ? '완성된 트윈 착장' : '두 사람 게시 전 비공개'}">${person('나',!!state.post,state.post?.photo)}${person('친구 · 샘플',state.twin.friendPosted,state.twin.friendPhoto)}</div>`;
    if (state.twin.status === 'none') content += '<button class="primary" data-action="invite">친구 초대 링크 만들기</button><p class="fine-print">이 컴퓨터 안에서만 열리는 로컬 데모예요.<br>실제 초대 메시지는 보내지 않아요.</p>';
    if (state.twin.status === 'invited') content += `<label class="fine-print" for="twin-link">같은 팔레트로 연결되는 데모 링크</label><input id="twin-link" class="twin-link-input" value="${esc(inviteUrl())}" readonly><button class="quiet-action" data-action="copy-twin">초대 링크 복사 <span>↗</span></button><div class="demo-step"><p>친구 역할 시연 · 실제 계정 연결 아님</p><button data-action="accept-twin">친구 참여 시연</button></div>`;
    if (paired && !state.post) content += '<button class="primary" data-action="twin-compose">내 착장 남기기</button>';
    if (paired && !state.twin.friendPosted) content += '<div class="demo-step"><p>친구 역할 시연 · 친구가 먼저 게시해도 사진은 잠겨 있어요.</p><button data-action="friend-post">친구 게시 시연</button></div>';
    if (paired && state.post && !state.twin.friendPosted) content += '<p class="fine-print">내 기록은 도착했어요. 친구가 남기면 함께 열려요.</p>';
    if (visible) content += '<p class="fine-print">두 사람 모두 게시해 트윈 전시가 열렸어요.<br>친구 사진은 샘플이에요.</p>';
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
    $('restore-content').innerHTML = `<p class="restore-date">9월 ${Number(date.slice(-2))}일</p><p class="fine-print">지나간 날의 색을 보완해요.<br>실제 게시와 구분되며 오늘의 잠금은 풀리지 않아요.</p><div class="restore-palette-options" role="group" aria-label="복구할 색">${['sage','butter','blue',...(state.rareEligible ? ['rare'] : [])].map(id=>`<button data-restore-color="${id}" aria-pressed="${id === restorePalette}">${palettes[id].name}</button>`).join('')}</div><button class="primary" data-action="restore-save">복구권 1장 사용</button>`;
    $('restore-dialog').showModal();
  }
  async function copy(text) {
    try { await navigator.clipboard.writeText(text); notify('데모 링크를 복사했어요.'); }
    catch { notify('자동 복사가 안 돼요. 링크를 직접 선택해 복사해주세요.'); }
  }
  document.addEventListener('click', async event => {
    const button = event.target.closest('button');
    if (!button || button.disabled) return;
    try {
      if (button.dataset.nav) { navigate(button.dataset.nav); return; }
      if (button.hasAttribute('data-close')) { button.closest('dialog').close(); return; }
      if (button.dataset.filter) { feedFilter = button.dataset.filter; renderFeed(); return; }
      if (button.dataset.select) { state = Model.choose(state,button.dataset.select); renderAll(); return; }
      if (button.dataset.like) { const id=button.dataset.like; liked.has(id) ? liked.delete(id) : liked.add(id); button.setAttribute('aria-pressed',String(liked.has(id))); button.classList.toggle('liked',liked.has(id)); return; }
      if (button.dataset.color) { const id=button.dataset.color; $('color-preview').innerHTML=paint(id,true); $('color-title').textContent=palettes[id].name; $('color-dialog').showModal(); return; }
      if (button.dataset.share) { const url=new URL(location.href); url.searchParams.set('feed',feedFilter); url.hash=`post-${button.dataset.share}`; $('share-link').value=url.href; $('share-dialog').showModal(); return; }
      if (button.dataset.restoreColor) { restorePalette=button.dataset.restoreColor; document.querySelectorAll('[data-restore-color]').forEach(el=>el.setAttribute('aria-pressed',String(el.dataset.restoreColor===restorePalette))); return; }
      if (button.dataset.day) {
        const entry=state.history.find(h=>h.date===button.dataset.day);
        if (entry) { $('color-preview').innerHTML=`${paint(entry.paletteId,true)}<p class="record-detail">${entry.kind==='restored' ? '복구한 색 · 실제 게시와 별도 기록' : '게시하며 남긴 색'}</p>`; $('color-title').textContent=`9월 ${Number(entry.date.slice(-2))}일 · ${palettes[entry.paletteId].name}`; $('color-dialog').showModal(); }
        else if (button.dataset.day===Model.TODAY) openCompose();
        else openRestore(button.dataset.day);
        return;
      }
      switch (button.dataset.action) {
        case 'compose': openCompose(); break;
        case 'twin-compose': openCompose('twin'); break;
        case 'cancel-compose': navigate(composeReturn); break;
        case 'choose-photo': $('photo-input').click(); break;
        case 'use-sample': draft={src:asset(palettes[state.selected].photo),kind:'sample'}; draftReady=false; renderCompose(); break;
        case 'publish':
          if (!draft || !draftReady) return;
          state=Model.publish(state,draft); feedFilter='same'; renderAll(); navigate(composeReturn); notify('데모에 게시했어요. 같은 팔레트가 열렸어요.'); break;
        case 'show-same': feedFilter='same'; renderFeed(); navigate('feed'); break;
        case 'open-twin': renderTwin(); navigate('twin'); break;
        case 'invite': state=Model.invite(Model.confirm(state)); renderToday(); renderTwin(); break;
        case 'accept-twin': state=Model.acceptTwin(state); renderAll(); notify('친구와 같은 팔레트로 연결된 시연이에요.'); break;
        case 'friend-post': state=Model.simulateFriendPost(state,{src:asset(state.selected==='blue'?'blue-outfit.jpg':state.selected==='butter'?'yellow-street.jpg':state.selected==='rare'?'green-blouse.jpg':'green-skirt.jpg'),kind:'sample'}); renderAll(); notify(Model.twinVisible(state)?'두 사람의 전시가 열렸어요.':'친구 기록 도착. 내가 게시하면 함께 열려요.'); break;
        case 'restore-empty': { const day=['01','02','03','04','05'].map(d=>`${Model.MONTH}-${d}`).find(date=>!state.history.some(h=>h.date===date)); if (day) openRestore(day); else notify('지난 날짜에 남은 빈칸이 없어요.'); break; }
        case 'restore-save': state=Model.restore(state,restoreDate,restorePalette); $('restore-dialog').close(); renderAll(); notify('지나간 날의 색을 복구했어요.'); break;
        case 'demo-settings': $('demo-dialog').showModal(); break;
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
