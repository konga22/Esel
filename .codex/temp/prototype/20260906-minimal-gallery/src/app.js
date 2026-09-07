(() => {
  'use strict';
  const Model = EselSocialState;
  const params = new URLSearchParams(location.search);
  const palettes = {
    sage: { name: '세이지', hex: '#A8B5A0', paints: ['sage'], photo: 'green-blouse.jpg', count: 428 },
    butter: { name: '버터', hex: '#E5C982', paints: ['butter'], photo: 'yellow-street.jpg', count: 316 },
    blue: { name: '파우더 블루', hex: '#9BB8CF', paints: ['powder-blue'], photo: 'blue-outfit.jpg', count: 224 },
    coral: { name:'코럴',hex:'#D98D83',paints:['butter'],filter:'hue-rotate(320deg) saturate(.7)',photo:'yellow-street.jpg',count:0 },
    violet: { name:'라일락',hex:'#B1A1C9',paints:['powder-blue'],filter:'hue-rotate(50deg)',photo:'blue-outfit.jpg',count:0 },
    rare: { name: '세이지 × 버터', hex: 'linear-gradient(135deg,#A8B5A0 50%,#E5C982 50%)', paints: ['sage','butter'], photo: 'green-skirt.jpg', count: 32 }
  };
  const scenario = params.get('scenario');
  const rare = scenario === 'rare' || (scenario === 'random' && Model.isRareDraw(Math.random()));
  let state = Model.create({ rare });
  // An incoming local invitation carries no palette or automatic acceptance.
  if (params.has('twin')) state = Model.invite(state);
  let twinChoice = null;
  let sharing = EselTwinSharing.create();
  let publicationDraft = null;
  let faceEditor = null;
  let feedFilter = params.get('feed') === 'same' ? 'same' : 'all';
  let feedSeen = [];
  let feedElapsed = 0;
  let feedStarted = null;
  const feedTime = () => feedElapsed + (feedStarted === null ? 0 : performance.now() - feedStarted);
  function trackFeedTime() {
    if (feedStarted !== null) feedElapsed += performance.now() - feedStarted;
    feedStarted = currentScreen === 'feed' && !document.hidden ? performance.now() : null;
  }
  document.addEventListener('visibilitychange', trackFeedTime);
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
  const twinMembers = {own:{id:'you',name:'유나',avatar:asset('green-blouse.jpg')},friend:{id:'twin_friend',name:'민서',avatar:asset('green-skirt.jpg')}};
  function publicTwinPosts(){
    return EselTwinSharing.entries(sharing,state.twin).map(entry=>({
      ...entry, twinPublic:true, date:Model.TODAY, minute:1440, likes:0,
      paletteId:entry.actors[0]==='friend'?state.twin.friendPaletteId:state.twin.paletteId, author:entry.actors.map(actor=>twinMembers[actor].name).join(' · ')
    }));
  }
  function twinPublicMarkup(post){
    const id=EselFeedOrder.key(post);
    const pictures=post.actors.map(actor=>{
      const other=actor==='own'?'friend':'own';
      return `<div class="twin-public-piece"><img class="post-photo" src="${esc(state.twin[actor+'Post'].photo.src)}" alt="${twinMembers[actor].name}의 ${palettes[state.twin[actor+'Post'].paletteId].name} 트윈 착장"><div class="partner-tag">${(post.actors.length===2?[other]:['own','friend']).map(tagActor=>`<button data-member="${tagActor}" aria-label="@${twinMembers[tagActor].id} 프로필 보기">@${twinMembers[tagActor].id}</button>`).join('')}</div></div>`;
    }).join('');
    return `<article class="post twin-public" id="post-${id}" data-public-kind="${post.actors.length===2?'joint':'solo'}"><header class="post-header"><img class="avatar" src="${twinMembers[post.actors[0]].avatar}" alt=""><span class="username">${esc(twinMembers.own.name)}와 ${esc(twinMembers.friend.name)}의 트윈</span><span class="paint-button">${[...new Set(post.actors.map(actor=>state.twin[actor+'Post'].paletteId))].map(id=>paint(id)).join('')}</span></header><div class="twin-public-photos ${post.actors.length===2?'paired-photos':''}">${pictures}</div><div class="post-actions"><button class="icon-button${liked.has(id)?' liked':''}" data-like="${id}" aria-label="트윈 착장 좋아요" aria-pressed="${liked.has(id)}">${heart}</button><button class="icon-button" data-share="${id}" aria-label="트윈 착장 공유">${share}</button></div></article>`;
  }
  const people = [
    { id:'sora', author:'sora', paletteId:'sage', photo:{src:asset('green-blouse.jpg')}, avatar:asset('green-skirt.jpg'), ratio:.8 },
    { id:'elle', author:'elle', paletteId:'butter', photo:{src:asset('yellow-street.jpg')}, avatar:asset('yellow-street.jpg'), ratio:.76 },
    { id:'haru', author:'haru', paletteId:'blue', photo:{src:asset('blue-outfit.jpg')}, avatar:asset('blue-outfit.jpg'), ratio:.87 },
    { id:'mina', author:'mina', paletteId:'rare', photo:{src:asset('green-skirt.jpg')}, avatar:asset('green-skirt.jpg'), ratio:.8 }
  ];
  // Fixed illustrative dates and like counts, not live user engagement.
  const allPosts = () => [...(state.post?[{id:'my-daily',author:twinMembers.own.name,avatar:twinMembers.own.avatar,date:Model.TODAY,minute:1441,paletteId:state.post.paletteId,photo:state.post.photo}]:[]),...['06','05','04','03'].flatMap((day, d) => people.map((p, i) => ({
    ...p, date:`2026-09-${day}`, minute:720-i*45,
    likes:[24,81,46,120][i] + d * 100
  })))];
  function paint(id, large = false) {
    return `<span class="paint-pair${large ? ' large' : ''}" style="filter:${palettes[id].filter||'none'}">${palettes[id].paints.map(p => `<img src="${asset(`paint-${p}.png`)}" alt="">`).join('')}</span>`;
  }
  function notify(message) {
    clearTimeout(timer); $('notice').textContent = message; $('notice').hidden = false;
    timer = setTimeout(() => { $('notice').hidden = true; }, 3200);
  }
  function navigate(screen) {
    const previous = currentScreen;
    if (screen === 'feed' && !state.confirmed) { state = Model.confirm(state); renderToday(); }
    currentScreen = screen;
    document.querySelector('.phone').dataset.activeScreen=screen;
    document.querySelector('.wordmark').hidden=screen!=='feed';
    trackFeedTime();
    document.querySelectorAll('[data-screen]').forEach(el => { el.hidden = el.dataset.screen !== screen; });
    const parent = screen === 'twin' || (screen === 'compose' && composeReturn === 'twin') ? 'profile' : screen === 'compose' ? 'today' : screen;
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
    return `<article class="post" id="post-${id}" data-palette="${post.paletteId}" aria-label="${esc(post.author)}의 ${p.name} 착장"><header class="post-header"><img class="avatar" src="${esc(post.avatar)}" alt="${esc(post.author)} 프로필 · 샘플"><span class="username">${esc(post.author)}</span><button class="paint-button" data-color="${post.paletteId}" aria-label="${esc(post.author)}의 색: ${p.name}">${paint(post.paletteId)}</button>${post.date !== Model.TODAY ? `<span class="post-date">9. ${Number(post.date.slice(-2))}.</span>` : ''}</header><img class="post-photo" style="--ratio:${post.ratio || .8}" src="${esc(post.photo.src)}" alt="${p.name} 착장 ${own ? '내 사진' : '샘플'}" loading="lazy"><div class="post-actions"><button class="icon-button${liked.has(id) ? ' liked' : ''}" data-like="${id}" aria-label="${esc(post.author)} 좋아요" aria-pressed="${liked.has(id)}">${heart}</button>${own ? '' : `<button class="icon-button" data-share="${id}" aria-label="${esc(post.author)} 공유">${share}</button>`}</div></article>`;
  }
  function renderFeed() {
    feedSeen = [];
    document.querySelectorAll('[data-filter]').forEach(el => el.setAttribute('aria-pressed', String(el.dataset.filter === feedFilter)));
    const p = palettes[state.selected];
    if (feedFilter === 'same' && !Model.canView(state, {date:Model.TODAY,paletteId:state.selected})) {
      $('post-list').innerHTML = `<section class="lock-panel" aria-label="오늘의 같은 팔레트 잠금">${paint(state.selected,true)}<h2>내 색을 먼저 남겨요.</h2><p>게시하면 같은 색의 착장이 열려요.</p><button class="primary" data-action="compose">착장 남기기</button><span class="count">같은 팔레트 ${p.count}명 · 예시</span></section>`;
      $('feed-more').hidden = true;
      return;
    }
    $('post-list').innerHTML = '';
    appendFeed();
  }
  function appendFeed() {
    const posts = [...publicTwinPosts(),...allPosts()].filter(p => (p.twinPublic || Model.canView(state,p)) && (feedFilter !== 'same' || (p.date === Model.TODAY && p.paletteId === state.selected)));
    const page = EselFeedOrder.next(posts, feedSeen, feedFilter === 'all' ? feedTime() : 0);
    $('post-list').insertAdjacentHTML('beforeend', page.map(p => p.twinPublic?twinPublicMarkup(p):postMarkup(p)).join(''));
    feedSeen.push(...page.map(EselFeedOrder.key));
    $('feed-more').hidden = feedSeen.length >= posts.length;
  }
  document.querySelector('[data-screen="feed"]').addEventListener('scroll', event => {
    const feed = event.currentTarget;
    if (currentScreen === 'feed' && !$('feed-more').hidden && feed.scrollHeight - feed.scrollTop - feed.clientHeight < 180) appendFeed();
  }, {passive:true});
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
    const publicCollection = publicTwinPosts().filter(post=>post.actors.includes('own')).map(post=>`<figure class="collection-piece"><img src="${esc(state.twin.ownPost.photo.src)}" alt="피드에 공개한 내 트윈 착장"><figcaption><span>트윈 · 9. 6.</span><span class="record-color" style="--record-color:${palettes[post.paletteId].hex}"></span></figcaption></figure>`).join('');
    const collection = publicCollection + records.map(h => {
      const src = h.date === Model.TODAY && state.post ? state.post.photo.src : asset(palettes[h.paletteId].photo);
      return `<figure class="collection-piece"><img src="${esc(src)}" alt="9월 ${Number(h.date.slice(-2))}일 ${palettes[h.paletteId].name} 착장 ${h.date === Model.TODAY ? '내 사진' : '샘플'}" loading="lazy"><figcaption><span>9. ${Number(h.date.slice(-2))}.</span><span class="record-color" style="--record-color:${palettes[h.paletteId].hex}" aria-label="${palettes[h.paletteId].name}"></span></figcaption></figure>`;
    }).join('');
    const content = profileView === 'photos' ? `<div class="collection-grid" aria-label="나의 착장 컬렉션">${collection}</div>` : `<div class="month-heading"><h2>2026. 9.</h2><span>${postCount}일의 착장</span></div><div class="weekdays" aria-hidden="true">${['일','월','화','수','목','금','토'].map(d=>`<span>${d}</span>`).join('')}</div><div class="calendar" aria-label="2026년 9월 색상 기록"><span></span><span></span>${calendar}</div><div class="record-footer"><span>쌓인 색은 사라지지 않아요.</span><button data-action="restore-empty">기록 관리 ↗</button></div>${state.history.some(h=>h.kind==='restored')?'<p class="calendar-legend">점선은 복구한 색이에요.</p>':''}`;
    $('profile-content').innerHTML = `<div class="profile-head"><img class="avatar" src="${asset('green-skirt.jpg')}" alt="내 프로필 · 샘플"><h1>나의 전시</h1>${state.rareEligible ? `<button class="paint-button" data-action="rare-info" aria-label="받은 특별 팔레트 보기">${paint('rare')}</button>` : ''}<button class="twin-entry" data-action="open-twin" aria-label="팔레트 트윈">트윈 ↗</button></div><div class="profile-switch" role="group" aria-label="내 전시 보기"><button data-profile-view="photos" aria-pressed="${profileView==='photos'}">착장</button><button data-profile-view="colors" aria-pressed="${profileView==='colors'}">색 기록</button></div>${content}`;
  }
  function renderCompose() {
    const id = composeReturn === 'twin' ? state.twin.paletteId : state.selected;
    document.querySelector('[data-screen="compose"] h1').textContent = composeReturn === 'twin' ? '트윈 착장 남기기' : '착장 남기기';
    $('compose-content').innerHTML = `<div class="compose-label">${paint(id)}<span>${palettes[id].name}${composeReturn === 'twin' ? ' · 내 트윈 색' : ''}</span></div>${draft ? `<img id="draft-photo" class="compose-photo" src="${esc(draft.src)}" alt="게시할 착장 미리보기">` : '<div class="photo-placeholder">오늘의 착장을 한 장.</div>'}<div class="upload-actions"><button data-action="choose-photo">사진 고르기</button><button data-action="use-sample">샘플로 체험</button></div><button class="primary" data-action="publish" ${draftReady && draft ? '' : 'disabled'}>게시하기</button><p class="compose-caption">기기 안에서만 처리하는 데모예요.</p>`;
    const image = $('draft-photo');
    faceEditor=null;
    if(image){
      const host=document.createElement('div');host.className='face-editor';image.before(host);host.append(image);
      faceEditor=EselFacePaint.mount(host,draft,{...palettes[id],maskColors:id==='rare'?['#A8B5A0','#E5C982']:undefined});
    }
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
    url.searchParams.set('twin','invite');
    return url.href;
  }
  function renderTwin() {
    const visible = Model.twinVisible(state);
    const twin = state.twin;
    let content = '';
    if (twin.status === 'none' || twin.status === 'invited') {
      content = '<div class="twin-intro"><span class="twin-pair-mark" aria-hidden="true">○ ○</span><p>하나의 추천, 두 가지 해석.</p><span>친구가 함께하면 각자의 추천색을 받아요.</span></div>';
      if (twin.status === 'none') content += '<button class="primary" data-action="invite">친구 초대하기 <span aria-hidden="true">↗</span></button>';
      else content += `<label class="fine-print" for="twin-link">친구의 참여를 기다리고 있어요.</label><input id="twin-link" class="twin-link-input" value="${esc(inviteUrl())}" readonly><button class="quiet-action" data-action="copy-twin">초대 링크 복사 <span>↗</span></button>`;
    } else if (twin.status === 'paired') {
      content = `<p class="twin-caption">추천 하나는 함께, 선택은 각자.</p><div class="today-options twin-options" role="group" aria-label="둘의 공통 포인트색">${twin.recommendations.own.map(id=>`<button class="today-option" data-twin-color="${id}" aria-pressed="${twinChoice===id}" aria-label="내 추천색 ${palettes[id].name} 선택">${paint(id)}<span class="option-name">${palettes[id].name}${id===twin.sharedId?' · 공통 추천':''}</span></button>`).join('')}</div><button class="primary" data-action="propose-twin" ${twinChoice ? '' : 'disabled'}>내 색 선택하기</button><p class="twin-caption">개인의 오늘 색과는 별개예요.</p>`;
    } else if (twin.status === 'proposed') {
      content = `<div class="twin-color-review">${paint(twin.proposalId,true)}<h2>${palettes[twin.proposalId].name}</h2><p>내 색을 골랐어요. 친구는 다른 색을 골라도 돼요.</p></div>`;
    } else if (twin.status === 'ready') {
      const id = twin.paletteId;
      const person = (name,post) => `<div><div class="twin-frame">${visible ? `<img src="${esc(post.photo.src)}" alt="${name}의 ${palettes[id].name} 착장">` : '<span class="waiting-mark" aria-hidden="true"></span>'}</div><div class="twin-person"><span>${name}</span><small>${post ? '게시 완료' : '기다리는 중'}</small></div></div>`;
      content = `<div class="twin-palette">${paint(id)}<span>${palettes[id].name} / ${palettes[twin.friendPaletteId].name}</span></div><p class="twin-caption">${visible ? '각자의 색, 나란히.' : '선택한 색으로 각자의 착장을 남겨요.'}</p><div class="twin-grid" aria-label="${visible ? '완성된 트윈 착장' : '두 사람 게시 전 비공개'}">${person(twinMembers.own.name,twin.ownPost)}${person(twinMembers.friend.name,twin.friendPost)}</div>`;
      if (!twin.ownPost) content += '<button class="primary" data-action="twin-compose">트윈 착장 남기기</button>';
      if (twin.ownPost && !twin.friendPost) content += '<p class="twin-finish">친구가 남기면 함께 열려요.</p>';
      if (twin.ownPost) {
        const joint = publicTwinPosts().some(post=>post.id==='twin-joint');
        const status = joint ? '함께 업로드 완료' : sharing.own==='joint' ? '친구의 공개 동의를 기다리고 있어요.' : sharing.friend==='joint' ? `${twinMembers.friend.name}님이 함께 공개에 동의했어요.` : sharing.own==='solo' ? '내 사진만 업로드 완료' : '';
        if(status) content += `<div class="twin-publication-status" role="status"><p>${esc(status)}</p>${joint?'<button data-action="view-twin-feed">피드에서 보기 ↗</button>':''}</div>`;
      }
      if (twin.ownPost) content += `<button class="quiet-action" data-action="publication">${sharing.own==='private'?'피드에 공개':'공개 설정'} <span>↗</span></button>`;
    }
    if (twin.status === 'invited' || twin.status === 'proposed' || twin.status === 'ready') content += '<button class="quiet-action" data-action="demo-settings">친구 역할 시연 <span>↗</span></button>';
    $('twin-content').innerHTML = content;
  }
  function renderAll() { renderFeed(); renderToday(); renderProfile(); renderTwin(); }
  function openCompose(from = currentScreen) {
    if (from === 'twin') {
      if (state.twin.status !== 'ready' || state.twin.ownPost) { notify('각자의 색 선택 후 한 번 게시할 수 있어요.'); return; }
    } else {
      if (state.post) { notify('오늘은 이미 게시했어요.'); return; }
      state=Model.confirm(state); renderToday();
    }
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
    $('color-preview').innerHTML = paint(rareOnly ? 'rare' : state.selected, true) + (rareOnly ? '<p class="fine-print">가끔 만나는 두 색의 조합이에요. 받은 특별 팔레트는 내 전시에 남아요.</p><p class="fine-print">결제나 가입 기간과 관계없이 무작위로 배정합니다. 이 데모의 3.2%는 예시값이에요.</p>' : '<p class="fine-print">세 가지 중 오늘 입고 싶은 색을 골라요. 작은 포인트 하나여도 괜찮아요.</p><p class="fine-print">둘러보기·개인 사진 준비를 시작하면 오늘의 색이 정해져요. 내 착장을 게시하면 같은 색의 사진이 열리고, 다른 색과 지난 전시는 먼저 볼 수 있어요.</p>');
    $('color-dialog').showModal();
  }
  function showDemoSettings() {
    let actions = '';
    if (state.twin.status === 'invited') actions = '<button data-action="accept-twin">친구 참여 시연 ↗</button>';
    if (state.twin.status === 'proposed') actions = `<p class="fine-print">친구의 추천색 · 하나를 선택하세요.</p>${state.twin.recommendations.friend.map(id=>`<button data-friend-color="${id}">${palettes[id].name}${id===state.twin.sharedId?' · 공통 추천':''}</button>`).join('')}<button data-action="decline-twin">내 색 다시 선택</button>`;
    if (state.twin.status === 'ready' && !state.twin.friendPost) actions = '<button data-action="friend-post">친구 게시 시연 ↗</button>';
    if (state.twin.friendPost) actions += `<p class="fine-print">친구의 공개 선택</p>${['private','solo','joint'].map((mode,i)=>`<button data-friend-public="${mode}" aria-pressed="${sharing.friend===mode}" ${mode==='joint'&&!Model.twinVisible(state)?'disabled':''}>${['비공개 / 함께 공개 거절','친구 사진만 공개','함께 공개 동의'][i]} 시연</button>`).join('')}`;
    $('demo-twin-tools').innerHTML = actions ? `<div class="demo-step"><h3>친구 역할 시연</h3>${actions}</div>` : '';
    $('demo-dialog').showModal();
  }
  function renderPublication(){
    const status = sharing.own==='private'?'아직 피드에 공개하지 않았어요.':sharing.own==='solo'?'내 사진만 피드에 공개 중이에요.':sharing.friend==='joint'?'두 사진을 하나로 공개 중이에요.':'친구의 함께 공개 동의를 기다려요.';
    $('publication-content').innerHTML=`<p class="fine-print">${status}</p><div class="publication-options">${['solo','joint','private'].map((mode,i)=>`<button data-public="${mode}" aria-pressed="${publicationDraft.own===mode}" ${mode==='joint'&&!Model.twinVisible(state)?'disabled':''}><span>${['내 사진만 공개','함께 공개','공개하지 않기'][i]}</span><small>${['상대 사진 없이 내 착장 한 장','둘의 사진을 하나로 · 상대 동의 필요','트윈 안에서만 감상'][i]}</small></button>`).join('')}</div><p class="fine-print">업로드하면 두 참여자의 아이디가 사진 아래에 표시돼요.</p><button class="primary" data-action="publication-upload">${publicationDraft.own==='private'?'설정 저장':'업로드'}</button>`;
  }
  function refreshPublication(){
    renderFeed();renderTwin();renderProfile();
  }
  function openMember(actor){
    const member=twinMembers[actor];
    if(!member)return;
    $('member-title').textContent='@'+member.id;
    const publicPhotos=publicTwinPosts().filter(post=>post.actors.includes(actor));
    $('member-content').innerHTML=`<p class="fine-print">${member.name}의 공개 트윈 · 로컬 프로필 데모</p>${publicPhotos.length?`<img class="post-photo" src="${esc(state.twin[actor+'Post'].photo.src)}" alt="공개한 트윈 착장">`:'<p class="fine-print">아직 공개한 트윈 사진이 없어요.</p>'}`;
    $('member-dialog').showModal();
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
      if(button.dataset.member){openMember(button.dataset.member);return;}
      if(button.dataset.public){publicationDraft={...publicationDraft,own:button.dataset.public};renderPublication();$('publication-content').querySelector(`[data-public="${button.dataset.public}"]`).focus({preventScroll:true});return;}
      if(button.dataset.friendColor){state=Model.approveTwinColor(state,button.dataset.friendColor);$('demo-dialog').close();renderTwin();restoreKeyboardFocus('[data-action="twin-compose"]');return;}
      if(button.dataset.friendPublic){sharing=EselTwinSharing.choose(sharing,state.twin,'friend',button.dataset.friendPublic);$('demo-dialog').close();refreshPublication();restoreKeyboardFocus('[data-action="view-twin-feed"]');notify(button.dataset.friendPublic==='joint'?(sharing.own==='joint'?`${twinMembers.friend.name}님이 동의했어요. 함께 업로드됐어요.`:`${twinMembers.friend.name}님이 함께 공개에 동의했어요.`):'친구의 공개 설정이 변경됐어요.');return;}
      if (button.dataset.nav) { navigate(button.dataset.nav); return; }
      if (button.hasAttribute('data-close')) { button.closest('dialog').close(); return; }
      if (button.dataset.filter) { feedFilter = button.dataset.filter; renderFeed(); document.querySelector('[data-screen="feed"]').scrollTop = 0; return; }
      if (button.dataset.profileView) { profileView = button.dataset.profileView; renderProfile(); if(keyboardNavigation) document.querySelector(`[data-profile-view="${profileView}"]`).focus({preventScroll:true}); return; }
      if (button.dataset.select) { state = Model.choose(state,button.dataset.select); renderAll(); if(keyboardNavigation) document.querySelector(`[data-select="${state.selected}"]`).focus({preventScroll:true}); return; }
      if (button.dataset.twinColor) { twinChoice=button.dataset.twinColor; renderTwin(); restoreKeyboardFocus(`[data-twin-color="${twinChoice}"]`); return; }
      if (button.dataset.like) { const id=button.dataset.like; liked.has(id) ? liked.delete(id) : liked.add(id); button.setAttribute('aria-pressed',String(liked.has(id))); button.classList.toggle('liked',liked.has(id)); return; }
      if (button.dataset.color) { const id=button.dataset.color; $('color-preview').innerHTML=paint(id,true); $('color-title').textContent=palettes[id].name; $('color-dialog').showModal(); return; }
      if (button.dataset.share) { const url=new URL(location.href); url.searchParams.set('feed',feedFilter); url.hash=`post-${button.dataset.share}`; $('share-link').value=url.href; $('share-dialog').showModal(); return; }
      if (button.dataset.restoreColor) { restorePalette=button.dataset.restoreColor; document.querySelectorAll('[data-restore-color]').forEach(el=>el.setAttribute('aria-pressed',String(el.dataset.restoreColor===restorePalette))); return; }
      switch (button.dataset.action) {
        case 'view-twin-feed': feedFilter='all';renderFeed();navigate('feed');document.getElementById(`post-twin-joint-${Model.TODAY}`)?.scrollIntoView({block:'start'});break;
        case 'publication': publicationDraft={...sharing};renderPublication();$('publication-dialog').showModal();break;
        case 'publication-upload': sharing=EselTwinSharing.choose(sharing,state.twin,'own',publicationDraft.own);sharing=EselTwinSharing.tag(sharing,'own',true);$('publication-dialog').close();refreshPublication();notify(sharing.own==='private'?'비공개로 변경했어요.':sharing.own==='joint'&&sharing.friend!=='joint'?'업로드했어요. 상대의 공개 동의를 기다려요.':'피드에 업로드했어요.');break;
        case 'more-posts': appendFeed(); break;
        case 'compose': openCompose(); break;
        case 'twin-compose': openCompose('twin'); break;
        case 'cancel-compose': navigate(composeReturn); break;
        case 'choose-photo': $('photo-input').click(); break;
        case 'use-sample': draft={src:asset(palettes[composeReturn==='twin' ? state.twin.paletteId : state.selected].photo),kind:'sample'}; draftReady=false; renderCompose(); restoreKeyboardFocus('[data-action="use-sample"]'); break;
        case 'publish':
          if (!draft || !draftReady) return;
          {const composed=faceEditor?faceEditor.export():draft;draft=composed;}
          if (composeReturn === 'twin') {
            state=Model.publishTwin(state,draft); renderTwin(); navigate('twin'); notify(Model.twinVisible(state) ? '두 사람의 트윈 전시가 열렸어요.' : '트윈에 남겼어요. 친구가 게시하면 함께 열려요.');
          } else {
            state=Model.publish(state,draft); feedFilter='same'; renderAll(); navigate(composeReturn); notify('데모에 게시했어요. 같은 팔레트가 열렸어요.');
          }
          break;
        case 'show-same': feedFilter='same'; renderFeed(); navigate('feed'); break;
        case 'open-twin': renderTwin(); navigate('twin'); break;
        case 'palette-info': showPaletteInfo(); break;
        case 'rare-info': showPaletteInfo(true); break;
        case 'invite': state=Model.invite(state); renderTwin(); restoreKeyboardFocus('[data-action="copy-twin"]'); break;
        case 'accept-twin': state=Model.acceptTwin(state); twinChoice=null; $('demo-dialog').close(); renderTwin(); restoreKeyboardFocus('[data-twin-color]'); notify('친구가 함께해요. 각자 추천색을 골라주세요.'); break;
        case 'propose-twin': state=Model.proposeTwinColor(state,twinChoice); renderTwin(); restoreKeyboardFocus('[data-action="demo-settings"]'); break;
        case 'approve-twin': state=Model.approveTwinColor(state); $('demo-dialog').close(); renderTwin(); restoreKeyboardFocus('[data-action="twin-compose"]'); notify('둘의 공통색이 정해졌어요.'); break;
        case 'decline-twin': state=Model.declineTwinColor(state); twinChoice=null; $('demo-dialog').close(); renderTwin(); restoreKeyboardFocus('[data-twin-color]'); break;
        case 'friend-post': state=Model.simulateFriendPost(state,{src:asset(state.twin.friendPaletteId==='sage'?'green-skirt.jpg':palettes[state.twin.friendPaletteId].photo),kind:'sample'}); $('demo-dialog').close(); renderTwin(); restoreKeyboardFocus('[data-action="twin-compose"]'); notify(Model.twinVisible(state)?'두 사람의 전시가 열렸어요.':'친구 기록이 도착했어요.'); break;
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
    if (localPhotoUrl && localPhotoUrl!==state.post?.photo.src && localPhotoUrl!==state.twin.ownPost?.photo.src) URL.revokeObjectURL(localPhotoUrl);
    localPhotoUrl=URL.createObjectURL(file); draft={src:localPhotoUrl,kind:'local'}; draftReady=false; renderCompose(); event.target.value='';
  });
  document.querySelectorAll('dialog').forEach(dialog=>dialog.addEventListener('click',event=>{if(event.target===dialog) dialog.close();}));
  $('publication-dialog').addEventListener('close',()=>restoreKeyboardFocus('[data-action="publication"]'));
  renderAll();
  navigate(params.has('twin') ? 'twin' : params.has('feed') ? 'feed' : 'today');
  // Existing shared links may point beyond the first page; still apply visibility.
  while (currentScreen === 'feed' && location.hash && !document.getElementById(location.hash.slice(1)) && !$('feed-more').hidden) appendFeed();
  const target=document.getElementById(location.hash.slice(1));
  if (target) requestAnimationFrame(()=>target.scrollIntoView({block:'start'}));
})();
