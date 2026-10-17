'use strict';
// Esel app mockup: every screen of the cover-SNS design in one tappable page.
// Photos, face boxes and the twelve colours come from the canvas generator (injected as ESEL_DATA at build time).
// Nothing is saved or sent: state lives in memory and resets on reload.

const D = window.ESEL_DATA;
const PEOPLE = D.people;
const PAINT = D.paint;
const ORDER = D.order;
const ME = D.me;
const INK = '#292A27';
const PAPER = '#F9F9FB';
const WHITE = '#FFFFFF';

const $ = (sel, el = document) => el.querySelector(sel);
const $$ = (sel, el = document) => [...el.querySelectorAll(sel)];
const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const pad2 = (n) => String(n).padStart(2, '0');
const pad3 = (n) => String(n).padStart(3, '0');
const pct = (v) => `${Math.round(v * 100)}%`;
const calm = () => matchMedia('(prefers-reduced-motion: reduce)').matches;
const hash = (s) => [...s].reduce((a, c) => a + c.charCodeAt(0), 0);
const jong = (w) => { const c = w.charCodeAt(w.length - 1) - 0xac00; return c >= 0 && c <= 11171 ? c % 28 : 0; };
const ro = (w) => w + (jong(w) === 0 || jong(w) === 8 ? '로' : '으로');
const iga = (w) => w + (jong(w) ? '이' : '가');
const cname = (c) => PAINT[c].name;
const photoSrc = (k) => `img/people/${k}.jpg`;
const paintSrc = (c) => `img/paint/${c}.png`;

// ───────── icons
const HEART = 'M12 20.3l-1.2-1.1C6.2 15 3.5 12.5 3.5 9.4 3.5 7 5.4 5 7.8 5c1.6 0 3.2.9 4.2 2.2C13 5.9 14.6 5 16.2 5c2.4 0 4.3 2 4.3 4.4 0 3.1-2.7 5.6-7.3 9.8L12 20.3z';
const PATHS = {
  plus: '<path d="M12 5v14"/><path d="M5 12h14"/>',
  heart: `<path d="${HEART}"/>`,
  comment: '<path d="M20 12a8 8 0 0 1-11.8 7L4 20l1.1-4A8 8 0 1 1 20 12z"/>',
  bookmark: '<path d="M6.5 4h11v16l-5.5-4.2L6.5 20z"/>',
  arrow: '<path d="M4 12h15"/><path d="M14 7l5 5-5 5"/>',
  up: '<path d="M6 14l6-6 6 6"/>',
  down: '<path d="M6 10l6 6 6-6"/>',
  left: '<path d="M14 6l-6 6 6 6"/>',
  right: '<path d="M10 6l6 6-6 6"/>',
  x: '<path d="M6 6l12 12"/><path d="M18 6L6 18"/>',
  check: '<path d="M5 12.5l4.5 4.5L19 7.5"/>',
  flip: '<path d="M4 9a8 8 0 0 1 14-3l2 2"/><path d="M20 4v4h-4"/><path d="M20 15a8 8 0 0 1-14 3l-2-2"/><path d="M4 20v-4h4"/>',
  apple: '<path d="M15.6 3.5c.1 1.2-.4 2.3-1.1 3.1-.8.8-1.9 1.4-3 1.3-.1-1.1.4-2.3 1.1-3 .8-.8 2-1.4 3-1.4z" fill="currentColor" stroke="none"/><path d="M19.6 16.9c-.5 1.1-.8 1.6-1.4 2.6-.9 1.4-2.2 3.1-3.8 3.1-1.4 0-1.8-.9-3.7-.9s-2.3.9-3.7.9c-1.6 0-2.8-1.6-3.7-3-2.5-3.9-2.8-8.4-1.2-10.8 1.1-1.7 2.9-2.7 4.6-2.7s2.8.9 4.2.9c1.4 0 2.2-.9 4.2-.9 1.5 0 3.1.8 4.2 2.2-3.7 2-3.1 7.3.3 8.6z" fill="currentColor" stroke="none"/>',
  mail: '<rect x="3.5" y="5.5" width="17" height="13" rx="2"/><path d="M4 7l8 6 8-6"/>',
  lock: '<rect x="5.5" y="10.5" width="13" height="9.5" rx="1.5"/><path d="M8.5 10.5V8a3.5 3.5 0 0 1 7 0v2.5"/>',
  share: '<path d="M12 15V4"/><path d="M7.5 8.5L12 4l4.5 4.5"/><path d="M5 13v6.5h14V13"/>',
  gear: '<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/>',
  link: '<path d="M10 14a4.5 4.5 0 0 0 6.4 0l3-3a4.5 4.5 0 0 0-6.4-6.4l-1 1"/><path d="M14 10a4.5 4.5 0 0 0-6.4 0l-3 3a4.5 4.5 0 0 0 6.4 6.4l1-1"/>',
  camera: '<path d="M4 8h3.2l1.5-2.5h6.6L16.8 8H20v11H4z"/><circle cx="12" cy="13.2" r="3.4"/>',
  search: '<circle cx="11" cy="11" r="6.5"/><path d="M16 16l4 4"/>',
};
const icon = (n, size = 24, sw = 1.7, fill = 'none') => `<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="${fill}" stroke="currentColor" stroke-width="${sw}" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${PATHS[n]}</svg>`;

// ───────── photos, paint and covers (same maths as generator/lib.mjs)
function fit(k, W, H, px = 0.5, py = 0.5) {
  const p = PEOPLE[k];
  const iw = 800;
  const ih = 800 * p.r;
  const s = Math.max(W / iw, H / ih);
  const dw = iw * s;
  const dh = ih * s;
  const ox = (dw - W) * px;
  const oy = (dh - H) * py;
  return { fx: p.fx * dw - ox, fy: p.fy * dh - oy, fwPx: p.fw * dw };
}
const paintImg = (c, w, alt = '') => `<img src="${paintSrc(c)}" alt="${esc(alt)}" style="width:${w}px;height:${w / 2}px;object-fit:contain;flex-shrink:0">`;
function strokeImg(k, W, H, px, py, color) {
  const f = fit(k, W, H, px, py);
  const pw = Math.round(f.fwPx * 2.15);
  return `<img src="${paintSrc(color || PEOPLE[k].color)}" alt="" style="left:${Math.round(f.fx - pw / 2)}px;top:${Math.round(f.fy - f.fwPx * 0.12 - pw / 4)}px;width:${pw}px;height:${Math.round(pw / 2)}px;transform:rotate(-10deg)">`;
}
function cropImg(k, W, H, zoom, fx, fy, tx, ty, alt) {
  const p = PEOPLE[k];
  const dw = Math.round(W * zoom);
  const dh = Math.round(dw * p.r);
  const left = Math.round(Math.min(0, Math.max(W - dw, tx - fx * dw)));
  const top = Math.round(Math.min(0, Math.max(H - dh, ty - fy * dh)));
  return `<img src="${photoSrc(k)}" alt="${alt}" loading="lazy" style="left:${left}px;top:${top}px;width:${dw}px;height:${dh}px">`;
}
function neckImg(k, W, H, alt) {
  const p = PEOPLE[k];
  const below = (dw) => dw * p.r - (p.fy * dw * p.r + p.fw * dw * 0.78);
  const z = Math.max(1, (H + 2) / below(W));
  const dw = Math.round(W * z);
  const dh = Math.round(dw * p.r);
  const chin = p.fy * dh + p.fw * dw * 0.78;
  const top = Math.round(Math.min(0, Math.max(H - dh, -chin)));
  const left = Math.round(Math.min(0, Math.max(W - dw, W / 2 - p.fx * dw)));
  return `<img src="${photoSrc(k)}" alt="${alt}, 얼굴 아래로 자른 구도" loading="lazy" style="left:${left}px;top:${top}px;width:${dw}px;height:${dh}px">`;
}
// One photo in a W×H box with a face presentation: plain, paint, behind (masthead), neck, detail, mono.
function face(k, W, H, style = 'plain', o = {}) {
  const p = PEOPLE[k];
  const px = o.px ?? 0.5;
  const py = o.py ?? 0.5;
  const alt = esc(o.alt ?? p.alt);
  let inner;
  if (style === 'neck') inner = neckImg(k, W, H, alt);
  else if (style === 'behind') inner = cropImg(k, W, H, o.zoom ?? 1.7, p.fx, p.fy, W / 2, H * (o.ty ?? 0.2), alt);
  else if (style === 'detail') inner = cropImg(k, W, H, 2.4, 0.55, 0.8, W / 2, H / 2, `${alt}의 디테일`);
  else {
    inner = `<img class="fit" src="${photoSrc(k)}" alt="${alt}" loading="lazy" style="object-position:${pct(px)} ${pct(py)}${style === 'mono' ? ';filter:grayscale(1) contrast(1.06)' : ''}">`;
    if (style === 'paint') inner += strokeImg(k, W, H, px, py, o.color);
  }
  return `<span class="ph" style="width:${W}px;height:${H}px${o.radius ? `;border-radius:${o.radius}px` : ''}">${inner}</span>`;
}
function avatar(k, size) {
  const p = PEOPLE[k];
  const W = Math.round((0.6 * size) / p.fw);
  const H = Math.round(W * p.r);
  const ml = Math.min(0, Math.max(size - W, Math.round(size / 2 - p.fx * W)));
  const mt = Math.min(0, Math.max(size - H, Math.round(size / 2 - p.fy * H)));
  return `<span class="avatar" style="width:${size}px;height:${size}px"><img src="${photoSrc(k)}" alt="" loading="lazy" style="width:${W}px;height:${H}px;left:${ml}px;top:${mt}px"></span>`;
}
const mastSize = (text, W, max = 200) => Math.min(max, Math.floor((W * 0.9) / (Math.max(2, text.length) * 0.47)));

// A small cover. In "plain" the masthead shrinks so it never sits on the face (contract P15).
function mini({ key, w, h, mast = 'Esel', mastColor = WHITE, name = key, style = 'plain', px = 0.5, py = 0.5, fs, go, label, cls = '', color }) {
  const base = fs ?? Math.round(w * 0.44);
  const top = Math.round(h * 0.03);
  let size = base;
  if (style === 'plain' || style === 'mono') {
    const f = fit(key, w, h, px, py);
    const room = Math.floor((f.fy - f.fwPx * 0.8 - top) / 0.8);
    if (room < size) size = Math.max(Math.round(w * 0.24), room);
  }
  const tag = go ? 'button' : 'span';
  const attrs = go ? `type="button" data-go="${go}"` : '';
  return `<${tag} class="mini ${cls}" ${attrs} aria-label="${esc(label ?? `${name}의 표지 보기`)}" style="width:${w}px;height:${h}px;color:${mastColor}">${face(key, w, h, style, { px, py, color })}<span class="mast" aria-hidden="true" style="top:${top}px;font-size:${size}px;padding-right:${Math.round(size * 0.05)}px">${esc(mast)}</span><span class="shade" style="bottom:0;height:40%;background:linear-gradient(rgba(0,0,0,0),rgba(0,0,0,.55))"></span>${name ? `<span class="nm" style="left:${Math.round(w * 0.06)}px;bottom:${Math.round(h * 0.035)}px;font-size:${Math.round(base * 0.34)}px">${esc(name)}</span>` : ''}</${tag}>`;
}
const spine = (it, owner, go) => `<${go ? 'button type="button" data-go="' + go + '"' : 'span'} class="spine" aria-label="Nº ${it.no} · ${cname(it.color)}" style="background:${PAINT[it.color].hex};color:${['burgundy', 'olive', 'charcoal', 'cobalt', 'terracotta'].includes(it.color) ? WHITE : INK}"><span class="serif it" style="font-size:13px">${esc(owner)}</span><span class="mono" style="font-size:10px;letter-spacing:.04em">Nº ${it.no}</span></${go ? 'button' : 'span'}>`;

// ───────── example data (not real people or numbers)
const TODAY_COLORS = ['camel', 'lilac', 'olive'];
const SAME_COUNT = { sage: 142, butter: 118, powder: 187, coral: 103, lilac: 96, terracotta: 77, burgundy: 58, olive: 71, cream: 129, charcoal: 88, camel: 64, cobalt: 92 };
const ISSUES = { dana: 38, ama: 24, lise: 51, kofi: 17, rio: 9, omar: 33, riva: 45, zuri: 21, hana: 14, theo: 29, cleo: 12, vera: 19, freya: 27, june: 8, imani: 15, ayo: 22, sol: 31, ines: 11, elin: 26, mira: 7, nia: 13, lua: 18, maya: 20, leo: 16, noor: 23, mara: 10 };
const FACE = { lise: 'paint', omar: 'neck', noor: 'behind', leo: 'neck', zuri: 'paint', june: 'neck' };
const POS = { dana: [0.58, 0.45], ama: [0.5, 0.3], lise: [0.5, 0.25], kofi: [0.65, 0.15], rio: [0.5, 0.4], riva: [0.5, 0.25], theo: [0.5, 0.5] };
const FEED = ['ama', 'lise', 'kofi', 'rio', 'omar', 'riva', 'zuri', 'hana', 'cleo', 'vera', 'freya', 'june', 'imani', 'ayo', 'sol', 'ines', 'elin', 'mira', 'nia', 'lua', 'maya', 'theo', 'leo', 'noor', 'mara'];
const LINES = { dana: [['zuri', '셔츠 끈 매듭이 다 했네요.'], ['kofi', '하늘이랑 셔츠 색이 똑같아요.'], ['riva', '파란 계열끼리 반가워요.']] };
const POOL = ['색이 정말 잘 어울려요.', '이 조합 따라 입어 볼게요.', '오늘 표지 빛이 좋아요.', '소품까지 색을 맞췄네요.', '같은 색인데 느낌이 완전히 달라요.'];
const DARK = new Set(['theo']);
const RESTORE_CHOICES = { 3: ['lilac', 'olive', 'camel'] };
const LIKERS = ['dana', 'ama', 'zuri', 'kofi', 'riva', 'hana', 'freya', 'leo', 'noor', 'sol', 'elin', 'maya'];
const MY_COUNTS = { likes: 12, lines: 3, scraps: 9, readers: 12 };

function fresh() {
  return {
    auth: 'out',
    me: { name: ME, bio: '옷으로 남기는 나의 계절.', issues: 11, color: 'camel', face: 'paint', mast: 'white', caption: PEOPLE[ME].cap, email: `${ME}@example.com`, minor: false },
    published: false,
    justPublished: false,
    liked: new Set(),
    scrapped: new Set(),
    subs: new Set(['dana', 'theo', 'ama']),
    lines: {},
    feedTab: 'all',
    shelfView: {},
    record: { 1: { c: 'camel', k: 'posted', no: 8 }, 2: { c: 'sage', k: 'posted', no: 9 }, 4: { c: 'powder', k: 'posted', no: 10 }, 5: { c: 'butter', k: 'posted', no: 11 } },
    credits: 2,
    restorePick: {},
    friends: ['dana', 'ama'],
    requests: ['zuri'],
    twin: { step: 'none', with: 'dana', color: 'camel', vis: null, no: 3 },
    notif: { on: true, twin: true, likes: true, remind: true },
    join: { color: 'camel', name: ME, face: 'paint' },
    copied: false,
  };
}
let S = fresh();
let stack = [{ name: 'intro' }];

const locked = () => S.auth === 'in' && !S.published && !S.me.minor;
// P01 (10-15): before publishing, every one of today's candidate colors is at the preview, so switching color opens nothing.
const visibleToday = (k) => !(locked() && TODAY_COLORS.includes(PEOPLE[k].color));
const myIssue = () => S.me.issues + (S.published ? 0 : 1);
const issueOf = (k) => (k === ME ? myIssue() : ISSUES[k] || 12);
const meName = () => S.me.name;
const sameCount = (c) => SAME_COUNT[c] + (S.published && c === S.me.color ? 1 : 0);
function linesFor(k) {
  if (!S.lines[k]) {
    const readers = FEED.filter((r) => r !== k);
    const h = hash(k);
    S.lines[k] = LINES[k] ? LINES[k].map((l) => [...l]) : [[readers[h % readers.length], POOL[h % POOL.length]], [readers[(h * 7) % readers.length], POOL[(h + 2) % POOL.length]]];
  }
  return S.lines[k];
}
const titleOf = (cap) => esc(cap).replace(/, /, ',<br>');

// ───────── shared pieces
const backBtn = (label = '이전', ic = 'left') => `<button type="button" class="icon-btn" data-back aria-label="${label}">${icon(ic, 24)}</button>`;
const wordmark = '<span class="wordmark" aria-hidden="true">Esel<i>.</i></span>';
function page({ eyebrow, title, lead = '', body = '', bottom = '', right = wordmark, id = 'scroller' }) {
  return `<div class="scr">
<div class="top-gap"></div>
<header class="hd">${backBtn()}<span class="eyebrow">${eyebrow}</span><span class="side">${right}</span></header>
<div class="scroll" id="${id}"><div class="pad" style="padding-top:14px;padding-bottom:28px">
<h1 class="h1">${title}</h1>${lead ? `<p class="lead">${lead}</p>` : ''}
${body}
</div></div>
${bottom ? `<div class="bottom-bar">${bottom}</div>` : ''}
</div>`;
}
const row = ({ go, act, title, sub = '', lead = '', chev = true, attrs = '' }) => `<button type="button" class="row" ${go ? `data-go="${go}"` : ''} ${act ? `data-act="${act}"` : ''} ${attrs}>${lead}<span class="t"><b>${title}</b>${sub ? `<span>${sub}</span>` : ''}</span>${chev ? `<span class="chev">${icon('right', 20)}</span>` : ''}</button>`;
function capsule(cur) {
  return `<nav class="capsule glass" aria-label="주요 화면">
<button type="button" class="side" data-tab="stand" aria-label="오늘의 색 가판대"${cur === 'stand' ? ' aria-current="page"' : ''}>${paintImg(S.me.color, 52)}</button>
<button type="button" class="make" data-tab="make" aria-label="오늘 호 만들기">${icon('plus', 22, 2)}</button>
<button type="button" class="side" data-tab="me" aria-label="내 잡지"${cur === 'me' ? ' aria-current="page"' : ''}>${avatar(ME, 34)}</button>
</nav>`;
}
function stat(kind, k, { onPhoto = false, own = false } = {}) {
  if (kind === 'like') {
    const on = S.liked.has(k);
    return `<button type="button" class="stat" data-act="like:${k}" aria-label="좋아요" aria-pressed="${on}">${icon('heart', 23, 1.7, on ? 'currentColor' : 'none')}${own ? `<span>${MY_COUNTS.likes}</span>` : ''}</button>`;
  }
  if (kind === 'scrap') {
    const on = S.scrapped.has(k);
    return `<button type="button" class="stat" data-act="scrap:${k}" aria-label="스크랩" aria-pressed="${on}">${icon('bookmark', 23, 1.7, on ? 'currentColor' : 'none')}${own ? `<span>${MY_COUNTS.scraps}</span>` : ''}</button>`;
  }
  if (kind === 'line') return `<button type="button" class="stat" data-go="spread:${k}:line" aria-label="독자 한 줄">${icon('comment', 23)}${own ? `<span>${MY_COUNTS.lines}</span>` : ''}</button>`;
  return `<button type="button" class="stat" data-act="share:${k}" aria-label="공유">${icon('share', 23)}</button>`;
}
const subbed = (k) => S.auth === 'in' && S.subs.has(k);
const subPill = (k, fg) => `<button type="button" class="pill-btn" data-act="sub:${k}" aria-pressed="${subbed(k)}" style="color:${fg}">${subbed(k) ? `<span class="pill on"><span style="color:${fg === WHITE ? INK : PAPER}">구독 중</span></span>` : '<span class="pill">구독</span>'}</button>`;

// ───────── feed: the first item is the cover, the rest are inner pages
function coverH() { return Math.max(620, ($('#app').clientHeight || 852) - 52); }
function coverSection(k, { tabs = true, H }) {
  const p = PEOPLE[k];
  const dark = DARK.has(k);
  const fg = dark ? WHITE : INK;
  const [px, py] = POS[k] || [0.5, 0.5];
  return `<section class="cover-sec on-photo" aria-label="오늘의 표지" style="height:${H}px;background:${dark ? '#26252C' : '#C9D3DC'}">
<span style="position:absolute;inset:0">${face(k, 393, H, 'plain', { px, py: dark ? 0.5 : 0.5 })}</span>
${dark ? '<div class="shade" style="top:0;height:300px;background:linear-gradient(rgba(0,0,0,.4),rgba(0,0,0,0))"></div>' : ''}
<div class="shade" style="bottom:0;height:460px;background:linear-gradient(rgba(0,0,0,0),rgba(0,0,0,.72))"></div>
<div class="topbar" style="color:${fg}">${tabs ? `<div class="tabs" role="group" aria-label="피드"><button type="button" data-act="feedtab:all" aria-pressed="${S.feedTab === 'all'}"><span>전체</span><i></i></button><button type="button" data-act="feedtab:subs" aria-pressed="${S.feedTab === 'subs'}"><span>구독</span><i></i></button></div>` : '<span style="padding-left:6px">오늘의 표지</span>'}<span style="font-size:12px">Nº 249 · 2026. 9. 6.</span></div>
<h1 class="sr">Esel 오늘의 표지</h1>
<div class="cover-text" style="bottom:52px">
<div style="display:flex;align-items:flex-end;gap:12px"><button type="button" class="name" data-go="shelf:${k}">${k}</button>${subPill(k, WHITE)}</div>
<button type="button" data-go="stand:${p.color}" style="height:44px;margin-top:4px;display:flex;align-items:center;gap:8px;font-size:14px;font-weight:600">${paintImg(p.color, 60, cname(p.color))}<span>${cname(p.color)} · 같은 색 ${sameCount(p.color)}명</span>${icon('arrow', 18, 1.8)}</button>
<p style="margin:0;font-size:15px;line-height:1.45">${esc(p.cap)}</p>
<div style="display:flex;align-items:center;margin:2px 0 0 -12px">${stat('like', k)}${stat('line', k)}${stat('scrap', k)}<button type="button" data-go="spread:${k}" style="margin-left:auto;height:48px;padding:0 12px;display:flex;align-items:center;gap:4px;font-size:14px;font-weight:600"><span>펼쳐 보기</span>${icon('up', 20, 1.8)}</button></div>
</div>
</section>`;
}
function inner(k, no, { mine = false } = {}) {
  const p = PEOPLE[k];
  const color = mine ? S.me.color : p.color;
  const style = mine ? S.me.face : FACE[k] || 'plain';
  const [px, py] = POS[k] || [0.5, 0.3];
  const who = mine ? meName() : k;
  return `<article class="inner">
<div class="folio"><span>${no}</span><span>${mine ? '방금' : p.time}</span></div>
<button type="button" data-go="spread:${k}" aria-label="${esc(who)}의 펼침면 보기" style="display:block">${face(k, 393, 500, style, { px, py, color })}</button>
<div class="namerow"><button type="button" class="who" data-go="${mine ? 'me' : `shelf:${k}`}">${esc(who)}</button><button type="button" data-go="stand:${color}" style="display:flex;align-items:center;gap:8px;height:44px">${paintImg(color, 54)}<span class="cn">${cname(color)}</span></button><span style="margin-left:auto;display:flex">${stat('like', k, { own: mine })}${stat('scrap', k, { own: mine })}</span></div>
<p class="cap">${esc(mine ? S.me.caption : p.cap)}</p>
</article>`;
}
function mastLayer(color) {
  return `<button type="button" class="pill-logo" data-act="top" aria-label="맨 위 표지로 돌아가기" tabindex="-1"></button>
<div class="mast-float" aria-hidden="true" style="color:${color}"><span>Esel<span class="dot">.</span></span></div>`;
}
// Scroll-linked masthead (same thresholds as generator/scroll.mjs, contract P16) and the logged-out login bar.
function morph(root, { loginAt = 0, coverColor = INK } = {}) {
  const sc = $('#scroller', root);
  const mast = $('.mast-float', root);
  const pill = $('.pill-logo', root);
  const dot = $('.mast-float .dot', root);
  const login = $('#loginbar', root);
  const es = { mode: 'cover', y: 0, dir: 0, acc: 0, animUntil: 0, login: false };
  const MELT = 360;
  const S0 = 0.14;
  const PILL = -97;
  const write = (ty, scale, opacity, d, pl, shift, color) => {
    const moving = Date.now() < es.animUntil;
    const t = moving ? 'transform 200ms var(--out), opacity 200ms ease-out' : 'none';
    mast.style.transition = t;
    mast.style.transform = `translateY(${ty}px) scale(${scale})`;
    mast.style.opacity = opacity;
    mast.style.color = color;
    dot.style.opacity = d;
    pill.style.transition = t;
    pill.style.transform = `translateY(${shift}px)`;
    pill.style.opacity = pl;
    pill.style.pointerEvents = pl > 0.5 ? 'auto' : 'none';
    pill.tabIndex = pl > 0.5 ? 0 : -1;
  };
  const paintAt = (y) => {
    if (es.mode === 'cover') {
      if (y < 300) write(-y, 1, 1, 0, 0, 0, coverColor);
      else write(PILL - 12, S0, 0, 0, 0, -12, INK);
      return;
    }
    if (calm() || y >= MELT) { write(PILL, S0, 1, 1, 1, 0, INK); return; }
    const clamp = (v) => Math.max(0, Math.min(1, v));
    const p = 1 - y / MELT;
    const e = p * p * (3 - 2 * p);
    write(Math.max(PILL, -y), S0 + (1 - S0) * e, 1, 1 - clamp(p / 0.25), 1 - clamp(p / 0.18), 0, INK);
  };
  sc.addEventListener('scroll', () => {
    const y = Math.max(0, sc.scrollTop);
    const d = y - es.y;
    es.y = y;
    if (d !== 0) {
      const dir = d > 0 ? 1 : -1;
      if (dir !== es.dir) { es.dir = dir; es.acc = 0; }
      es.acc += Math.abs(d);
    }
    let mode = es.mode;
    if (y <= 1) mode = 'cover';
    else if (mode === 'cover' && y >= MELT && es.dir < 0 && es.acc >= 48) mode = 'float';
    else if (mode === 'float' && y >= MELT && es.dir > 0 && es.acc >= 18) mode = 'cover';
    if (mode !== es.mode) {
      es.mode = mode;
      if (y > 1) {
        if (mode === 'float') { es.animUntil = 0; write(-109, S0, 0, 1, 0, -12, INK); void mast.offsetWidth; }
        es.animUntil = Date.now() + 220;
      }
    }
    paintAt(y);
    if (login) {
      const show = y >= loginAt;
      if (show !== es.login) {
        es.login = show;
        login.style.transition = calm() ? 'opacity 200ms ease-out' : 'transform 360ms var(--drawer), opacity 200ms ease-out';
        login.style.transform = show || calm() ? 'translateY(0)' : 'translateY(140%)';
        login.style.opacity = show ? 1 : 0;
        login.style.pointerEvents = show ? 'auto' : 'none';
      }
    }
  }, { passive: true });
  paintAt(0);
}

// ───────── screens
const SCREENS = {};

// J1 비로그인 표지: the cover, two inner pages, then the login bar rises in the capsule's place (P12)
SCREENS.intro = () => ({
  html: `<div class="scr">
<div class="scroll" id="scroller">
${coverSection('dana', { tabs: false, H: coverH() })}
${inner('ama', '02')}
${inner('lise', '03')}
<section aria-label="맛보기 끝" style="position:relative;height:430px;overflow:hidden">
<span aria-hidden="true" style="position:absolute;left:-20px;top:-20px;filter:blur(16px);opacity:.85">${face('kofi', 433, 470, 'plain', { px: 0.65, py: 0.15, alt: '' })}</span>
<div aria-hidden="true" style="position:absolute;inset:0;background:linear-gradient(rgba(249,249,251,.15),${PAPER} 78%)"></div>
<div style="position:absolute;left:28px;right:28px;top:170px;text-align:center">
<p class="serif" style="margin:0;font-size:27px;line-height:1.3">오늘 호는 아직<br>열두 쪽이 더 남았어요.</p>
<p style="margin:12px 0 0;font-size:14px;line-height:1.55;color:var(--muted)">로그인하면 끝까지 읽고, 내 잡지도 만들 수 있어요.</p>
</div>
</section>
<div style="height:120px"></div>
</div>
${mastLayer(INK)}
<div class="loginbar glass" id="loginbar"><button type="button" class="a" data-act="login">로그인</button><button type="button" class="b" data-go="join-color">내 잡지 만들기</button></div>
</div>`,
  mount: (el) => morph(el, { loginAt: 640 }),
});

// C1·C2·C7 표지 피드
SCREENS.feed = () => {
  const subs = FEED.filter((k) => S.subs.has(k));
  const coverKey = S.feedTab === 'subs' ? (S.subs.has('theo') ? 'theo' : S.subs.has('dana') ? 'dana' : subs[0]) : 'dana';
  let list = (S.feedTab === 'subs' ? [...(S.subs.has('dana') ? ['dana'] : []), ...subs] : FEED).filter((k) => k !== coverKey && visibleToday(k));
  list = [...new Set(list)];
  const pages = [];
  let n = 2;
  if (S.published && S.feedTab === 'all') pages.push(inner(ME, pad2(n++), { mine: true }));
  list.forEach((k, i) => {
    pages.push(inner(k, pad2(n++)));
    if (i === 2 && locked() && S.feedTab === 'all') {
      pages.push(`<button type="button" class="notice" data-go="same">${paintImg(S.me.color, 64)}<span style="display:flex;flex-direction:column;gap:3px;flex:1"><b style="font-size:15px">오늘의 ${cname(S.me.color)} · ${sameCount(S.me.color)}명</b><span style="font-size:13px;color:var(--muted)">발행하면 함께 펼쳐집니다</span></span>${icon('right', 20)}</button>`);
    }
  });
  if (!coverKey) {
    return { html: `<div class="scr"><div class="top-gap"></div><div class="pad" style="padding-top:60px"><h1 class="h1">구독한 잡지가 없어요</h1><p class="lead">표지에서 구독을 누르면 여기에서 모아 볼 수 있어요.</p><div style="margin-top:20px"><button type="button" class="btn line" data-act="feedtab:all">전체 표지 보기</button></div></div></div>`, capsule: 'feed' };
  }
  return {
    html: `<div class="scr">
<div class="scroll" id="scroller">
${coverSection(coverKey, { H: coverH() })}
${pages.join('\n')}
<div style="height:110px"></div>
</div>
${mastLayer(DARK.has(coverKey) ? WHITE : INK)}
</div>`,
    capsule: 'feed',
    mount: (el) => morph(el, { coverColor: DARK.has(coverKey) ? WHITE : INK }),
  };
};

// C3 펼침면
SCREENS.spread = (arg = 'dana') => {
  const [k, focus] = arg.split(':');
  const mine = k === ME && S.published;
  const p = PEOPLE[k];
  const who = k === ME ? meName() : k;
  const color = k === ME ? S.me.color : p.color;
  const style = k === ME ? S.me.face : FACE[k] || 'plain';
  const [px] = POS[k] || [0.5];
  const lines = linesFor(k);
  const canWrite = S.auth === 'in';
  return {
    html: `<div class="scr">
<div class="top-gap"></div>
<header class="hd" style="padding-right:12px">${backBtn('표지로 돌아가기', 'down')}<span class="serif it" style="font-size:18px">${esc(who)} · Nº ${pad3(issueOf(k))}</span>${k === ME ? '<span class="side"></span>' : subPill(k, INK)}</header>
<div class="scroll" id="scroller"><div class="pad" style="padding-bottom:110px">
<div class="serif it" style="display:flex;align-items:baseline;justify-content:space-between;height:30px;font-size:16px"><span>01</span><span>${mine ? '방금' : p.time}</span></div>
<h1 class="serif" style="margin:6px 0 0;font-size:34px;font-weight:400;line-height:1.22;letter-spacing:-.01em">${titleOf(k === ME ? S.me.caption : p.cap)}</h1>
<button type="button" data-go="${k === ME ? 'me' : `shelf:${k}`}" style="height:48px;display:flex;align-items:center;gap:8px">${avatar(k, 32)}<span style="margin-left:2px;font-size:15px;font-weight:600">${esc(who)}</span>${paintImg(color, 48)}<span style="font-size:13px;color:var(--muted)">${cname(color)}</span></button>
<div class="hscroll" style="display:flex;gap:8px;margin:6px -20px 0 0">${face(k, 210, 280, style, { px, py: 0.45, radius: 4, color })}${face(k, 210, 280, 'detail', { radius: 4 })}<span style="width:12px;flex-shrink:0"></span></div>
<div style="display:flex;align-items:center;margin-left:-12px">${stat('like', k, { own: mine })}${stat('scrap', k, { own: mine })}${stat('share', k)}</div>
${mine ? `<p class="note" style="margin:0 0 6px">오늘 ${MY_COUNTS.readers}명이 읽었어요 · 나에게만 보여요</p>` : ''}
<h2 class="serif" style="margin:4px 0 2px;font-size:21px;font-weight:400">독자 한 줄</h2>
<div id="lines">${lines.map(([r, t]) => readerLine(r, t)).join('')}</div>
</div></div>
<form id="line-form" style="position:absolute;left:16px;right:16px;bottom:var(--sb);z-index:10" autocomplete="off">
<label for="one-line" class="sr">한 줄 남기기</label>
<input id="one-line" class="glass" type="text" maxlength="60" placeholder="${canWrite ? '한 줄 남기기' : '로그인하면 한 줄을 남길 수 있어요'}" ${canWrite ? '' : 'readonly data-act="login"'} style="width:100%;height:50px;box-sizing:border-box;padding:0 20px;border:0;border-radius:25px;font-size:15px;outline:none">
</form>
</div>`,
    mount: (el) => {
      const form = $('#line-form', el);
      form.addEventListener('submit', (e) => {
        e.preventDefault();
        const input = $('#one-line', el);
        const text = input.value.trim();
        if (!text || S.auth !== 'in') return;
        linesFor(k).push([ME, text]);
        $('#lines', el).insertAdjacentHTML('beforeend', readerLine(ME, text));
        input.value = '';
        toast('한 줄을 남겼어요');
      });
      if (focus === 'line' && canWrite) setTimeout(() => $('#one-line', el).focus(), 50);
    },
  };
};
function readerLine(r, t) {
  const color = r === ME ? S.me.color : PEOPLE[r].color;
  return `<div style="display:flex;gap:10px;padding:7px 0">${avatar(r, 30)}<div style="min-width:0"><div style="display:flex;align-items:center;gap:6px;height:18px"><span style="font-size:14px;font-weight:600">${esc(r === ME ? meName() : r)}</span>${paintImg(color, 40)}<span style="font-size:12px;color:var(--muted)">${cname(color)}</span></div><p style="margin:2px 0 0;font-size:14.5px;line-height:1.4">${esc(t)}</p></div></div>`;
}

// C4 가판대
function chips(active) {
  const today = [S.me.color, ...TODAY_COLORS.filter((c) => c !== S.me.color)];
  const lockChip = (c) => `<button type="button" class="chip locked${active === c ? ' on' : ''}" data-go="same:${c}" aria-label="${cname(c)} · 오늘 발행 전이라 세 장만 먼저 보여요"><span>${paintImg(c, 40)}<span>${cname(c)}</span>${icon('lock', 15, 1.8)}</span></button>`;
  const openChip = (c) => `<button type="button" class="chip${active === c ? ' on' : ''}" data-go="stand:${c}" aria-pressed="${active === c}"><span${c === S.me.color ? ' id="mychip"' : ''}>${paintImg(c, 40)}<span>${cname(c)}</span></span></button>`;
  return `<div class="chips" role="group" aria-label="같은 색">
<button type="button" class="chip plain${!active ? ' on' : ''}" data-go="stand" aria-pressed="${!active}"><span>전체</span></button>
${today.map((c) => (locked() ? lockChip(c) : openChip(c))).join('')}
${ORDER.filter((c) => !today.includes(c)).map(openChip).join('')}
</div>`;
}
function shelfGrid(keys, { rise = false } = {}) {
  const rows = [];
  for (let i = 0; i < keys.length; i += 2) {
    const cell = (k, j) => (k ? `<span class="${rise ? 'rise' : ''}" style="${rise ? `animation-delay:${(i + j) * 40}ms` : ''}">${k === ME ? mini({ key: ME, w: 174, h: 250, mast: 'Esel', name: meName(), style: S.me.face, color: S.me.color, go: `spread:${ME}` }) : mini({ key: k, w: 174, h: 250, style: FACE[k] || 'plain', py: 0.3, mastColor: ['kofi', 'maya'].includes(k) ? INK : WHITE, go: `spread:${k}` })}</span>` : '<span style="width:174px"></span>');
    rows.push(`<div style="display:flex;justify-content:space-between;padding:0 16px">${cell(keys[i], 0)}${cell(keys[i + 1], 1)}</div><span class="shelf-line" aria-hidden="true" style="margin-bottom:16px"></span>`);
  }
  return rows.join('');
}
SCREENS.stand = (c) => {
  if (c && TODAY_COLORS.includes(c) && locked()) return { redirect: { name: 'same', arg: c } };
  let keys = FEED.filter(visibleToday).filter((k) => !c || PEOPLE[k].color === c);
  if (S.published && (!c || c === S.me.color)) keys = [ME, ...keys];
  return {
    html: `<div class="scr">
<div class="top-gap"></div>
<header style="flex-shrink:0;height:48px;display:flex;align-items:center;justify-content:space-between;padding:0 18px 0 6px">
<span style="display:flex;align-items:center">${stack.length > 1 ? backBtn() : '<span style="width:12px"></span>'}<h1 class="serif" style="margin:0;font-size:32px;font-weight:400;line-height:1">가판대</h1></span>
<span class="serif it" style="font-size:17px">9. 6. 일요일</span></header>
<button type="button" class="btn text" data-go="challenges">이번 주의 착장 →</button><button type="button" class="btn text" data-go="collections">일·주·월 표지 특집 →</button>
${chips(c)}
${c ? `<div style="flex-shrink:0;height:40px;display:flex;align-items:center;gap:6px;padding:0 20px">${paintImg(c, 48)}<span style="font-size:15px;font-weight:600">오늘의 ${cname(c)} · ${sameCount(c)}명</span></div>` : ''}
<div class="scroll" id="scroller">${shelfGrid(keys)}<div style="height:100px"></div></div>
</div>`,
    capsule: 'stand',
  };
};

// C8 같은 색 · 발행 전 (P01: every candidate color shows three newest covers, the rest are closed spines; opens on own publish or at midnight)
const LOCK_FACE = { leo: { style: 'neck', mastColor: INK }, noor: { style: 'behind' }, mara: { fs: 38 } };
SCREENS.same = (color) => {
  const c = color || S.me.color;
  const room = FEED.filter((k) => PEOPLE[k].color === c).sort((a, b) => minutes(PEOPLE[b].time) - minutes(PEOPLE[a].time));
  if (!locked()) {
    const fx = S.justPublished;
    S.justPublished = false;
    return {
      html: `<div class="scr">
<div class="top-gap"></div>
<header style="flex-shrink:0;height:48px;display:flex;align-items:center;justify-content:space-between;padding:0 18px 0 6px"><span style="display:flex;align-items:center">${backBtn()}<h1 class="serif" style="margin:0;font-size:32px;font-weight:400;line-height:1">가판대</h1></span><span class="serif it" style="font-size:17px">9. 6. 일요일</span></header>
${chips(c)}
<div style="flex-shrink:0;padding:0 20px 8px;display:flex;flex-direction:column;gap:2px">
<div style="display:flex;align-items:center;gap:6px;height:40px">${paintImg(c, 56)}<span style="font-size:15px;font-weight:600">오늘의 ${cname(c)} · ${sameCount(c)}명</span></div>
${fx ? `<p class="note" style="margin:0">발행해서 같은 색 표지가 모두 펼쳐졌어요.</p>` : ''}
</div>
<div class="scroll" id="scroller">${shelfGrid(c === S.me.color ? [ME, ...room] : room, { rise: fx })}<div style="height:100px"></div></div>
</div>`,
      capsule: 'stand',
      mount: (el) => { if (fx) $('#mychip', el)?.classList.add('unlock-fill'); },
    };
  }
  const open = room.slice(0, 3);
  const w = open.length >= 3 ? 113 : 174;
  const names = ['yuna', 'marco', 'ella', 'kai', 'sora', 'remi', 'zoe', 'taro', 'lena', 'oli', 'mina', 'jun', 'ava', 'noa'];
  return {
    html: `<div class="scr">
<div class="top-gap"></div>
<header style="flex-shrink:0;height:48px;display:flex;align-items:center;justify-content:space-between;padding:0 18px 0 6px"><span style="display:flex;align-items:center">${backBtn()}<h1 class="serif" style="margin:0;font-size:32px;font-weight:400;line-height:1">가판대</h1></span><span class="serif it" style="font-size:17px">9. 6. 일요일</span></header>
${chips(c)}
<div class="scroll" id="scroller">
<div style="height:48px;display:flex;align-items:center;gap:6px;padding:0 20px">${paintImg(c, 56)}<span style="font-size:15px;font-weight:600">오늘의 ${cname(c)} · ${sameCount(c)}명</span><span style="margin-left:auto;font-size:13px;color:var(--muted)">먼저 ${open.length}장</span></div>
<div style="display:flex;justify-content:space-between;padding:0 16px">${open.map((k) => mini({ key: k, w, h: Math.round(w * 1.437), py: 0.3, go: `spread:${k}`, ...(LOCK_FACE[k] || {}) })).join('')}</div>
<span class="shelf-line" aria-hidden="true" style="margin-bottom:14px"></span>
<section aria-label="${cname(c)} 표지 ${sameCount(c) - open.length}장 · 오늘 호를 발행하면 펼쳐져요" style="position:relative;padding:0 16px">
<div aria-hidden="true" style="display:flex;gap:4px;align-items:flex-end;filter:blur(2.5px)">${names.map((n, i) => `<span style="width:22px;height:${196 + ((i * 37) % 5) * 6}px;flex-shrink:0;display:flex;justify-content:center;padding-top:8px;box-sizing:border-box;background:${PAINT[c].hex};opacity:${0.55 + ((i * 3) % 4) * 0.1};font-family:var(--serif);font-style:italic;font-size:13px;writing-mode:vertical-rl">${n}</span>`).join('')}</div>
<span class="shelf-line" aria-hidden="true"></span>
<div style="position:absolute;left:50%;top:60px;transform:translateX(-50%);width:280px;padding:16px 18px 12px;box-sizing:border-box;border-radius:22px;display:flex;flex-direction:column;align-items:center;gap:4px;text-align:center;background:rgba(249,249,251,.94);box-shadow:inset 0 0 0 1px var(--hair),0 10px 28px rgba(0,0,0,.1)">
${icon('lock', 20, 1.8)}
<p class="serif" style="margin:2px 0 0;font-size:22px;line-height:1.2">발행하면 함께 펼쳐집니다</p>
<p style="margin:0;font-size:13px;line-height:1.45;color:var(--muted)">${cname(c)} 표지 ${sameCount(c) - open.length}장이 더 있어요.<br>자정이 지나면 모두 펼쳐져요.</p>
</div>
</section>
<div style="display:flex;justify-content:center;margin-top:18px"><button type="button" class="btn small" data-tab="make">${icon('plus', 18, 2)}<span>오늘 호 만들기</span></button></div>
<div style="height:110px"></div>
</div>
</div>`,
    capsule: 'stand',
  };
};
const minutes = (t) => { const m = t.match(/(오전|오후) (\d+):(\d+)/); if (!m) return 0; let h = +m[2] % 12; if (m[1] === '오후') h += 12; return h * 60 + +m[3]; };

// C5 서가 (someone else's magazine) and M1 내 잡지
function pastIssues(owner, count, colors) {
  return Array.from({ length: Math.min(26, count) }, (_, i) => ({ no: pad3(count - i), color: colors[i % colors.length] }));
}
const OLDER = ['coral', 'sage', 'butter', 'cobalt', 'cream', 'powder', 'lilac', 'camel', 'olive', 'powder', 'terracotta', 'charcoal', 'sage', 'powder', 'burgundy', 'butter'];
function issueShelf(owner, photoKey, items, view, viewKey, { color, styles = ['plain', 'paint', 'behind', 'neck', 'detail', 'mono'] } = {}) {
  const covers = items.slice(0, 6).map((it, i) => `<div style="width:113px">${mini({ key: photoKey, w: 113, h: 166, mast: owner, mastColor: INK, name: '', style: styles[i % styles.length], px: 0.58, py: 0.5, fs: mastSize(owner, 113, 46), label: `Nº ${it.no} 표지 보기`, go: `spread:${photoKey}`, color })}<div class="mono" style="height:26px;display:flex;align-items:center;justify-content:space-between;font-size:11px"><span>Nº ${it.no}</span><span style="width:22px;height:4px;border-radius:2px;background:${PAINT[it.color].hex}"></span></div></div>`).join('');
  const spines = [items.slice(0, 13), items.slice(13, 26)].filter((r) => r.length).map((r) => `<div style="display:flex;gap:5px;align-items:flex-end">${r.map((it) => spine(it, owner)).join('')}</div><span class="shelf-line" aria-hidden="true" style="margin-bottom:18px"></span>`).join('');
  return `<div style="margin:14px 0 10px;border-bottom:2px solid var(--ink);display:flex;align-items:center;justify-content:space-between">
<h2 class="serif" style="margin:0;font-size:21px;font-weight:400">지난 호</h2>
<div role="group" aria-label="지난 호 보기" class="tabs" style="margin-right:-8px">${['covers', 'spines'].map((v) => `<button type="button" data-act="shelfview:${viewKey}:${v}" aria-pressed="${view === v}" style="padding:0 8px;font-size:14px;font-weight:${view === v ? 600 : 400};color:${view === v ? INK : 'var(--muted)'}"><span>${v === 'covers' ? '표지' : '책등'}</span></button>`).join('')}</div>
</div>
${view === 'covers' ? `<div style="display:flex;flex-wrap:wrap;justify-content:space-between;row-gap:8px">${covers}</div>` : `<div style="display:flex;flex-direction:column;padding-top:6px">${spines}</div>`}`;
}
SCREENS.shelf = (k = 'dana') => {
  if (k === ME) return { redirect: { name: 'me' } };
  const p = PEOPLE[k];
  const n = ISSUES[k] || 12;
  const view = S.shelfView[k] || 'covers';
  const items = pastIssues(k, n, Array.from({ length: 26 }, (_, i) => (i < 6 ? p.color : OLDER[(i + hash(k)) % OLDER.length])));
  return {
    html: `<div class="scr">
<div class="top-gap"></div>
<header class="hd" style="padding-right:18px">${backBtn('표지로 돌아가기')}<span class="eyebrow" style="color:var(--ink)">ESEL · 개인 잡지</span></header>
<div class="scroll" id="scroller"><div class="pad shelf-head" style="padding-bottom:110px">
<h1>${k}</h1>
<div style="display:flex;align-items:center;justify-content:space-between;margin-top:14px">
<div style="display:flex;flex-direction:column;gap:2px"><div style="display:flex;align-items:center;gap:6px;font-size:14px">${paintImg(p.color, 52)}<span>오늘은 ${cname(p.color)}</span></div><span style="font-size:14px;color:var(--muted)">${n}호 발행</span></div>
<button type="button" class="sub-btn${S.subs.has(k) ? ' on' : ''}" data-act="sub:${k}" aria-pressed="${S.subs.has(k)}">${S.subs.has(k) ? '구독 중' : '구독'}</button>
</div>
${issueShelf(k, k, items, view, k)}
</div></div>
</div>`,
    capsule: 'feed',
  };
};
SCREENS.challenges = () => ({
  html: `<div class="scr"><div class="top-gap"></div><header style="display:flex;align-items:center">${backBtn()}<h1 class="serif" style="font-size:24px">이번 주의 착장</h1></header><div class="scroll" style="padding:20px">
<h2 class="serif">옷을 입는 작은 이유</h2><p class="note">오늘 후보 3색과 함께 내 잡지에 이야기를 남겨요.<br>목업 · 저장하지 않는 예시 화면</p>
<h2 class="serif">주간 드레스코드</h2><p>가방으로 포인트 · 서울 월요일~일요일</p><p class="note">오늘 후보 색과 주제를 함께 표현해요. 새 옷을 살 필요는 없어요.</p><button type="button" class="btn" data-act="content-weekly">이번 주 주제에 참여하기</button>
<h2 class="serif">같은 옷, 다른 코디</h2><p class="note">내 지난 날짜 발행 표지를 골라 같은 옷인지 직접 확인해요. 앱에서 실제 내 기록을 선택할 수 있어요.</p><button type="button" class="btn line" data-act="content-restyle">지난 표지 골라 참여하기</button><h2 class="serif">내 참여 표지</h2><p class="note">${S.contentAttached ? '오늘 발행한 호를 연결했어요. 호수는 늘지 않아요.' : '첫 참여를 기다리고 있어요. 오늘 호도 연결할 수 있어요.'}</p><div style="height:40px"></div></div></div>`, capsule: null
});
SCREENS.collections = () => ({
  html: `<div class="scr"><div class="top-gap"></div><header style="display:flex;align-items:center">${backBtn()}<h1 class="serif" style="font-size:24px">표지 특집</h1></header><div class="scroll" style="padding:20px">
  <h2 class="serif">일·주·월의 표지를 엮어요</h2><p class="note">내가 고른 공개 표지와 선정 이유를 기록해요.<br>목업 · 로컬 직접 선정 화면의 예시</p>
  <p>일간 · 주간 · 월간</p><p class="note">서울 시간 기준 · 이전 기간도 확인할 수 있어요.</p>
  <h2 class="serif">선정 이유가 있는 특집</h2><p>주제에 맞는 착장 · 색 활용 · 다양한 스타일</p><p class="note">공개 규칙을 먼저 적용해요. 좋아요 순위나 자동 점수는 사용하지 않아요.</p>
  <h2 class="serif">아직 엮은 표지가 없어요</h2><p class="note">Flutter 앱에서는 기간별 공개 표지 고르기, 선정 이유 저장·수정, 해제와 재조회가 가능해요. 이 목업은 저장하지 않는 구성 견본이에요.</p>
  <button type="button" class="btn line" data-go="stand">공개 표지 살펴보기</button><div style="height:40px"></div></div></div>`, capsule: null
});
SCREENS.me = () => {
  const m = S.me;
  const n = myIssue();
  const view = S.shelfView[ME] || 'covers';
  const dayColors = [m.color, 'butter', 'powder', 'sage', 'camel', ...OLDER];
  const items = m.issues ? pastIssues(m.name, m.issues, S.published ? dayColors : dayColors.slice(1)) : [];
  const today = S.published
    ? `<div class="card" style="display:flex;gap:14px;align-items:center;margin-top:18px">${mini({ key: ME, w: 92, h: 132, mast: m.name, mastColor: m.mast === 'white' ? WHITE : INK, name: '', style: m.face, color: m.color, fs: mastSize(m.name, 92, 40), go: `spread:${ME}` })}<div style="display:flex;flex-direction:column;gap:6px;min-width:0"><span class="mono" style="font-size:11px;letter-spacing:.06em">Nº ${pad3(m.issues)} · 오늘</span><span class="serif" style="font-size:20px;line-height:1.25">${esc(m.caption)}</span><span style="font-size:13px;color:var(--muted)">오늘 ${MY_COUNTS.readers}명이 읽었어요 · 나에게만 보여요</span><div style="display:flex;gap:6px;margin-top:2px"><button type="button" class="btn line small" style="height:38px;padding:0 14px;font-size:14px" data-act="share:${ME}">${icon('share', 16)}공유</button></div></div></div>`
    : `<div class="card" style="margin-top:18px;display:flex;flex-direction:column;gap:12px"><div style="display:flex;align-items:center;gap:8px">${paintImg(m.color, 56)}<span style="font-size:15px;font-weight:600">오늘은 ${cname(m.color)}</span></div><p class="note" style="margin:0">오늘 호를 아직 만들지 않았어요. 발행하면 같은 색 ${sameCount(m.color)}명의 표지가 함께 펼쳐져요.</p><button type="button" class="btn" data-tab="make">오늘 호 만들기</button></div>`;
  return {
    html: `<div class="scr">
<div class="top-gap"></div>
<header class="hd">${backBtn()}<span class="eyebrow" style="color:var(--ink)">MY MAGAZINE / Nº ${pad3(n)}</span><span class="side"><button type="button" class="icon-btn" data-go="settings" aria-label="설정">${icon('gear', 22)}</button></span></header>
<div class="scroll" id="scroller"><div class="pad shelf-head" style="padding-bottom:110px">
<h1>${esc(m.name)}</h1>
<p class="lead" style="margin-top:12px">${esc(m.bio)}</p>
<button type="button" data-go="reactions" style="margin-top:6px;height:44px;display:flex;align-items:center;gap:6px;font-size:14px"><span>${m.issues}개의 표지</span><span class="muted">·</span><span style="text-decoration:underline;text-underline-offset:4px">내 표지의 좋아요 보기</span>${icon('arrow', 16, 1.8)}</button>
${today}
<div class="rows" style="margin-top:14px">
${row({ go: 'collections', title: '일·주·월 표지 특집', sub: '선정 이유로 소개하는 공개 표지' })}
${row({ go: 'challenges', title: '이번 주의 착장', sub: '주간 드레스코드 · 같은 옷, 다른 코디' })}
${row({ go: 'record', title: '월간 색 기록', sub: '9월, 내가 입은 색의 흐름' })}
${row({ go: 'twin', title: '친구와 트윈', sub: S.twin.step === 'none' ? '같은 날, 서로 다른 표지' : `${S.twin.with}와의 트윈 · ${twinStatus()}` })}
${row({ go: 'friends', title: '나의 친구', sub: `친구 ${S.friends.length}명${S.requests.length ? ` · 받은 요청 ${S.requests.length}개` : ''}` })}
${row({ go: 'settings', title: '설정', sub: '프로필 · 알림 · 계정 관리' })}
</div>
${items.length ? issueShelf(m.name, ME, items, view, ME, { color: m.color, styles: [m.face, 'plain', 'neck', 'behind', 'detail', 'mono'] }) : ''}
</div></div>
</div>`,
    capsule: 'me',
  };
};

// A4 내 표지의 반응 (P18: counts only for the publisher)
SCREENS.reactions = () => page({
  eyebrow: 'MY ISSUE / REACTIONS',
  title: '내 표지의 반응',
  lead: '좋아요 수와 반응 목록은 나에게만 보여요.',
  body: `<div style="display:flex;align-items:baseline;gap:10px;margin:22px 0 6px"><span class="serif" style="font-size:64px;line-height:1">${MY_COUNTS.likes}</span><span style="font-size:15px;font-weight:600">좋아요</span><span class="mono" style="margin-left:auto;font-size:11px;color:var(--muted)">Nº ${pad3(S.me.issues)}</span></div>
<p class="note">독자 한 줄 ${MY_COUNTS.lines} · 스크랩 ${MY_COUNTS.scraps} · 오늘 읽은 사람 ${MY_COUNTS.readers}</p>
<div class="rows" style="margin-top:12px">${LIKERS.map((k) => `<div class="row" style="min-height:58px">${avatar(k, 36)}<span class="t"><b>${k}</b><span>나의 표지를 좋아해요</span></span>${paintImg(PEOPLE[k].color, 40)}</div>`).join('')}</div>
<p class="note" style="margin-top:16px">다른 사람에게는 좋아요 수가 표시되지 않아요.</p>`,
  bottom: '<button type="button" class="btn line" data-tab="me">내 잡지로</button>',
});

// C6 오늘 호 만들기 → 발행 (P04: one issue a day; P11: the face cover is placed before publishing)
SCREENS.make = () => {
  const m = S.me;
  if (S.published) {
    return {
      html: page({
        eyebrow: 'TODAY / PUBLISHED',
        title: '오늘 호는 이미 발행했어요',
        lead: `하루에 한 호만 발행할 수 있어요. 내일 새 색으로 만나요.`,
        body: `<div style="display:flex;justify-content:center;margin-top:24px">${mini({ key: ME, w: 200, h: 296, mast: m.name, mastColor: m.mast === 'white' ? WHITE : INK, name: '', style: m.face, color: m.color, fs: mastSize(m.name, 200, 100), go: `spread:${ME}` })}</div>`,
        bottom: `<button type="button" class="btn" data-go="spread:${ME}">오늘 호 보기</button>`,
      }),
    };
  }
  const W = 236;
  const H = 350;
  const faces = [['plain', '그대로'], ['paint', '물감'], ['behind', '제호 뒤'], ['neck', '목 아래']];
  return {
    html: `<div class="scr">
<div class="top-gap"></div>
<header class="hd" style="padding-right:18px">${backBtn('닫기', 'x')}<h1 style="margin:0;font-size:16px;font-weight:600">오늘 호 만들기</h1><span class="serif it" style="font-size:18px"><span class="roll" id="roll"><span><span>Nº ${pad3(m.issues + 1)}</span><span>발행</span></span></span></span></header>
<div class="scroll" id="scroller"><div style="display:flex;flex-direction:column;align-items:center;padding:6px 20px 20px">
<div id="mk-cover" style="position:relative;width:${W}px;height:${H}px;overflow:hidden;background:var(--photo);color:${m.mast === 'white' ? WHITE : INK};box-shadow:0 14px 36px rgba(41,42,39,.2)">
${face(ME, W, H, m.face, { zoom: 1.9, ty: 0.17, color: m.color })}
<span class="shade" style="top:0;height:45%;background:linear-gradient(rgba(0,0,0,.4),rgba(0,0,0,0))"></span>
<span class="mono" aria-hidden="true" style="position:absolute;left:10px;right:10px;top:8px;display:flex;justify-content:space-between;font-size:8px;letter-spacing:.06em;color:${WHITE}"><span>ESEL</span><span>Nº ${pad3(m.issues + 1)} · 9. 6.</span></span>
<span class="serif" aria-hidden="true" style="position:absolute;left:0;right:0;top:18px;text-align:center;font-size:${mastSize(m.name, W, 128)}px;line-height:.9;letter-spacing:-.05em;padding-right:6px;white-space:nowrap">${esc(m.name)}</span>
<span class="shade" style="bottom:0;height:40%;background:linear-gradient(rgba(0,0,0,0),rgba(0,0,0,.5))"></span>
<span style="position:absolute;left:14px;right:14px;bottom:14px;color:${WHITE};font-size:12px;font-weight:500">${esc(m.caption)}</span>
</div>
<div style="align-self:stretch;margin-top:18px;display:flex;flex-direction:column">
<span style="font-size:12px;color:var(--muted)">얼굴</span>
<div class="seg" role="group" aria-label="얼굴 연출" style="margin-top:2px">${faces.map(([k, l]) => `<button type="button" data-act="face:${k}" aria-pressed="${m.face === k}"><span>${l}</span></button>`).join('')}</div>
<div style="display:flex;align-items:center;gap:6px;margin-top:10px"><span style="font-size:14px;margin-right:6px">제호 색</span><div class="seg" role="group" aria-label="제호 색" style="width:140px">${[['ink', '먹'], ['white', '흰']].map(([k, l]) => `<button type="button" data-act="mast:${k}" aria-pressed="${m.mast === k}"><span>${l}</span></button>`).join('')}</div><span style="margin-left:auto;display:flex;align-items:center;gap:4px;font-size:14px">${paintImg(m.color, 52)}<span>${cname(m.color)}</span></span></div>
<div class="field" style="margin-top:12px"><label for="cover-line">표지 문구</label><input id="cover-line" type="text" maxlength="40" value="${esc(m.caption)}" data-in="caption"></div>
</div>
</div></div>
<div class="bottom-bar"><button type="button" class="btn" data-act="publish">발행</button></div>
</div>`,
  };
};

// ───────── 월간 색 기록 R1–R5 (P06·P07: restore only past empty days this month, two a month, never counts as a post)
const MONTH_START_DOW = 2; // 2026-09-01 is a Tuesday
const TODAY = 6;
const DOW = ['일', '월', '화', '수', '목', '금', '토'];
function dayRecord(d) {
  if (d === TODAY && S.published) return { c: S.me.color, k: 'posted', no: S.me.issues };
  return S.record[d];
}
SCREENS.record = () => {
  const cells = [];
  for (let i = 0; i < MONTH_START_DOW; i++) cells.push('<span></span>');
  let posted = 0;
  let restored = 0;
  for (let d = 1; d <= 30; d++) {
    const r = dayRecord(d);
    if (r?.k === 'posted') posted++;
    if (r?.k === 'restored') restored++;
    const n = `<span class="n">${pad2(d)}</span>`;
    if (d > TODAY) cells.push(`<span class="day future">${n}<span class="mark"></span></span>`);
    else if (r?.k === 'posted') cells.push(`<button type="button" class="day${d === TODAY ? ' today' : ''}" data-go="day:${d}" aria-label="9월 ${d}일 · ${cname(r.c)} · 사진 기록">${n}<span class="mark">${paintImg(r.c, 40)}</span></button>`);
    else if (r?.k === 'restored') cells.push(`<button type="button" class="day" data-go="day:${d}" aria-label="9월 ${d}일 · ${cname(r.c)} · 색 복원">${n}<span class="mark"><span class="ring" style="border-color:${PAINT[r.c].hex}"></span></span></button>`);
    else if (d === TODAY) cells.push(`<button type="button" class="day today" data-tab="make" aria-label="오늘 · 아직 발행 전">${n}<span class="mark"><span class="empty"></span></span></button>`);
    else cells.push(`<button type="button" class="day" data-go="restore:${d}" aria-label="9월 ${d}일 · 빈 날 · 색 복원하기">${n}<span class="mark"><span class="empty"></span></span></button>`);
  }
  return {
    html: page({
      eyebrow: 'COLOR ARCHIVE / 2026',
      title: '9월의 색 기록',
      lead: '사진으로 남긴 날과 색만 복원한 날을 구분해요.',
      body: `<div class="cal" style="margin-top:20px">${DOW.map((w) => `<span class="dow">${w}</span>`).join('')}${cells.join('')}</div>
<div style="display:flex;flex-wrap:wrap;gap:6px 16px;margin-top:16px;font-size:13px"><span style="display:flex;align-items:center;gap:6px">${paintImg('camel', 28)}사진 기록 ${posted}일</span><span style="display:flex;align-items:center;gap:6px"><span class="ring" style="display:inline-block;width:14px;height:14px;border-radius:50%;border:2px solid var(--muted)"></span>색 복원 ${restored}일</span><span class="muted" style="margin-left:auto">복원 기회 ${S.credits}번 남음</span></div>
<hr class="rule" style="margin:16px 0">
<p class="note">빈 날짜를 눌러 놓친 색을 복원할 수 있어요. 복원한 색은 사진 게시나 가판대 공개에 포함되지 않아요.</p>`,
      bottom: S.published ? `<button type="button" class="btn" data-go="day:${TODAY}">9월 ${TODAY}일 기록 보기</button>` : '<button type="button" class="btn" data-tab="make">오늘 호 만들기</button>',
    }),
  };
};
SCREENS.day = (d) => {
  d = +d;
  const r = dayRecord(d);
  if (!r) return { redirect: { name: 'record' } };
  const dow = DOW[(MONTH_START_DOW + d - 1) % 7];
  const restored = r.k === 'restored';
  const styles = ['paint', 'plain', 'neck', 'behind', 'detail'];
  return {
    html: page({
      eyebrow: `COLOR ARCHIVE / ${pad2(d)} SEP`,
      title: `${cname(r.c)}, 나의 ${dow}요일`,
      lead: `2026.09.${pad2(d)} / ${restored ? '사진 없이 색만 복원한 기록' : '사진으로 남긴 색'}`,
      body: restored
        ? `<div class="card" style="margin-top:22px;display:flex;flex-direction:column;align-items:center;gap:12px;padding:30px 18px"><span style="width:96px;height:96px;border-radius:50%;box-sizing:border-box;border:6px solid ${PAINT[r.c].hex}"></span><span class="serif" style="font-size:22px">${cname(r.c)}</span><p class="note" style="text-align:center">사진 없이도 기억하는 색.<br>이 기록은 나만 볼 수 있어요.</p></div>`
        : `<p class="mono" style="margin:18px 0 10px;font-size:12px;letter-spacing:.06em">Nº ${pad3(r.no)}  /  ${PAINT[r.c].en.toUpperCase()}</p>
<div style="display:flex;justify-content:center">${mini({ key: ME, w: 236, h: 350, mast: meName(), mastColor: WHITE, name: '', style: d === TODAY ? S.me.face : styles[d % styles.length], color: r.c, fs: mastSize(meName(), 236, 120), go: `spread:${ME}` })}</div>
<p class="serif" style="margin:16px 0 0;font-size:20px;line-height:1.4;text-align:center">${esc(d === TODAY ? S.me.caption : '가벼운 코트와 느린 산책.')}</p>`,
      bottom: restored
        ? '<button type="button" class="btn line" data-back>월간 색 기록으로</button>'
        : `<button type="button" class="btn" data-go="spread:${ME}">내 표지 보기</button><button type="button" class="btn line" data-act="share:${ME}">기록 공유하기</button>`,
    }),
  };
};
SCREENS.restore = (d) => {
  d = +d;
  const choices = RESTORE_CHOICES[d] || TODAY_COLORS;
  const pick = S.restorePick[d] || choices[0];
  const can = S.credits > 0;
  return {
    html: page({
      eyebrow: 'COLOR ARCHIVE / RESTORE',
      title: '놓친 날의 색',
      lead: `9월 ${d}일 · 사진 없이 색만 기록해요.`,
      body: `<p style="margin:22px 0 10px;font-size:15px;font-weight:600">그날 입었던 색을 골라 주세요.</p>
<div role="group" aria-label="그날의 색" style="display:flex;flex-direction:column;gap:10px">${choices.map((c) => `<button type="button" class="pick" data-act="restorepick:${d}:${c}" aria-pressed="${pick === c}">${paintImg(c, 110)}<span class="nm"><b>${cname(c)}</b><i>${PAINT[c].en}</i></span><span class="ck">${icon('check', 16, 2.2)}</span></button>`).join('')}</div>
<p class="note" style="margin-top:16px">색 기록만 복원돼요. 사진 게시, 오늘 호 발행, 가판대 열람 조건은 바뀌지 않아요.</p>
${can ? '' : '<p class="note" style="color:var(--err);margin-top:8px">이번 달의 복원 기회를 모두 사용했어요.</p>'}`,
      bottom: `<button type="button" class="btn" data-act="restore:${d}" ${can ? '' : 'disabled'}>${ro(cname(pick))} 복원하기</button>`,
    }),
  };
};
SCREENS.restored = (d) => {
  const r = S.record[+d];
  return {
    html: page({
      eyebrow: 'COLOR ARCHIVE / RESTORED',
      title: '한 칸을 채웠어요',
      lead: `9월 ${d}일 · ${cname(r.c)} · 색만 복원한 기록`,
      body: `<div style="display:flex;flex-direction:column;align-items:center;gap:14px;margin-top:40px"><span style="width:120px;height:120px;border-radius:50%;box-sizing:border-box;border:8px solid ${PAINT[r.c].hex}"></span><p class="serif" style="margin:6px 0 0;font-size:22px">사진 없이도 기억하는 색.</p><p class="note" style="text-align:center">달력에서는 테두리 원으로 표시돼요.<br>이 기록은 나만 볼 수 있어요.</p></div>`,
      bottom: '<button type="button" class="btn" data-act="to-record">월간 색 기록으로</button>',
    }),
  };
};

// ───────── 친구 F1–F3
SCREENS.friends = () => page({
  eyebrow: `FRIENDS / ${pad2(S.friends.length)}`,
  title: '나의 친구',
  lead: '취향이 닮은 사람들과 기록을 이어가요.',
  body: `<div class="rows" style="margin-top:16px">${S.friends.map((k) => row({ go: `shelf:${k}`, title: k, sub: k === 'dana' ? '친구 · 트윈 2회' : k === 'ama' ? '친구 · 오늘의 표지 발행' : '새 친구', lead: avatar(k, 44) })).join('')}</div>
${S.requests.length ? `<button type="button" class="card" data-go="friend:${S.requests[0]}" style="margin-top:18px;width:100%;display:flex;align-items:center;gap:12px;text-align:left">${avatar(S.requests[0], 44)}<span style="display:flex;flex-direction:column;gap:3px;flex:1"><b style="font-size:15px">친구 요청 ${S.requests.length}</b><span style="font-size:13px;color:var(--muted)">${S.requests[0]}님의 요청이 도착했어요</span></span>${icon('right', 20)}</button>` : ''}
<form id="find" style="margin-top:22px" autocomplete="off"><div class="field"><label for="find-id">아이디로 친구 찾기</label><input id="find-id" type="text" placeholder="@zuri" autocapitalize="none" spellcheck="false"></div><p class="hint" id="find-hint" style="margin:8px 0 0;font-size:13px;color:var(--muted)">영문 아이디를 적어 주세요.</p><button type="submit" class="btn line" style="margin-top:12px">친구 프로필 확인</button></form>`,
});
SCREENS.friend = (k = 'zuri') => {
  const isFriend = S.friends.includes(k);
  return {
    html: page({
      eyebrow: 'FRIENDS / REQUEST',
      title: isFriend ? `${k}, 나의 친구` : `새로운 친구, ${k}`,
      lead: '친구가 되면 트윈에 초대할 수 있어요.',
      body: `<div style="display:flex;justify-content:center;margin-top:24px">${mini({ key: k, w: 200, h: 290, mast: k, mastColor: WHITE, name: '', style: FACE[k] || 'plain', py: 0.3, fs: mastSize(k, 200, 96), go: `shelf:${k}` })}</div>
<p class="serif" style="margin:16px 0 0;text-align:center;font-size:20px">${k === 'zuri' ? '색으로 기록하는 작은 일상.' : esc(PEOPLE[k].cap)}</p>
<p class="note" style="text-align:center;margin-top:6px">${cname(PEOPLE[k].color)} · ${ISSUES[k] || 12}호 발행</p>`,
      bottom: isFriend ? '<button type="button" class="btn line" data-back>친구 목록으로</button>' : `<button type="button" class="btn" data-act="accept:${k}">친구 요청 수락</button><button type="button" class="btn text" data-act="later:${k}">나중에</button>`,
    }),
  };
};
SCREENS['friend-added'] = (k = 'zuri') => page({
  eyebrow: 'FRIENDS / ADDED',
  title: '친구가 되었어요',
  lead: `${k}와 새로운 기록을 시작해 보세요.`,
  body: `<div style="display:flex;align-items:center;justify-content:center;gap:14px;margin-top:36px">${avatar(ME, 88)}<span class="serif it" style="font-size:28px">×</span>${avatar(k, 88)}</div><p class="serif" style="text-align:center;margin:14px 0 0;font-size:22px">${esc(meName())} × ${k}</p><p class="note" style="text-align:center;margin-top:8px">친구 목록에 ${k}${jong(k) ? '이' : '가'} 추가됐어요.</p>`,
  bottom: '<button type="button" class="btn" data-go="twin">트윈 홈으로</button><button type="button" class="btn text" data-act="to-friends">친구 목록으로</button>',
});

// ───────── 트윈 T1–T10 (P08–P10: one shared candidate, independent choice, both post before reveal, joint needs both)
const TWIN_FRIEND_COLORS = ['camel', 'powder', 'butter'];
function twinStatus() {
  return { invited: '수락 대기', paired: '색 고르는 중', ready: '내 표지 준비', posted: '상대 게시 대기', both: '두 표지 도착', consent: '공동 공개 동의 대기', joint: '공동 공개 준비', published: '공동 발행 완료', private: '둘만 보관', solo: '내 표지만 공개' }[S.twin.step] || '';
}
const twinRoute = () => ({ invited: 'twin-invite', paired: 'twin-color', ready: 'twin-ready', posted: 'twin-wait', both: 'twin-reveal', consent: 'twin-consent', joint: 'twin-joint', published: 'twin-done', private: 'twin-done', solo: 'twin-done' }[S.twin.step]);
function twinPair(w = 150, h = 216, { reveal = true, joint = false } = {}) {
  const mineCover = mini({ key: ME, w, h, mast: meName(), name: '', style: S.me.face, color: S.twin.color, fs: mastSize(meName(), w, 60) });
  const theirs = reveal
    ? mini({ key: S.twin.with, w, h, mast: S.twin.with, name: '', style: FACE[S.twin.with] || 'plain', px: 0.58, py: 0.45, fs: mastSize(S.twin.with, w, 60) })
    : `<span class="ph" style="width:${w}px;height:${h}px;display:flex;align-items:center;justify-content:center;background:repeating-linear-gradient(135deg,#ECECEF 0 8px,#F4F4F6 8px 16px);box-shadow:0 4px 12px rgba(41,42,39,.16)"><span style="display:flex;flex-direction:column;align-items:center;gap:6px;color:var(--muted);font-size:13px">${icon('lock', 20, 1.8)}준비 중</span></span>`;
  if (joint) return `<div style="display:flex;justify-content:center"><div style="position:relative;display:flex;box-shadow:0 14px 36px rgba(41,42,39,.2)">${face(ME, w, h * 1.1, S.me.face, { color: S.twin.color })}${face(S.twin.with, w, h * 1.1, 'plain', { px: 0.58, py: 0.45 })}<span class="shade" style="top:0;height:40%;background:linear-gradient(rgba(0,0,0,.4),rgba(0,0,0,0))"></span><span class="serif" aria-hidden="true" style="position:absolute;left:0;right:0;top:10px;text-align:center;color:${WHITE};font-size:${mastSize(`${meName()}×${S.twin.with}`, w * 2, 64)}px;line-height:.9;letter-spacing:-.04em;white-space:nowrap">${esc(meName())}×${S.twin.with}</span><span class="mono" style="position:absolute;left:12px;bottom:10px;color:${WHITE};font-size:10px;letter-spacing:.08em">TWIN Nº ${pad3(S.twin.no)}</span></div></div>`;
  return `<div style="display:flex;justify-content:center;gap:12px">${mineCover}${theirs}</div>`;
}
SCREENS.twin = () => page({
  eyebrow: 'TWIN ISSUE / FRIENDS',
  title: '둘이 만드는 오늘 호',
  lead: '친구와 같은 날, 각자의 색으로 표지를 남겨요.',
  body: `<div style="margin-top:22px">${twinPair(140, 202)}</div>
<p class="serif" style="text-align:center;margin:14px 0 0;font-size:20px">${esc(meName())} × ${S.twin.with}</p>
<p class="note" style="text-align:center;margin-top:6px">함께 고를 수 있는 공통 색 하나. 서로 다른 색을 골라도 트윈이 될 수 있어요.</p>
${S.twin.step !== 'none' ? `<button type="button" class="card" data-go="${twinRoute()}" style="margin-top:18px;width:100%;display:flex;align-items:center;gap:12px;text-align:left"><span style="display:flex;flex-direction:column;gap:3px;flex:1"><b style="font-size:15px">${S.twin.with}와의 트윈</b><span style="font-size:13px;color:var(--muted)">${twinStatus()}</span></span>${icon('right', 20)}</button>` : ''}
<div class="rows" style="margin-top:14px">
${S.twin.step === 'none' ? S.friends.map((k) => row({ act: `twin-invite:${k}`, title: `${k}와 트윈 하기`, sub: '초대를 보내고 각자 오늘 호를 만들어요', lead: avatar(k, 40) })).join('') : ''}
${row({ go: 'friends', title: '친구 목록 · 요청', sub: `내 친구 ${S.friends.length}명${S.requests.length ? ` · 받은 요청 ${S.requests.length}개` : ''}` })}
</div>`,
  bottom: '<button type="button" class="btn line" data-act="invite-link">' + icon('link', 18) + '친구 초대 링크 만들기</button>',
});
SCREENS['twin-invite'] = () => page({
  eyebrow: 'TWIN ISSUE / INVITATION',
  title: `${S.twin.with}와 함께할까요?`,
  lead: '상대방이 수락하면 시작돼요.',
  body: `<div class="card" style="margin-top:22px;display:flex;flex-direction:column;gap:10px"><span class="mono" style="font-size:11px;letter-spacing:.08em;color:var(--muted)">오늘의 트윈 초대</span><div style="display:flex;align-items:center;gap:10px">${avatar(ME, 40)}<span class="serif it" style="font-size:22px">×</span>${avatar(S.twin.with, 40)}<span style="font-size:15px;font-weight:600;margin-left:4px">${esc(meName())} × ${S.twin.with}</span></div><p class="note" style="margin:0">각자 색을 고르고 오늘의 사진을 올려요. 두 사람 모두 게시한 뒤 서로의 표지가 열려요.</p></div>
<p class="note" style="margin-top:16px">${S.twin.with}에게 초대를 보냈어요. 실제 앱에서는 ${S.twin.with}${jong(S.twin.with) ? '이' : '가'} 수락하면 알림이 와요.</p>`,
  bottom: `<button type="button" class="demo" data-act="twin-accept"><b>시연</b>${S.twin.with}${jong(S.twin.with) ? '이' : '가'} 수락한 상태로 보기</button><button type="button" class="btn text" data-act="twin-cancel">초대 취소</button>`,
});
SCREENS['twin-color'] = () => {
  const mine = TODAY_COLORS;
  const shared = mine.filter((c) => TWIN_FRIEND_COLORS.includes(c));
  return {
    html: page({
      eyebrow: 'TWIN ISSUE / 01',
      title: '나의 색 고르기',
      lead: '각자 후보 3개 중 하나를 선택해요.',
      body: `<div role="group" aria-label="나의 색" style="display:flex;flex-direction:column;gap:10px;margin-top:20px">${mine.map((c) => `<button type="button" class="pick" data-act="twinpick:${c}" aria-pressed="${S.twin.color === c}">${paintImg(c, 110)}<span class="nm"><b>${cname(c)}</b><i>${PAINT[c].en}${shared.includes(c) ? ' · 공통 색' : ''}</i></span><span class="ck">${icon('check', 16, 2.2)}</span></button>`).join('')}</div>
<div class="card" style="margin-top:16px;display:flex;flex-direction:column;gap:6px"><span class="mono" style="font-size:11px;letter-spacing:.08em">우리의 공통 색 / ${shared.map((c) => cname(c)).join(' · ')}</span><p class="note" style="margin:0">${S.twin.with}의 후보: ${TWIN_FRIEND_COLORS.map(cname).join(' · ')}<br>겹치는 색은 ${shared.map(cname).join(' · ')} 하나예요. 같은 색을 고를지는 각자의 선택이에요.</p></div>`,
      bottom: `<button type="button" class="btn" data-act="twin-ready">${ro(cname(S.twin.color))} 트윈 표지 만들기</button>`,
    }),
  };
};
SCREENS['twin-ready'] = () => page({
  eyebrow: 'TWIN ISSUE / 02',
  title: '나의 표지 준비',
  lead: `${cname(S.twin.color)} · 상대의 사진은 아직 보이지 않아요.`,
  body: `<div style="display:flex;justify-content:center;margin-top:22px">${mini({ key: ME, w: 220, h: 320, mast: meName(), name: '', style: S.me.face, color: S.twin.color, fs: mastSize(meName(), 220, 110) })}</div>
<p class="mono" style="text-align:center;margin:12px 0 0;font-size:12px;letter-spacing:.06em">${esc(meName())} / TWIN Nº ${pad3(S.twin.no)}</p>
<p class="note" style="margin-top:14px">이 사진은 트윈 보관함에 먼저 저장돼요. 공개 범위는 두 표지가 열린 뒤 정할 수 있어요. 트윈 게시는 내 오늘 호와 따로 세고, 같은 색 잠금도 풀지 않아요.</p>`,
  bottom: '<button type="button" class="btn" data-act="twin-post">내 표지 게시하기</button>',
});
SCREENS['twin-wait'] = () => page({
  eyebrow: 'TWIN ISSUE / WAITING',
  title: '한 사람의 표지가 더 필요해요',
  lead: `내 표지는 준비됐어요. ${S.twin.with}의 게시를 기다려요.`,
  body: `<div style="margin-top:22px">${twinPair(140, 202, { reveal: false })}</div>
<div class="rows" style="margin-top:16px"><div class="row" style="min-height:52px"><span class="t"><b>${esc(meName())}</b></span><span style="display:flex;align-items:center;gap:4px;font-size:14px;font-weight:600">${icon('check', 18, 2)}게시 완료</span></div><div class="row" style="min-height:52px"><span class="t"><b>${S.twin.with}</b></span><span class="muted" style="font-size:14px">준비 중</span></div></div>
<p class="note" style="margin-top:14px">기다리는 동안 상대의 사진은 가려져 있어요. 완료되면 알림으로 알려드릴게요.</p>`,
  bottom: `<button type="button" class="demo" data-act="twin-arrive"><b>시연</b>${S.twin.with}의 게시가 도착한 상태로 보기</button><button type="button" class="btn line" data-tab="me">내 잡지로 돌아가기</button>`,
});
SCREENS['twin-reveal'] = () => page({
  eyebrow: 'TWIN ISSUE / REVEAL',
  title: '같은 날, 다른 우리',
  lead: '두 사람의 표지가 모두 도착했어요.',
  body: `<div class="rise" style="margin-top:22px">${twinPair(150, 216)}</div>
<p class="mono" style="text-align:center;margin:14px 0 0;font-size:12px;letter-spacing:.08em">${PAINT[S.twin.color].en.toUpperCase()}  /  ${PAINT.powder.en.toUpperCase()}</p>
<p class="note" style="text-align:center;margin-top:10px">함께한 하루는 아직 두 사람만 볼 수 있어요.</p>`,
  bottom: '<button type="button" class="btn" data-go="twin-vis">공개 범위 정하기</button>',
});
SCREENS['twin-vis'] = () => page({
  eyebrow: 'TWIN ISSUE / VISIBILITY',
  title: '어디까지 보여줄까요?',
  lead: '공동 표지는 두 사람 모두 동의해야 공개돼요.',
  body: `<div class="rows" style="margin-top:16px">
${row({ act: 'twinvis:private', title: '우리끼리 보관', sub: '두 사람만 보는 트윈 기록' })}
${row({ act: 'twinvis:solo', title: '내 표지만 공개', sub: '내 잡지에 내 사진만 공개' })}
${row({ act: 'twinvis:joint', title: '공동 표지 공개 요청', sub: '두 사진을 한 호로 공개 · 상대 동의 필요' })}
</div>
<p class="note" style="margin-top:16px">공개 전에는 언제든 돌아갈 수 있어요. 상대방의 사진을 혼자 공개할 수 없어요.</p>`,
});
SCREENS['twin-consent'] = () => page({
  eyebrow: 'TWIN ISSUE / CONSENT',
  title: '공동 공개 동의 대기',
  lead: `${esc(meName())} 동의 완료 · ${S.twin.with}의 동의를 기다려요.`,
  body: `<div style="margin-top:22px">${twinPair(140, 202)}</div><p class="note" style="text-align:center;margin-top:14px">아직 공동 표지는 공개되지 않았어요.</p>`,
  bottom: `<button type="button" class="demo" data-act="twin-agree"><b>시연</b>${S.twin.with}${jong(S.twin.with) ? '이' : '가'} 동의한 상태로 보기</button><button type="button" class="btn line" data-tab="me">내 잡지로</button>`,
});
SCREENS['twin-joint'] = () => page({
  eyebrow: 'TWIN ISSUE / READY',
  title: '우리의 한 호',
  lead: '두 사람 모두 공동 공개에 동의했어요.',
  body: `<div style="margin-top:22px">${twinPair(150, 216, { joint: true })}</div>`,
  bottom: '<button type="button" class="btn" data-act="twin-publish">공동 표지 발행하기</button>',
});
SCREENS['twin-done'] = () => {
  const v = S.twin.step;
  const copy = {
    published: ['TWIN ISSUE / PUBLISHED', '함께한 오늘, 발행 완료', '공동 표지가 공개됐어요.'],
    private: ['TWIN ISSUE / SAVED', '둘만의 기록으로', '트윈 보관함에 비공개로 저장했어요.'],
    solo: ['TWIN ISSUE / SAVED', '내 표지만 공개했어요', '상대방의 사진은 공개되지 않아요.'],
  }[v];
  if (!copy) return { redirect: { name: 'twin' } };
  return {
    html: page({
      eyebrow: copy[0],
      title: copy[1],
      lead: copy[2],
      body: `<div class="rise" style="margin-top:22px">${v === 'published' ? twinPair(150, 216, { joint: true }) : v === 'solo' ? `<div style="display:flex;justify-content:center">${mini({ key: ME, w: 200, h: 290, mast: meName(), name: '', style: S.me.face, color: S.twin.color, fs: mastSize(meName(), 200, 100) })}</div>` : twinPair(140, 202)}</div>
${v === 'published' ? `<p class="mono" style="text-align:center;margin:14px 0 0;font-size:12px;letter-spacing:.08em">TWIN Nº ${pad3(S.twin.no)}  /  ${esc(meName()).toUpperCase()} × ${S.twin.with.toUpperCase()}</p>` : ''}`,
      bottom: `${v === 'published' ? `<button type="button" class="btn" data-act="share:twin">${icon('share', 18)}공동 표지 공유하기</button>` : ''}<button type="button" class="btn line" data-tab="me">내 잡지로</button>`,
    }),
  };
};

// ───────── 설정 S1–S6
SCREENS.settings = () => page({
  eyebrow: 'PREFERENCES',
  title: '나의 설정',
  lead: '잡지를 가꾸는 가장 간단한 방법.',
  body: `<div class="rows" style="margin-top:16px">
${row({ go: 'profile', title: '프로필 편집', sub: '이름과 소개를 바꿔요' })}
${row({ go: 'notifications', title: '알림 설정', sub: S.notif.on ? '내가 받고 싶은 소식만' : '알림이 꺼져 있어요' })}
${row({ go: 'account', title: '계정 관리', sub: '이메일 · 로그아웃 · 계정 탈퇴' })}
</div>
<p class="mono" style="margin:40px 0 0;font-size:11px;letter-spacing:.08em;color:var(--muted)">Esel / PERSONAL STYLE JOURNAL</p>
<button type="button" class="demo" data-jump="reset" style="margin-top:12px"><b>시연</b>목업을 처음부터 다시 보기</button>`,
});
SCREENS.profile = () => {
  const m = S.me;
  return {
    html: page({
      eyebrow: 'PREFERENCES / PROFILE',
      title: '프로필 편집',
      lead: '나의 잡지에 보여줄 이름과 소개를 정해요.',
      body: `<form id="profile" style="display:flex;flex-direction:column;gap:22px;margin-top:22px" autocomplete="off">
<div class="field"><label for="pf-name">이름 · 표지 제호가 돼요</label><input id="pf-name" class="big" type="text" value="${esc(m.name)}" maxlength="10" autocapitalize="none" spellcheck="false" data-in="pf-name"><p class="hint" id="pf-name-hint">영문 소문자 2~10자</p></div>
<div class="field"><label for="pf-bio">소개</label><textarea id="pf-bio" maxlength="80" data-in="pf-bio">${esc(m.bio)}</textarea><p class="hint" id="pf-bio-hint">${m.bio.length} / 80</p></div>
</form>`,
      bottom: '<button type="button" class="btn" data-act="save-profile" id="pf-save">변경 내용 저장</button>',
    }),
  };
};
SCREENS.notifications = () => {
  const n = S.notif;
  const sw = (key, title, sub, disabled = false) => `<button type="button" class="row" role="switch" aria-checked="${n[key]}" data-act="notif:${key}" ${disabled ? 'disabled style="opacity:.4"' : ''}><span class="t"><b>${title}</b>${sub ? `<span>${sub}</span>` : ''}</span><span class="switch" aria-hidden="true"></span></button>`;
  return {
    html: page({
      eyebrow: 'PREFERENCES / NOTIFICATIONS',
      title: '알림 설정',
      lead: '필요한 소식만 가볍게 받아 보세요.',
      body: `<div class="rows" style="margin-top:16px">${sw('on', '알림 받기', n.on ? '켜짐' : '꺼짐')}</div>
<p class="eyebrow" style="margin-top:22px">받을 소식</p>
<div class="rows">${sw('twin', '트윈 초대와 게시 완료', '', !n.on)}${sw('likes', '좋아요와 새로운 구독', '', !n.on)}${sw('remind', '오늘의 색 기록 리마인더', '', !n.on)}</div>
<p class="note" style="margin-top:14px">${n.on ? '위 소식을 푸시 알림으로 받아요.' : '모든 푸시 알림이 꺼져 있어요. 앱 안의 기록은 그대로 남아 있어요.'}</p>`,
    }),
  };
};
SCREENS.account = () => page({
  eyebrow: 'PREFERENCES / ACCOUNT',
  title: '계정 관리',
  lead: '계정 정보와 로그인 상태를 관리해요.',
  body: `<div class="rows" style="margin-top:16px">
<div class="row"><span class="t"><b>연결된 이메일</b><span>${esc(S.me.email)}</span></span></div>
${row({ go: 'logout', title: '로그아웃', sub: '기록은 계정에 그대로 보관돼요' })}
${row({ go: 'delete', title: '계정 탈퇴', sub: '삭제되는 내용을 먼저 확인해 주세요' })}
</div>`,
});
SCREENS.logout = () => page({
  eyebrow: 'ACCOUNT / SIGN OUT',
  title: '로그아웃할까요?',
  lead: '다시 로그인하면 나의 잡지를 이어 볼 수 있어요.',
  body: '<p class="note" style="margin-top:20px">이 기기의 로그인 상태만 해제돼요. 표지, 색 기록, 트윈 기록은 삭제되지 않아요.</p>',
  bottom: '<button type="button" class="btn" data-act="logout">로그아웃</button><button type="button" class="btn text" data-back>계속 머무르기</button>',
});
SCREENS.delete = () => {
  const ok = !!S.deleteChecked;
  return {
    html: page({
      eyebrow: 'ACCOUNT / DELETE',
      title: '계정을 떠나기 전에',
      lead: '삭제되는 기록을 확인해 주세요.',
      body: `<div class="card" style="margin-top:20px;display:flex;flex-direction:column;gap:8px"><b style="font-size:15px">삭제되는 것</b><p class="note" style="margin:0">내 표지와 사진<br>월간 색 기록<br>프로필과 계정 정보</p></div>
<p class="note" style="margin-top:14px">삭제 후에는 되돌릴 수 없어요. 공동 트윈의 상대방 기록 처리 범위는 서비스 탈퇴 정책에서 확인해 주세요.</p>
<button type="button" class="row" role="checkbox" aria-checked="${ok}" data-act="delete-check" style="margin-top:10px"><span class="check" aria-hidden="true">${icon('check', 16, 2.4)}</span><span class="t"><b>삭제 내용을 확인했어요</b></span></button>`,
      bottom: `<button type="button" class="btn" data-go="delete-final" ${ok ? '' : 'disabled'}>확인 후 마지막 단계로</button><button type="button" class="btn text" data-act="keep-account">계정 유지하기</button>`,
    }),
  };
};
SCREENS['delete-final'] = () => page({
  eyebrow: 'ACCOUNT / FINAL CHECK',
  title: '정말 탈퇴할까요?',
  lead: '삭제 내용 확인 완료 · 마지막 확인 단계',
  body: '<p class="note" style="margin-top:20px">내 계정과 개인 기록을 삭제합니다. 이 작업은 되돌릴 수 없어요.</p>',
  bottom: '<button type="button" class="btn danger" data-act="delete-account">계정 영구 삭제</button><button type="button" class="btn text" data-back>취소하고 돌아가기</button>',
});
SCREENS.goodbye = (kind = 'out') => ({
  html: `<div class="scr" style="justify-content:center;align-items:center;text-align:center;padding:0 28px">
<p class="eyebrow">ESEL / ACCOUNT</p>
<h1 class="h1">${kind === 'deleted' ? '탈퇴가 완료됐어요' : '로그아웃했어요'}</h1>
<p class="lead">${kind === 'deleted' ? '함께 기록해 주셔서 고마워요.' : '나의 잡지는 안전하게 보관 중이에요.'}</p>
<p class="serif" style="margin:46px 0 0;font-size:120px;line-height:.9;letter-spacing:-.05em">Esel<span style="color:var(--dot)">.</span></p>
<p class="serif it" style="margin:6px 0 0;font-size:20px;color:var(--muted)">Your own little magazine.</p>
<div style="position:absolute;left:20px;right:20px;bottom:calc(var(--sb) + 12px)"><button type="button" class="btn" data-act="${kind === 'deleted' ? 'restart' : 'to-intro'}">${kind === 'deleted' ? '처음 화면으로' : '오늘의 표지 보기'}</button></div>
</div>`,
});

// ───────── 창간 J3–J7
function steps(n) {
  return `<header class="hd" style="padding-right:18px">${backBtn()}<span class="mono" style="font-size:12px;letter-spacing:.06em">창간 ${n} / 4</span></header>
<div aria-hidden="true" style="flex-shrink:0;display:flex;gap:4px;padding:0 20px">${[1, 2, 3, 4].map((i) => `<span style="flex:1 1 0;height:2px;border-radius:1px;background:${i <= n ? INK : '#D8D9D3'}"></span>`).join('')}</div>`;
}
const TAKEN = new Set(Object.keys(PEOPLE).filter((k) => k !== ME));
SCREENS['join-color'] = () => ({
  html: `<div class="scr"><div class="top-gap"></div>${steps(1)}
<div class="scroll" id="scroller"><div class="pad" style="padding-top:26px;padding-bottom:20px">
<p class="mono" style="margin:0;font-size:12px;letter-spacing:.06em;color:var(--muted)">2026. 9. 6. 오늘의 색</p>
<h1 class="serif" style="margin:8px 0 0;font-size:36px;font-weight:400;line-height:1.2">창간호는<br>어떤 색으로 할까요?</h1>
<p class="lead">고른 색의 옷·양말·가방 무엇이든 좋아요. 그 색으로 첫 표지를 찍어요.</p>
<div role="group" aria-label="오늘의 색" style="display:flex;flex-direction:column;gap:10px;margin-top:26px">${TODAY_COLORS.map((c) => `<button type="button" class="pick" data-act="joincolor:${c}" aria-pressed="${S.join.color === c}">${paintImg(c, 120)}<span class="nm"><b>${cname(c)}</b><i>${PAINT[c].en}</i></span><span class="ck">${icon('check', 16, 2.2)}</span></button>`).join('')}</div>
</div></div>
<div class="bottom-bar"><button type="button" class="btn" data-go="join-shoot">${ro(cname(S.join.color))} 찍기</button></div></div>`,
});
SCREENS['join-shoot'] = () => ({
  html: `<div class="scr on-photo" style="background:#111210;color:${WHITE}">
<span style="position:absolute;inset:0">${face(ME, 393, $('#app').clientHeight || 852, 'plain', { alt: '카메라 미리보기: 카멜 코트와 페도라 착장' })}</span>
<div class="shade" style="top:0;height:200px;background:linear-gradient(rgba(0,0,0,.5),rgba(0,0,0,0))"></div>
<div class="shade" style="bottom:0;height:280px;background:linear-gradient(rgba(0,0,0,0),rgba(0,0,0,.65))"></div>
<div class="top-gap" style="position:relative"></div>
<header class="hd" style="position:relative;padding-right:18px">${backBtn()}<span class="mono" style="font-size:12px;letter-spacing:.06em">창간 2 / 4</span></header>
<div style="position:relative;display:flex;justify-content:center;margin-top:10px"><span class="glass" style="height:44px;padding:0 16px 0 8px;border-radius:22px;display:flex;align-items:center;gap:4px;color:${INK};font-size:14px;font-weight:600">${paintImg(S.join.color, 52)}<span>${iga(cname(S.join.color))} 보이게 찍어요</span></span></div>
<span aria-hidden="true" style="position:relative;align-self:center;margin-top:24px;width:325px;flex:1 1 auto;max-height:470px;box-sizing:border-box;border:1.5px solid rgba(255,255,255,.55);border-radius:18px"></span>
<p style="position:relative;margin:18px 0 0;text-align:center;font-size:14px">얼굴은 다음 단계에서 가릴 수 있어요.</p>
<div style="position:relative;display:flex;align-items:center;justify-content:space-around;padding:18px 30px calc(var(--sb) + 18px)">
<button type="button" aria-label="앨범에서 고르기" data-act="album" style="width:52px;height:52px;border-radius:12px;overflow:hidden;box-shadow:0 0 0 2px ${WHITE}">${face('freya', 52, 52, 'plain', { py: 0.4, alt: '' })}</button>
<button type="button" aria-label="촬영" data-act="shutter" style="width:82px;height:82px;border-radius:50%;display:flex;align-items:center;justify-content:center;box-shadow:inset 0 0 0 4px ${WHITE}"><span style="width:66px;height:66px;border-radius:50%;background:${WHITE}"></span></button>
<button type="button" aria-label="카메라 전환" data-act="flip" style="width:52px;height:52px;border-radius:50%;display:flex;align-items:center;justify-content:center;background:rgba(255,255,255,.18)">${icon('flip', 24)}</button>
</div>
</div>`,
});
function nameHint(name) {
  if (name.length < 2) return ['영문 소문자 2~10자로 적어요.', false, false];
  if (TAKEN.has(name)) return ['이미 있는 이름이에요.', true, false];
  return [`${name} — 쓸 수 있는 이름이에요.`, false, true];
}
SCREENS['join-name'] = () => {
  const name = S.join.name;
  const [hint, err, ok] = nameHint(name);
  const W = 260;
  return {
    html: `<div class="scr"><div class="top-gap"></div>${steps(3)}
<div class="scroll" id="scroller"><div class="pad" style="padding-bottom:20px">
<h1 class="serif" style="margin:20px 0 0;font-size:30px;font-weight:400;line-height:1.2">잡지 이름을 정해요</h1>
<div style="position:relative;width:${W}px;height:386px;margin:18px auto 0;overflow:hidden;background:var(--photo);box-shadow:0 14px 36px rgba(41,42,39,.2)">
${face(ME, W, 386, 'plain')}
<span class="shade" style="top:0;height:45%;background:linear-gradient(rgba(0,0,0,.4),rgba(0,0,0,0))"></span>
<span class="mono" aria-hidden="true" style="position:absolute;left:10px;right:10px;top:8px;color:${WHITE};display:flex;justify-content:space-between;font-size:8px;letter-spacing:.06em"><span>ESEL</span><span>Nº 001 · 창간호</span></span>
<span class="serif" id="jn-mast" aria-hidden="true" style="position:absolute;left:0;right:0;top:20px;text-align:center;font-size:${mastSize(name || 'esel', W, 140)}px;line-height:.9;letter-spacing:-.05em;padding-right:4px;white-space:nowrap;color:${WHITE}">${esc(name || 'esel')}</span>
</div>
<div class="field" style="margin-top:18px"><label for="mast-name">영문 닉네임 · 표지 제호가 돼요</label><input id="mast-name" class="big" type="text" value="${esc(name)}" maxlength="10" autocomplete="off" autocapitalize="none" spellcheck="false" data-in="join-name"><p class="hint${err ? ' err' : ''}" id="jn-hint">${esc(hint)}</p></div>
</div></div>
<div class="bottom-bar"><button type="button" class="btn" id="jn-next" data-go="join-face" ${ok ? '' : 'disabled'}>다음</button></div></div>`,
  };
};
SCREENS['join-face'] = () => {
  const f = S.join.face;
  const W = 210;
  const H = 310;
  const cards = [['plain', '그대로', '얼굴을 보여요'], ['paint', '물감 한 획', '오늘의 색으로 가려요'], ['behind', '제호 뒤로', '이름 뒤에 숨겨요'], ['neck', '목 아래', '옷만 보여요']];
  return {
    html: `<div class="scr"><div class="top-gap"></div>${steps(4)}
<div class="scroll" id="scroller"><div class="pad" style="padding-bottom:20px">
<h1 class="serif" style="margin:20px 0 0;font-size:30px;font-weight:400;line-height:1.2">얼굴은 어떻게 할까요?</h1>
<p style="margin:6px 0 0;font-size:14px;color:var(--sub)">호마다 바꿀 수 있어요. 가려도 표지는 똑같이 멋져요.</p>
<div style="position:relative;width:${W}px;height:${H}px;margin:20px auto 0;overflow:hidden;background:var(--photo);color:${WHITE};box-shadow:0 14px 36px rgba(41,42,39,.2)">
${face(ME, W, H, f, { zoom: 1.9, ty: 0.17, color: S.join.color })}
<span class="shade" style="top:0;height:45%;background:linear-gradient(rgba(0,0,0,.4),rgba(0,0,0,0))"></span>
<span class="serif" aria-hidden="true" style="position:absolute;left:0;right:0;top:14px;text-align:center;font-size:${mastSize(S.join.name, W, 110)}px;line-height:.9;letter-spacing:-.05em;padding-right:4px;white-space:nowrap">${esc(S.join.name)}</span>
</div>
<div class="face-cards" role="group" aria-label="얼굴 연출" style="margin-top:18px">${cards.map(([k, t, s]) => `<button type="button" data-act="joinface:${k}" aria-pressed="${f === k}"><b>${t}</b><span>${s}</span></button>`).join('')}</div>
</div></div>
<div class="bottom-bar"><button type="button" class="btn" data-go="join-done">창간하기</button></div></div>`,
  };
};
SCREENS['join-done'] = () => {
  const name = S.join.name;
  const c = S.join.color;
  const H = $('#app').clientHeight || 852;
  return {
    html: `<div class="scr on-photo" style="background:#D9D2C6">
<span style="position:absolute;inset:0">${face(ME, 393, H, S.join.face, { zoom: 1.9, ty: 0.17, color: c })}</span>
<div class="shade" style="top:0;height:340px;background:linear-gradient(rgba(0,0,0,.42),rgba(0,0,0,0))"></div>
<div class="shade" style="bottom:0;height:420px;background:linear-gradient(rgba(0,0,0,0),rgba(0,0,0,.7))"></div>
<div class="mono" style="position:absolute;left:20px;right:20px;top:calc(var(--st) + 4px);display:flex;justify-content:space-between;font-size:12px;letter-spacing:.06em;color:${WHITE}"><span>ESEL</span><span>Nº 001 · 창간호 · 2026. 9. 6.</span></div>
<div class="serif" aria-hidden="true" style="position:absolute;left:0;right:0;top:calc(var(--st) + 30px);text-align:center;font-size:${mastSize(name, 393, 200)}px;line-height:.9;letter-spacing:-.05em;padding-right:10px;color:${WHITE};white-space:nowrap">${esc(name)}</div>
<div style="position:absolute;left:20px;right:20px;bottom:calc(var(--sb) + 12px);color:${WHITE}">
<p class="mono" style="margin:0;font-size:12px;letter-spacing:.06em">창간을 축하해요</p>
<h1 class="serif" style="margin:8px 0 0;font-size:30px;font-weight:400;line-height:1.25">${esc(name)}의 첫 호가<br>오늘 가판대에 올라갔어요.</h1>
<div style="display:flex;align-items:center;gap:8px;margin:12px 0 18px;font-size:14px;font-weight:600">${paintImg(c, 56)}<span>${cname(c)} · 같은 색 ${SAME_COUNT[c] + 1}명과 함께</span></div>
<button type="button" class="btn" data-act="found:feed" style="background:${PAPER};color:${INK}">오늘의 표지 보러 가기</button>
<button type="button" class="btn text" data-act="found:me" style="color:${WHITE}">내 잡지 보기</button>
</div>
</div>`,
  };
};

// ───────── share sheet (A1–A3, A5–A8)
function openShare(kind) {
  let preview;
  let meta;
  let ok = true;
  let path;
  if (kind === 'twin') {
    preview = twinPair(84, 120, { joint: true });
    meta = `${esc(meName())} × ${S.twin.with} / TWIN Nº ${pad3(S.twin.no)}`;
    ok = S.twin.step === 'published';
    path = `twin/${pad3(S.twin.no)}`;
  } else {
    const k = kind;
    const mine = k === ME;
    ok = !mine || S.published;
    preview = `<div style="display:flex;justify-content:center">${mine ? mini({ key: ME, w: 120, h: 174, mast: meName(), name: '', style: S.me.face, color: S.me.color, fs: mastSize(meName(), 120, 56) }) : mini({ key: k, w: 120, h: 174, mast: k, name: '', style: FACE[k] || 'plain', py: 0.3, fs: mastSize(k, 120, 56) })}</div>`;
    meta = `${esc(mine ? meName() : k)} / Nº ${pad3(issueOf(k))} / ${cname(mine ? S.me.color : PEOPLE[k].color)}`;
    path = `${mine ? meName() : k}/${pad3(issueOf(k))}`;
  }
  const url = `https://example.com/esel/${path}`;
  openSheet(`<span class="grab"></span>
<div style="display:flex;align-items:center;justify-content:space-between"><h2>${kind === 'twin' ? '우리의 트윈 공유' : kind === ME ? '이 한 호를 함께' : `${kind}의 표지 공유`}</h2><button type="button" class="icon-btn" data-act="close-sheet" aria-label="닫기" style="margin-right:-12px">${icon('x', 22)}</button></div>
<p class="note" style="margin:0">${ok ? (kind === 'twin' ? '공동 공개에 동의한 표지를 공유해요.' : '공개된 표지의 링크를 공유해요.') : '공개된 표지만 링크로 공유할 수 있어요. 오늘 호를 발행하면 공유할 수 있어요.'}</p>
<div style="padding:8px 0">${preview}</div>
<p class="mono" style="margin:0;text-align:center;font-size:12px;letter-spacing:.06em">${meta}</p>
<p class="mono" style="margin:0;text-align:center;font-size:11px;color:var(--muted);user-select:all">${ok ? esc(url) : ''}</p>
<div id="share-actions" style="display:flex;flex-direction:column;gap:8px;margin-top:4px">
<button type="button" class="btn" data-act="copy-link" data-url="${esc(url)}" ${ok ? '' : 'disabled'}>${icon('link', 18)}<span>링크 복사</span></button>
<button type="button" class="btn line" data-act="share-apps" ${ok ? '' : 'disabled'}>공유 앱 선택</button>
</div>`);
}
function shareApps() {
  $('#share-actions').innerHTML = `<p class="serif" style="margin:6px 0 0;font-size:24px">어디로 보낼까요?</p>
<p class="note" style="margin:0">실제 앱에서는 기기의 공유 메뉴가 열려요.</p>
<div class="rows">${row({ act: 'share-dest', title: '메시지', sub: '표지 링크 전달' })}${row({ act: 'share-dest', title: '다른 앱', sub: '기기 공유 메뉴에서 선택' })}</div>
<button type="button" class="btn text" data-act="close-sheet">공유 화면 닫기</button>`;
}

// ───────── login sheet (J2)
function openLogin() {
  openSheet(`<span class="grab"></span>
<div style="display:flex;align-items:center;justify-content:space-between;margin-top:4px"><h2>Esel에 들어가기</h2><button type="button" class="icon-btn" data-act="close-sheet" aria-label="닫기" style="margin-right:-12px">${icon('x', 22)}</button></div>
<p style="margin:0 0 6px;font-size:14px;line-height:1.55;color:var(--sub)">오늘의 표지를 끝까지 읽고, 구독한 잡지를 모아 봐요.</p>
<button type="button" class="btn" data-act="signin">${icon('apple', 20, 1.6)}<span>Apple로 계속하기</span></button>
<button type="button" class="btn line" data-act="signin" style="background:${WHITE};box-shadow:inset 0 0 0 1px var(--line)">Google로 계속하기</button>
<button type="button" class="btn line" data-act="signin" style="background:${WHITE};box-shadow:inset 0 0 0 1px var(--line)">${icon('mail', 20, 1.6)}<span>이메일로 계속하기</span></button>
<div style="display:flex;align-items:center;gap:12px;margin:8px 0 2px;font-size:13px;color:var(--muted)"><span style="flex:1;height:1px;background:#D3D4CE"></span><span>처음이라면</span><span style="flex:1;height:1px;background:#D3D4CE"></span></div>
<button type="button" data-act="to-join" style="height:50px;display:flex;align-items:center;justify-content:center;gap:6px;font-size:16px;font-weight:600"><span>내 잡지 만들기</span>${icon('arrow', 18, 1.8)}</button>
<p style="margin:0;font-size:12px;line-height:1.5;color:var(--muted);text-align:center">계속하면 이용약관과 개인정보 처리방침에 동의하게 돼요. 목업이라 실제로 로그인하지 않아요.</p>`);
}

// ───────── sheets, toasts
function openSheet(html) {
  closeSheet(true);
  const dev = $('#device');
  dev.insertAdjacentHTML('beforeend', `<div class="backdrop" data-act="close-sheet"></div><section class="sheet glass" role="dialog" aria-modal="true">${html}</section>`);
  requestAnimationFrame(() => { $('.backdrop', dev).classList.add('show'); $('.sheet', dev).classList.add('show'); $('.sheet button', dev)?.focus({ preventScroll: true }); });
}
function closeSheet(now = false) {
  const dev = $('#device');
  const els = $$('.backdrop, .sheet', dev);
  if (!els.length) return;
  if (now || calm()) { els.forEach((e) => e.remove()); return; }
  els.forEach((e) => e.classList.remove('show'));
  setTimeout(() => els.forEach((e) => e.remove()), 360);
}
let toastTimer;
function toast(msg) {
  const dev = $('#device');
  $('.toast', dev)?.remove();
  dev.insertAdjacentHTML('beforeend', `<div class="toast glass" role="status">${icon('check', 18, 2)}<span>${esc(msg)}</span></div>`);
  const t = $('.toast', dev);
  requestAnimationFrame(() => t.classList.add('show'));
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => { t.classList.remove('show'); setTimeout(() => t.remove(), 260); }, 2200);
}

// ───────── navigation
function render({ keepScroll = false } = {}) {
  const top = stack[stack.length - 1];
  const out = (SCREENS[top.name] || SCREENS.feed)(top.arg);
  if (out.redirect) { stack[stack.length - 1] = out.redirect; render({ keepScroll }); return; }
  const app = $('#app');
  const y = keepScroll ? $('#scroller', app)?.scrollTop || 0 : 0;
  closeSheet(true);
  app.innerHTML = (out.html || out) + (out.capsule ? capsule(out.capsule) : '');
  out.mount?.(app);
  const sc = $('#scroller', app);
  if (sc && y) { sc.scrollTop = y; sc.dispatchEvent(new Event('scroll')); }
  if (!keepScroll) app.focus({ preventScroll: true });
  markGuide();
}
const NEEDS_LOGIN = new Set(['shelf', 'stand', 'same', 'me', 'make', 'record', 'friends', 'twin', 'settings']);
function go(name, arg) {
  if (S.auth === 'out' && NEEDS_LOGIN.has(name)) { openLogin(); return; }
  const entry = arg !== undefined ? { name, arg } : { name };
  const top = stack[stack.length - 1];
  if (['stand', 'same'].includes(name) && ['stand', 'same'].includes(top.name)) { stack[stack.length - 1] = entry; render(); return; }
  stack.push(entry);
  render();
}
function back() {
  if (stack.length > 1) stack.pop();
  else stack = [{ name: S.auth === 'in' ? 'feed' : 'intro' }];
  render();
}
function tab(name) {
  if (S.auth === 'out') { openLogin(); return; }
  if (name === 'make') { go('make'); return; }
  stack = name === 'feed' ? [{ name: 'feed' }] : [{ name: 'feed' }, { name }];
  render();
}
function signIn() {
  S.auth = 'in';
  closeSheet(true);
  stack = [{ name: 'feed' }];
  render();
  toast(`${meName()}으로 로그인했어요`);
}

// ───────── actions
const ACT = {
  login: () => openLogin(),
  signin: () => signIn(),
  'to-join': () => { closeSheet(true); go('join-color'); },
  'close-sheet': () => closeSheet(),
  top: () => $('#scroller')?.scrollTo({ top: 0, behavior: calm() ? 'auto' : 'smooth' }),
  feedtab: (t) => { S.feedTab = t; render(); },
  like: (k, el) => {
    if (S.auth === 'out') return openLogin();
    S.liked.has(k) ? S.liked.delete(k) : S.liked.add(k);
    $$(`[data-act="like:${k}"]`).forEach((b) => {
      const on = S.liked.has(k);
      b.setAttribute('aria-pressed', on);
      $('svg', b).setAttribute('fill', on ? 'currentColor' : 'none');
      b.classList.remove('pop');
      if (on) { void b.offsetWidth; b.classList.add('pop'); }
    });
  },
  scrap: (k) => {
    if (S.auth === 'out') return openLogin();
    S.scrapped.has(k) ? S.scrapped.delete(k) : S.scrapped.add(k);
    $$(`[data-act="scrap:${k}"]`).forEach((b) => { const on = S.scrapped.has(k); b.setAttribute('aria-pressed', on); $('svg', b).setAttribute('fill', on ? 'currentColor' : 'none'); });
    toast(S.scrapped.has(k) ? '스크랩했어요' : '스크랩을 취소했어요');
  },
  sub: (k) => {
    if (S.auth === 'out') return openLogin();
    S.subs.has(k) ? S.subs.delete(k) : S.subs.add(k);
    render({ keepScroll: true });
    toast(S.subs.has(k) ? `${k}${jong(k) ? '을' : '를'} 구독했어요` : `${k} 구독을 취소했어요`);
  },
  share: (k) => (S.auth === 'out' ? openLogin() : openShare(k)),
  'copy-link': (el) => {
    const url = el.dataset.url;
    const done = () => { el.innerHTML = `${icon('check', 18, 2)}<span>링크를 복사했어요</span>`; toast('공유 링크를 복사했어요'); };
    try { navigator.clipboard.writeText(url).then(done, done); } catch { done(); }
  },
  'share-apps': () => shareApps(),
  'share-dest': () => { closeSheet(); toast('실제 앱에서는 기기 공유 메뉴로 보내요'); },
  shelfview: (key, v) => { const [k, view] = [key, v]; S.shelfView[k] = view; render({ keepScroll: true }); },
  face: (k) => { S.me.face = k; render({ keepScroll: true }); },
  mast: (k) => { S.me.mast = k; render({ keepScroll: true }); },
  'content-weekly': () => { if (S.published) { S.contentAttached=true; render(); toast('오늘 호를 연결했어요. 호수는 늘지 않아요.'); } else { go('make'); } },
  'content-restyle': () => toast('실제 앱에서 내 지난 날짜 발행 표지를 골라요. 목업은 선택 안내만 보여요.'),
  publish: () => {
    const cover = $('#mk-cover');
    const roll = $('#roll');
    S.me.caption = $('#cover-line')?.value.trim() || S.me.caption;
    const finish = () => {
      S.published = true;
      S.justPublished = true;
      S.me.issues += 1;
      stack = [{ name: 'feed' }, { name: 'same' }];
      render();
      toast(`Nº ${pad3(S.me.issues)}를 발행했어요`);
    };
    if (calm()) { finish(); return; }
    cover.classList.add('stamping');
    setTimeout(() => roll.classList.add('go'), 330);
    setTimeout(finish, 640);
  },
  restorepick: (d, c) => { S.restorePick[d] = c; render({ keepScroll: true }); },
  restore: (d) => {
    d = +d;
    if (S.credits <= 0 || S.record[d] || d >= TODAY) return;
    const c = S.restorePick[d] || (RESTORE_CHOICES[d] || TODAY_COLORS)[0];
    S.record[d] = { c, k: 'restored' };
    S.credits -= 1;
    stack[stack.length - 1] = { name: 'restored', arg: String(d) };
    render();
  },
  'to-record': () => { while (stack.length > 1 && stack[stack.length - 1].name !== 'record') stack.pop(); render(); },
  accept: (k) => {
    S.requests = S.requests.filter((r) => r !== k);
    if (!S.friends.includes(k)) S.friends.push(k);
    stack[stack.length - 1] = { name: 'friend-added', arg: k };
    render();
  },
  later: () => back(),
  'to-friends': () => { stack = [{ name: 'feed' }, { name: 'me' }, { name: 'friends' }]; render(); },
  'invite-link': () => {
    const url = `https://example.com/esel/invite/${meName()}`;
    try { navigator.clipboard.writeText(url).catch(() => {}); } catch { /* clipboard refused */ }
    toast('초대 링크를 복사했어요');
  },
  'twin-invite': (k) => { S.twin = { ...S.twin, step: 'invited', with: k }; go('twin-invite'); },
  'twin-cancel': () => { S.twin.step = 'none'; back(); },
  'twin-accept': () => { S.twin.step = 'paired'; stack[stack.length - 1] = { name: 'twin-color' }; render(); },
  twinpick: (c) => { S.twin.color = c; render({ keepScroll: true }); },
  'twin-ready': () => { S.twin.step = 'ready'; go('twin-ready'); },
  'twin-post': () => { S.twin.step = 'posted'; stack[stack.length - 1] = { name: 'twin-wait' }; render(); toast('트윈 보관함에 내 표지를 올렸어요'); },
  'twin-arrive': () => { S.twin.step = 'both'; stack[stack.length - 1] = { name: 'twin-reveal' }; render(); },
  twinvis: (v) => {
    if (v === 'joint') { S.twin.step = 'consent'; go('twin-consent'); return; }
    S.twin.step = v;
    go('twin-done');
  },
  'twin-agree': () => { S.twin.step = 'joint'; stack[stack.length - 1] = { name: 'twin-joint' }; render(); },
  'twin-publish': () => { S.twin.step = 'published'; stack[stack.length - 1] = { name: 'twin-done' }; render(); },
  'save-profile': () => {
    const name = $('#pf-name').value;
    const bio = $('#pf-bio').value.trim();
    if (!/^[a-z]{2,10}$/.test(name) || (TAKEN.has(name) && name !== S.me.name)) return;
    S.me.name = name;
    S.me.bio = bio;
    stack = [{ name: 'feed' }, { name: 'me' }];
    render();
    toast('프로필을 저장했어요');
  },
  notif: (k) => { S.notif[k] = !S.notif[k]; render({ keepScroll: true }); },
  logout: () => { S.auth = 'out'; stack = [{ name: 'goodbye', arg: 'out' }]; render(); },
  'delete-check': () => { S.deleteChecked = !S.deleteChecked; render({ keepScroll: true }); },
  'keep-account': () => { S.deleteChecked = false; stack = [{ name: 'feed' }, { name: 'me' }, { name: 'settings' }]; render(); },
  'delete-account': () => { S = fresh(); stack = [{ name: 'goodbye', arg: 'deleted' }]; render(); },
  'to-intro': () => { stack = [{ name: 'intro' }]; render(); },
  restart: () => { S = fresh(); stack = [{ name: 'intro' }]; render(); },
  joincolor: (c) => { S.join.color = c; render({ keepScroll: true }); },
  shutter: () => go('join-name'),
  album: () => { toast('목업에서는 예시 사진으로 이어가요'); go('join-name'); },
  flip: () => toast('목업에서는 카메라를 쓰지 않아요'),
  joinface: (f) => { S.join.face = f; render({ keepScroll: true }); },
  found: (where) => {
    const j = S.join;
    S.auth = 'in';
    S.me = { ...S.me, name: j.name, color: j.color, face: j.face, issues: 1 };
    S.published = true;
    S.record = {};
    stack = where === 'me' ? [{ name: 'feed' }, { name: 'me' }] : [{ name: 'feed' }];
    render();
    toast('창간호를 발행했어요');
  },
};

document.addEventListener('click', (e) => {
  const t = e.target.closest('[data-jump],[data-tab],[data-back],[data-go],[data-act]');
  if (!t || t.disabled) return;
  if (t.dataset.jump) { jump(t.dataset.jump); return; }
  if (t.dataset.tab) { tab(t.dataset.tab); return; }
  if (t.hasAttribute('data-back')) { back(); return; }
  if (t.dataset.go) {
    const [name, ...rest] = t.dataset.go.split(':');
    go(name, rest.length ? rest.join(':') : undefined);
    return;
  }
  const [name, ...args] = t.dataset.act.split(':');
  ACT[name]?.(...args, t);
});
document.addEventListener('input', (e) => {
  const key = e.target.dataset?.in;
  if (!key) return;
  const el = e.target;
  if (key === 'join-name' || key === 'pf-name') {
    const v = el.value.toLowerCase().replace(/[^a-z]/g, '').slice(0, 10);
    if (v !== el.value) el.value = v;
    if (key === 'join-name') {
      S.join.name = v;
      const [hint, err, ok] = nameHint(v);
      const m = $('#jn-mast');
      m.textContent = v || 'esel';
      m.style.fontSize = `${mastSize(v || 'esel', 260, 140)}px`;
      const h = $('#jn-hint');
      h.textContent = hint;
      h.classList.toggle('err', err);
      $('#jn-next').disabled = !ok;
    } else {
      const [hint, err, ok] = v === S.me.name ? ['지금 쓰는 이름이에요.', false, true] : nameHint(v);
      const h = $('#pf-name-hint');
      h.textContent = v.length < 2 ? '영문 소문자 2~10자' : hint;
      h.classList.toggle('err', err);
      $('#pf-save').disabled = !ok;
    }
  }
  if (key === 'pf-bio') $('#pf-bio-hint').textContent = `${el.value.length} / 80`;
  if (key === 'caption') S.me.caption = el.value;
});
document.addEventListener('submit', (e) => {
  if (e.target.id !== 'find') return;
  e.preventDefault();
  const id = $('#find-id').value.trim().replace(/^@/, '').toLowerCase();
  if (PEOPLE[id] && id !== ME) go('friend', id);
  else { $('#find-hint').textContent = id ? `@${id} 아이디를 찾지 못했어요. 철자를 확인해 주세요.` : '영문 아이디를 적어 주세요.'; }
});
document.addEventListener('keydown', (e) => { if (e.key === 'Escape' && $('.sheet')) closeSheet(); });

// ───────── desktop guide: jump to a scene
const JUMPS = [
  ['intro', '비로그인 첫 표지', 'J1'],
  ['join', '창간하기', 'J3–J7'],
  ['feed', '로그인 후 표지 피드', 'C1·C7'],
  ['same', '같은 색 · 발행 전', 'C8'],
  ['make', '오늘 호 만들기', 'C6'],
  ['me', '내 잡지', 'M1'],
  ['record', '월간 색 기록', 'R1–R5'],
  ['twin', '친구와 트윈', 'T1–T10'],
  ['friends', '나의 친구', 'F1–F3'],
  ['settings', '설정 · 계정', 'S1–S6'],
];
function jump(id) {
  if (id === 'reset') { S = fresh(); stack = [{ name: 'intro' }]; render(); return; }
  if (id === 'intro') { S.auth = 'out'; stack = [{ name: 'intro' }]; render(); return; }
  if (id === 'join') { S.auth = 'out'; stack = [{ name: 'intro' }, { name: 'join-color' }]; render(); return; }
  if (S.auth === 'out') S.auth = 'in';
  const path = { feed: [], same: ['same'], make: ['make'], me: ['me'], record: ['me', 'record'], twin: ['me', 'twin'], friends: ['me', 'friends'], settings: ['me', 'settings'] }[id] || [];
  stack = [{ name: 'feed' }, ...path.map((name) => ({ name }))];
  render();
}
function markGuide() {
  const nav = $('#jumps');
  if (!nav.childElementCount) nav.innerHTML = JUMPS.map(([id, label, code]) => `<button type="button" data-jump="${id}"><span>${label}</span><span>${code}</span></button>`).join('');
}

// ───────── size: a real phone fills the screen; desktop shows a 393×852 phone that fits the window
function fitDevice() {
  const dev = $('#device');
  const phone = innerWidth <= 560;
  document.body.classList.toggle('phone', phone);
  if (phone) {
    const z = innerWidth / 393;
    dev.style.zoom = z;
    dev.style.height = `${document.body.clientHeight / z}px`;
  } else {
    dev.style.zoom = Math.min(1, (innerHeight - 48) / 852);
    dev.style.height = '852px';
  }
}
let lastH = 0;
addEventListener('resize', () => {
  fitDevice();
  const h = $('#app').clientHeight;
  const typing = ['INPUT', 'TEXTAREA'].includes(document.activeElement?.tagName);
  if (!typing && Math.abs(h - lastH) > 40) { lastH = h; render({ keepScroll: true }); }
});
fitDevice();
lastH = $('#app').clientHeight;
render();
