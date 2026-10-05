// Shared data and markup helpers for the cover-SNS family of artboards.
export const B = (id) => `/_blob/${id}`;
export const SANS = "'Esel Dot', 'Instrument Sans', Pretendard, -apple-system, BlinkMacSystemFont, 'Apple SD Gothic Neo', 'Noto Sans KR', sans-serif";
export const SERIF = "'Esel Dot', 'Cormorant Garamond', 'Nanum Myeongjo', AppleMyungjo, Georgia, serif";
export const MONO = "'DM Mono', ui-monospace, Menlo, monospace";
export const INK = '#292A27';
export const PAPER = '#F9F9FB';
export const MUTED = '#71736C';
export const HAIR = '#E0E1DC';
export const EASE_OUT = 'cubic-bezier(0.23, 1, 0.32, 1)';
export const EASE_DRAWER = 'cubic-bezier(0.32, 0.72, 0, 1)';

// Twelve point colors: the acrylic paint asset, Korean and English names, and a flat hex for swatches.
export const PAINT = {
  sage: { id: '01c7aef9caeab80dd2ca2949e8ba18c0', name: '세이지', en: 'Sage', hex: '#A8B5A0' },
  butter: { id: '76c81659c2b051a973c2071f8c1dd366', name: '버터', en: 'Butter', hex: '#E3C878' },
  powder: { id: '2741e570bc827c25a1b735a55cfb4f8e', name: '파우더 블루', en: 'Powder blue', hex: '#A9BDDC' },
  coral: { id: '45fd789cdc8232887f512c159b3ba1e3', name: '코랄', en: 'Coral', hex: '#EE8C76' },
  lilac: { id: 'd032f1756dd4b6c552a391d30c48d7d6', name: '라일락', en: 'Lilac', hex: '#BBA6D6' },
  terracotta: { id: 'dc9bda2f1944a8796d1a3d118d7d5935', name: '테라코타', en: 'Terracotta', hex: '#C2643F' },
  burgundy: { id: '8c34cccf0aa6b2cd1c68178dbff4a444', name: '버건디', en: 'Burgundy', hex: '#7A2735' },
  olive: { id: '8cb906caa448cfa1a9e4217aa611ab08', name: '올리브', en: 'Olive', hex: '#6F7445' },
  cream: { id: '3530d97ccf523268678b64e43a7a9448', name: '크림', en: 'Cream', hex: '#E9DEC6' },
  charcoal: { id: 'f0a5d7b805f4ea330ca85e418c63f59e', name: '차콜', en: 'Charcoal', hex: '#3F4043' },
  camel: { id: 'b6075b3235f77454183c94c49f6da37a', name: '카멜', en: 'Camel', hex: '#C1945F' },
  cobalt: { id: 'df0bc44e7f972fd97b0d90234a638a31', name: '코발트', en: 'Cobalt', hex: '#2648B0' },
};
export const COLOR_ORDER = ['sage', 'butter', 'powder', 'coral', 'lilac', 'terracotta', 'burgundy', 'olive', 'cream', 'charcoal', 'camel', 'cobalt'];

// People: photo asset, height/width ratio, face centre and width as fractions of the photo, and their example post.
export const PEOPLE = {
  dana: { id: 'ccccff032247b980b249542cac99de46', r: 1.5, fx: 0.55, fy: 0.441, fw: 0.204, color: 'powder', time: '오전 8:12', cap: '난간에 기대서, 셔츠 하나로.', alt: '파우더 블루 셔츠와 데님 착장' },
  elin: { id: '9cfabfeec4c23b2ece0dbf8f87ac8a11', r: 1.5, fx: 0.542, fy: 0.217, fw: 0.221, color: 'sage', time: '오전 9:40', cap: '라탄 의자, 세이지 셋업. 일요일 오전.', alt: '세이지색 셋업을 입고 라탄 의자에 앉은 착장' },
  mira: { id: '8a310513242c00b53e6f091e65dc00df', r: 1.25, fx: 0.434, fy: 0.195, fw: 0.104, color: 'sage', time: '오후 1:05', cap: '세이지 투피스, 철문 앞에서.', alt: '연두빛 세이지 투피스 드레스 착장' },
  ama: { id: 'a3b1f50ec885b82797b4dad1d6fb32f8', r: 1.5, fx: 0.478, fy: 0.205, fw: 0.117, color: 'butter', time: '오전 8:40', cap: '노란 셋업에 은색 가방 하나.', alt: '노란 셋업과 은색 가방 착장' },
  hana: { id: '16b1eeb8d5be0dba464bad2254d08550', r: 1.25, fx: 0.656, fy: 0.229, fw: 0.101, color: 'butter', time: '오전 10:20', cap: '버터 와이드 팬츠, 노란 차와 깔맞춤.', alt: '노란 와이드 셋업을 입고 노란 클래식카에 기댄 착장' },
  sol: { id: '200ffdfc3dc90562fa53863c048124d3', r: 1.5, fx: 0.516, fy: 0.341, fw: 0.107, color: 'powder', time: '오전 11:15', cap: '하늘색 셋업, 의자 하나.', alt: '하늘색 셋업을 입고 스튜디오 의자에 앉은 착장' },
  ines: { id: '0d4a6ba247b79548b298ec9fb0b0778c', r: 1.5, fx: 0.565, fy: 0.184, fw: 0.196, color: 'powder', time: '오후 2:30', cap: '블라우스는 크게, 바지는 하얗게.', alt: '하늘색 블라우스와 흰 바지 착장' },
  zuri: { id: 'a3999eebd3499221f8ec78cf743f25b7', r: 1.44, fx: 0.555, fy: 0.164, fw: 0.116, color: 'coral', time: '오전 9:02', cap: '코랄 원피스, 문턱에 서서.', alt: '코랄 원피스 착장' },
  rio: { id: 'b5ff21cbb74e080d3cd23771fe4a7d6a', r: 1.5, fx: 0.552, fy: 0.35, fw: 0.138, color: 'coral', time: '오후 6:45', cap: '분홍 벽엔 코랄 슬립.', alt: '분홍 벽 앞 코랄 슬립 원피스 착장' },
  lua: { id: '274a44a60b66f668d5e90dd01795655e', r: 1.5, fx: 0.375, fy: 0.223, fw: 0.203, color: 'lilac', time: '오전 10:55', cap: '라일락 셋업에 바이저.', alt: '라일락 셋업과 바이저 착장' },
  theo: { id: '594858a7eb4bdde0d0199e0982cf3f95', r: 1.5, fx: 0.55, fy: 0.516, fw: 0.145, color: 'lilac', time: '오후 4:10', cap: '창가의 라일락 니트.', alt: '어두운 창가에 앉은 라일락 니트 셋업 착장' },
  nia: { id: 'be2062f0f8bb9e61196b7a918177e0f2', r: 1.5, fx: 0.529, fy: 0.381, fw: 0.142, color: 'terracotta', time: '오후 12:20', cap: '줄무늬 테라코타, 계단 위에서.', alt: '테라코타 줄무늬 셔츠와 반바지 착장' },
  vera: { id: '63ec474100e2afdff573023dfd73730c', r: 1.5, fx: 0.514, fy: 0.34, fw: 0.085, color: 'terracotta', time: '오후 3:35', cap: '주황 드레스가 바람을 탔다.', alt: '가을 공원의 주황 롱드레스 착장' },
  cleo: { id: '0e9dfede87240970a60a9d4d7b348202', r: 1.64, fx: 0.484, fy: 0.226, fw: 0.097, color: 'burgundy', time: '오후 7:15', cap: '버건디 수트 속 데님.', alt: '버건디 수트와 데님 톱 착장' },
  lise: { id: 'a766ad9f12dec92cfa9b3cdca4c63768', r: 1.5, fx: 0.473, fy: 0.349, fw: 0.245, color: 'burgundy', time: '오전 8:05', cap: '창가의 버건디 코트.', alt: '창가에 선 버건디 랩 코트 착장' },
  kofi: { id: 'c2d2447b3fb019a0647547b338dc9615', r: 1.5, fx: 0.732, fy: 0.144, fw: 0.134, color: 'olive', time: '오전 9:30', cap: '올리브 수트에 빨간 타이.', alt: '올리브 더블 수트와 빨간 타이 착장' },
  imani: { id: '72d732d3de8d11ba280ed3e810a621a5', r: 1.25, fx: 0.46, fy: 0.298, fw: 0.16, color: 'olive', time: '오후 8:00', cap: '올리브 드레스, 벽돌 앞.', alt: '벽돌 벽 앞 올리브 튜브 드레스 착장' },
  freya: { id: 'd59cedab1c3a96ed7cf32ca456e541f8', r: 1.5, fx: 0.467, fy: 0.188, fw: 0.138, color: 'cream', time: '오전 11:40', cap: '크림 수트, 파란 타일.', alt: '파란 타일 스튜디오의 크림 수트 착장' },
  maya: { id: '8ad47ab1dabd84a10ead2ddeb7eefb86', r: 1.5, fx: 0.714, fy: 0.38, fw: 0.14, color: 'cream', time: '오후 2:05', cap: '흰 벽에 크림 셋업.', alt: '흰 벽에 기댄 크림 셔츠와 바지 착장' },
  omar: { id: 'b793cac0ae70e33fd05e2a45f17a2500', r: 1.5, fx: 0.326, fy: 0.215, fw: 0.198, color: 'charcoal', time: '오후 5:25', cap: '숲에서 입은 검정 수트.', alt: '숲속의 검정 수트 착장' },
  june: { id: 'a083104662de6b00bdffc25d95935c8f', r: 1.25, fx: 0.308, fy: 0.167, fw: 0.122, color: 'charcoal', time: '오전 10:00', cap: '차콜 수트, 한쪽 다리는 자유롭게.', alt: '검정 수트와 흰 셔츠 착장' },
  selin: { id: '0d2c5aca03c0e210cd888e2094c78869', r: 1.5, fx: 0.527, fy: 0.421, fw: 0.159, color: 'camel', time: '오후 3:00', cap: '카멜 코트와 페도라.', alt: '카멜 코트와 페도라 착장' },
  leo: { id: '138c37eab57fb9690da67376fe9028ea', r: 1.25, fx: 0.488, fy: 0.12, fw: 0.092, color: 'camel', time: '오전 8:50', cap: '카멜 코트, 검정으로 받치기.', alt: '카멜 코트와 검정 니트 착장' },
  noor: { id: '00e40fb5b21f897da768d0dde6b4eade', r: 1.5025, fx: 0.448, fy: 0.18, fw: 0.244, color: 'camel', time: '오전 11:10', cap: '크림 재킷에 카멜 히잡.', alt: '크림 트위드 재킷과 카멜색 히잡 착장' },
  mara: { id: 'a47d28a12b07c350f690ae5c5f0ed153', r: 1.5, fx: 0.551, fy: 0.279, fw: 0.103, color: 'camel', time: '오후 4:20', cap: '카멜 코트, 검은 모자와 부츠.', alt: '카멜 더블 코트와 검은 챙모자, 니하이 부츠 착장' },
  ayo: { id: 'f58f119167a567a8a92482ac18be333a', r: 1.5, fx: 0.369, fy: 0.26, fw: 0.16, color: 'cobalt', time: '오후 1:40', cap: '코발트 원피스, 금단추.', alt: '금단추 코발트 원피스 착장' },
  riva: { id: '7bee9f1a7214e73bb5aa29dfce802597', r: 1.5, fx: 0.507, fy: 0.151, fw: 0.083, color: 'cobalt', time: '오전 7:30', cap: '바닷가엔 코발트.', alt: '바닷가 바위 위 코발트 셔츠 원피스 착장' },
};
export const ME = 'selin';

// Place a focus point of the photo (fractions) at (tx, ty) inside a W×H box, with the photo k× the box width.
export function crop(key, W, H, k, focusX, focusY, tx, ty, { extra = '', alt, filter = '' } = {}) {
  const p = PEOPLE[key];
  const dw = Math.round(W * k);
  const dh = Math.round(dw * p.r);
  const left = Math.round(Math.min(0, Math.max(W - dw, tx - focusX * dw)));
  const top = Math.round(Math.min(0, Math.max(H - dh, ty - focusY * dh)));
  return `<span style="position: relative; display: block; width: ${W}px; height: ${H}px; overflow: hidden; background: #EDEEEA${extra}"><img src="${B(p.id)}" alt="${alt ?? p.alt}" style="position: absolute; left: ${left}px; top: ${top}px; width: ${dw}px; height: ${dh}px; max-width: none${filter ? `; filter: ${filter}` : ''}"></span>`;
}

// Where a photo lands inside a W×H box with object-fit: cover and the given object-position fractions.
export function fit(key, W, H, px = 0.5, py = 0.5) {
  const p = PEOPLE[key];
  const iw = 800;
  const ih = 800 * p.r;
  const s = Math.max(W / iw, H / ih);
  const dw = iw * s;
  const dh = ih * s;
  const ox = (dw - W) * px;
  const oy = (dh - H) * py;
  return { dw, dh, ox, oy, fx: p.fx * dw - ox, fy: p.fy * dh - oy, fwPx: p.fw * dw };
}
const pct = (v) => `${Math.round(v * 100)}%`;

export const photo = (key, style, alt) => `<img src="${B(PEOPLE[key].id)}" alt="${alt ?? PEOPLE[key].alt}" style="${style}">`;
export const cover = (key, W, H, px = 0.5, py = 0.5, extra = '', alt) => photo(key, `display: block; width: ${W}px; height: ${H}px; object-fit: cover; object-position: ${pct(px)} ${pct(py)}${extra}`, alt);

// An acrylic stroke laid across the eyes of a photo shown in a W×H cover box.
export function faceStroke(key, W, H, px = 0.5, py = 0.5, rot = -10) {
  const f = fit(key, W, H, px, py);
  const pw = Math.round(f.fwPx * 2.15);
  const color = PEOPLE[key].color;
  return `<img src="${B(PAINT[color].id)}" alt="" style="position: absolute; left: ${Math.round(f.fx - pw / 2)}px; top: ${Math.round(f.fy - f.fwPx * 0.12 - pw / 4)}px; width: ${pw}px; height: ${Math.round(pw / 2)}px; max-width: none; transform: rotate(${rot}deg); pointer-events: none">`;
}
// The same photo cropped so the frame starts just under the chin.
// Enlarges the photo when needed so that chin-to-bottom alone fills the box.
export function neckDown(key, W, H, extra = '') {
  const p = PEOPLE[key];
  const below = (dw) => dw * p.r - (p.fy * dw * p.r + p.fw * dw * 0.78);
  const k = Math.max(1, (H + 2) / below(W));
  const dw = Math.round(W * k);
  const dh = Math.round(dw * p.r);
  const chin = p.fy * dh + p.fw * dw * 0.78;
  const top = Math.round(Math.min(0, Math.max(H - dh, -chin)));
  const left = Math.round(Math.min(0, Math.max(W - dw, W / 2 - p.fx * dw)));
  return `<span style="position: relative; display: block; width: ${W}px; height: ${H}px; overflow: hidden; background: #EDEEEA${extra}"><img src="${B(p.id)}" alt="${p.alt}, 얼굴 아래로 자른 구도" style="position: absolute; left: ${left}px; top: ${top}px; width: ${dw}px; height: ${dh}px; max-width: none"></span>`;
}

export function avatar(key, D) {
  const p = PEOPLE[key];
  const W = Math.round((0.6 * D) / p.fw);
  const H = Math.round(W * p.r);
  const ml = Math.min(0, Math.max(D - W, Math.round(D / 2 - p.fx * W)));
  const mt = Math.min(0, Math.max(D - H, Math.round(D / 2 - p.fy * H)));
  return `<span style="display: block; width: ${D}px; height: ${D}px; flex-shrink: 0; border-radius: 50%; overflow: hidden; background: #E9E9E6"><img src="${B(p.id)}" alt="" style="display: block; width: ${W}px; height: ${H}px; max-width: none; margin: ${mt}px 0 0 ${ml}px"></span>`;
}
export const paint = (c, w, extra = '', alt) => `<img src="${B(PAINT[c].id)}" alt="${alt ?? PAINT[c].name}" style="width: ${w}px; height: ${w / 2}px; flex-shrink: 0; object-fit: contain${extra}">`;

const HEART = 'M12 20.3l-1.2-1.1C6.2 15 3.5 12.5 3.5 9.4 3.5 7 5.4 5 7.8 5c1.6 0 3.2.9 4.2 2.2C13 5.9 14.6 5 16.2 5c2.4 0 4.3 2 4.3 4.4 0 3.1-2.7 5.6-7.3 9.8L12 20.3z';
const PATHS = {
  plus: '<path d="M12 5v14"></path><path d="M5 12h14"></path>',
  heart: `<path d="${HEART}" fill="{{heartFill}}"></path>`,
  heartPlain: `<path d="${HEART}"></path>`,
  comment: '<path d="M20 12a8 8 0 0 1-11.8 7L4 20l1.1-4A8 8 0 1 1 20 12z"></path>',
  bookmark: '<path d="M6.5 4h11v16l-5.5-4.2L6.5 20z"></path>',
  arrow: '<path d="M4 12h15"></path><path d="M14 7l5 5-5 5"></path>',
  up: '<path d="M6 14l6-6 6 6"></path>',
  down: '<path d="M6 10l6 6 6-6"></path>',
  left: '<path d="M14 6l-6 6 6 6"></path>',
  x: '<path d="M6 6l12 12"></path><path d="M18 6L6 18"></path>',
  check: '<path d="M5 12.5l4.5 4.5L19 7.5"></path>',
  flip: '<path d="M4 9a8 8 0 0 1 14-3l2 2"></path><path d="M20 4v4h-4"></path><path d="M20 15a8 8 0 0 1-14 3l-2-2"></path><path d="M4 20v-4h4"></path>',
  apple: '<path d="M15.6 3.5c.1 1.2-.4 2.3-1.1 3.1-.8.8-1.9 1.4-3 1.3-.1-1.1.4-2.3 1.1-3 .8-.8 2-1.4 3-1.4z" fill="currentColor" stroke="none"></path><path d="M19.6 16.9c-.5 1.1-.8 1.6-1.4 2.6-.9 1.4-2.2 3.1-3.8 3.1-1.4 0-1.8-.9-3.7-.9s-2.3.9-3.7.9c-1.6 0-2.8-1.6-3.7-3-2.5-3.9-2.8-8.4-1.2-10.8 1.1-1.7 2.9-2.7 4.6-2.7s2.8.9 4.2.9c1.4 0 2.2-.9 4.2-.9 1.5 0 3.1.8 4.2 2.2-3.7 2-3.1 7.3.3 8.6z" fill="currentColor" stroke="none"></path>',
  mail: '<rect x="3.5" y="5.5" width="17" height="13" rx="2"></rect><path d="M4 7l8 6 8-6"></path>',
  camera: '<path d="M4 8h3.2l1.5-2.5h6.6L16.8 8H20v11H4z"></path><circle cx="12" cy="13.2" r="3.4"></circle>',
  lock: '<rect x="5.5" y="10.5" width="13" height="9.5" rx="1.5"></rect><path d="M8.5 10.5V8a3.5 3.5 0 0 1 7 0v2.5"></path>',
};
export const icon = (name, size = 24, sw = 1.7) => `<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="${sw}" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${PATHS[name]}</svg>`;
export const LIKE_ATTRS = ' aria-pressed="{{likePressed}}" onClick="{{toggleLike}}"';
export const stat = (name, label, count, attrs = '') => `<button type="button" aria-label="${label}"${attrs} style="height: 48px; min-width: 48px; padding: 0 12px; display: flex; align-items: center; gap: 6px">${icon(name, 23)}${count ? `<span style="font-size: 13px; font-weight: 600">${count}</span>` : ''}</button>`;
export const wordmark = (size, dot = '#AE8775') => `<span style="font-family: ${SERIF}; font-size: ${size}px; line-height: 1; letter-spacing: -1px">Esel<span style="color: ${dot}">.</span></span>`;
export const ROOT = (extra = '') => `width: 393px; height: 852px; box-sizing: border-box; position: relative; overflow: hidden; font-family: ${SANS}; ${extra}`;
export const pill = (label, fg, extra = '') => `<span style="height: 32px; padding: 0 14px; border-radius: 16px; display: flex; align-items: center; box-shadow: inset 0 0 0 1.5px ${fg}; font-size: 13px; font-weight: 600${extra}">${label}</span>`;

// The masthead: the brand name set huge across the top of a cover.
export const masthead = (text, color, { size = 200, top = 80, track = -0.05 } = {}) => `<div aria-hidden="true" style="position: absolute; left: 0; right: 0; top: ${top}px; text-align: center; font-family: ${SERIF}; font-size: ${size}px; line-height: 0.9; letter-spacing: ${track}em; padding-right: ${Math.round(-track * size)}px; color: ${color}; white-space: nowrap">${text}</div>`;

// Floating glass capsule: today's paint, make a cover, my magazine.
export function capsule({ color = 'powder', me = ME } = {}) {
  return `<nav aria-label="주요 화면" class="esel-glass" style="position: absolute; left: 50%; bottom: 34px; width: 196px; height: 60px; margin-left: -98px; box-sizing: border-box; padding: 0 6px; border-radius: 30px; display: flex; align-items: center; justify-content: space-between; color: ${INK}">
<a href="CoverStand.dc.html" aria-label="오늘의 색 가판대" style="width: 60px; height: 48px; display: flex; align-items: center; justify-content: center">${paint(color, 52, '', '')}</a>
<a href="CoverMake.dc.html" aria-label="표지 만들기" style="width: 48px; height: 48px; border-radius: 50%; display: flex; align-items: center; justify-content: center; background: ${INK}; color: ${PAPER}">${icon('plus', 22, 2)}</a>
<a href="CoverShelf.dc.html" aria-label="내 잡지" style="width: 60px; height: 48px; display: flex; align-items: center; justify-content: center">${avatar(me, 34)}</a>
</nav>`;
}

const GLASS_CSS = `@font-face{font-family:'Esel Dot';src:local('AppleSDGothicNeo-Regular'),local('Apple SD Gothic Neo'),local('Pretendard-Regular'),local('Pretendard Regular'),local('NotoSansKR-Regular'),local('Noto Sans KR'),local('Malgun Gothic');unicode-range:U+00B7}
.esel-glass{background:rgba(249,249,251,0.58);-webkit-backdrop-filter:blur(22px) saturate(1.6);backdrop-filter:blur(22px) saturate(1.6);box-shadow:inset 0 0 0 1px rgba(255,255,255,0.6),0 10px 28px rgba(0,0,0,0.14)}
@media (prefers-reduced-transparency: reduce){.esel-glass{background:#F9F9FB;-webkit-backdrop-filter:none;backdrop-filter:none}}
@media (prefers-contrast: more){.esel-glass{background:#F9F9FB;box-shadow:inset 0 0 0 1.5px #292A27}}`;

export const LIKE_VALS = `const liked = !!(this.state && this.state.liked);
const vals = {
heartFill: liked ? 'currentColor' : 'none',
likePressed: liked ? 'true' : 'false',
toggleLike: () => this.setState({ liked: !liked })
};`;

export function page(title, body, { logic = '', methods = '', w = 393, h = 852, css = '' } = {}) {
  return `<!doctype html>
<html lang="ko">
<head>
<meta charset="utf-8">
<title>${title}</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,300;0,400;0,500;1,300;1,400&amp;family=DM+Mono:wght@400;500&amp;family=Instrument+Sans:wght@400;500;600&amp;family=Nanum+Myeongjo:wght@400;700&amp;family=Noto+Sans+KR:wght@400;500;600&amp;display=swap" rel="stylesheet">
<style>
body{margin:0}
button{font:inherit;color:inherit;background:none;border:0;padding:0;cursor:pointer;text-align:inherit}
input{font:inherit;color:inherit}
a{color:inherit;text-decoration:none}a:hover{color:inherit}
button,a{transition:transform 160ms cubic-bezier(0.23,1,0.32,1)}
button:active,a:active{transform:scale(0.97)}
.esel-scroll::-webkit-scrollbar{display:none}
${GLASS_CSS}
@media (prefers-reduced-motion: reduce){button,a{transition:none !important}}
${css}
</style>
</helmet>
${body}
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"$preview":{"width":${w},"height":${h}}}'>
class Component extends DCLogic {
renderVals() {
${LIKE_VALS}
${logic}
return vals;
}
${methods}
}
</script>
</body>
</html>
`;
}

// Masthead size that fits a word of this length across W px (Cormorant averages ~0.47em per letter at -0.05em tracking).
export const mastSize = (text, W, max = 200) => Math.min(max, Math.floor((W * 0.9) / (text.length * 0.47)));
