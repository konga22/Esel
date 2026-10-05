// Cover-SNS screens (C1–C7) on the new model photos, twelve colors and the glass capsule.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { mastSize, B, SANS, SERIF, MONO, INK, PAPER, MUTED, PAINT, PEOPLE, ME, COLOR_ORDER, ROOT, cover, faceStroke, neckDown, crop, avatar, paint, icon, stat, LIKE_ATTRS, pill, masthead, capsule, page } from './lib.mjs';
import { mastLayer, scrollLogic } from './scroll.mjs';

const OUT = path.join(path.dirname(fileURLToPath(import.meta.url)), 'project');
const files = {};
const tabs = (fg) => `<div style="display: flex">
<button type="button" aria-pressed="true" style="height: 44px; padding: 0 6px; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 3px"><span>전체</span><span style="width: 100%; height: 1.5px; background: ${fg}"></span></button>
<button type="button" aria-pressed="false" style="height: 44px; padding: 0 6px; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 3px; opacity: 0.78"><span>구독</span><span style="width: 100%; height: 1.5px"></span></button>
</div>`;
const topBar = (fg, { issue = 249, withTabs = true } = {}) => `<div style="position: absolute; left: 14px; right: 20px; top: 48px; height: 44px; display: flex; align-items: center; justify-content: space-between; color: ${fg}; font-size: 13px; font-weight: 600; letter-spacing: 0.04em">
${withTabs ? tabs(fg) : '<span style="padding-left: 6px">오늘의 표지</span>'}
<span style="font-size: 12px">Nº ${issue} · 2026. 9. 6.</span>
</div>`;
const coverText = (key, { same, likes, comments, bottom = 100 }) => {
  const p = PEOPLE[key];
  return `<div style="position: absolute; left: 20px; right: 8px; bottom: ${bottom}px; color: #FFFFFF">
<div style="display: flex; align-items: flex-end; gap: 12px">
<a href="CoverShelf.dc.html" style="font-family: ${SERIF}; font-style: italic; font-size: 76px; line-height: 0.9; letter-spacing: -0.03em">${key}</a>
<button type="button" style="height: 44px; display: flex; align-items: center">${pill('구독', '#FFFFFF')}</button>
</div>
<a href="CoverStand.dc.html" style="height: 44px; margin-top: 4px; display: flex; align-items: center; gap: 8px; font-size: 14px; font-weight: 600">${paint(p.color, 60)}<span>${PAINT[p.color].name} · 같은 색 ${same}명</span>${icon('arrow', 18, 1.8)}</a>
<p style="margin: 0; font-size: 15px; line-height: 1.45">${p.cap}</p>
<div style="display: flex; align-items: center; margin: 2px 0 0 -12px">
${stat('heart', '좋아요', likes, LIKE_ATTRS)}
${stat('comment', '독자 한 줄', comments)}
${stat('bookmark', '스크랩', '')}
<a href="CoverSpread.dc.html" style="margin-left: auto; height: 48px; padding: 0 12px; display: flex; align-items: center; gap: 4px; font-size: 14px; font-weight: 600"><span>펼쳐 보기</span>${icon('up', 20, 1.8)}</a>
</div>
</div>`;
};
const shade = (h = 480) => `<div aria-hidden="true" style="position: absolute; left: 0; right: 0; bottom: 0; height: ${h}px; background: linear-gradient(rgba(0, 0, 0, 0), rgba(0, 0, 0, 0.72))"></div>`;
const topShade = `<div aria-hidden="true" style="position: absolute; left: 0; right: 0; top: 0; height: 300px; background: linear-gradient(rgba(0, 0, 0, 0.4), rgba(0, 0, 0, 0))"></div>`;

// C1 표지 피드
files.CoverFeed = page('표지 SNS 1 표지 피드', `<div style="${ROOT(`background: #C9D3DC; color: ${INK}`)}">
${cover('dana', 393, 852, 0.58, 0.5, '; position: absolute; left: 0; top: 0')}
${shade()}
${topBar(INK)}
${masthead('Esel', INK)}
${coverText('dana', { same: 187, likes: '128', comments: '12' })}
${capsule({ color: PEOPLE[ME].color })}
</div>`);

// C2 다음 표지 · 어두운 사진
files.CoverNext = page('표지 SNS 2 다음 표지', `<div style="${ROOT('background: #26252C; color: #FFFFFF')}">
${cover('theo', 393, 852, 0.5, 0.5, '; position: absolute; left: 0; top: 0')}
${topShade}
${shade()}
${topBar('#FFFFFF')}
${masthead('Esel', '#FFFFFF')}
${coverText('theo', { same: 96, likes: '211', comments: '18' })}
${capsule({ color: PEOPLE[ME].color })}
</div>`);

// C3 펼침면
const reader = (key, text) => `<div style="display: flex; gap: 10px; padding: 7px 0">
${avatar(key, 30)}
<div style="min-width: 0">
<div style="display: flex; align-items: center; gap: 6px; height: 18px"><span style="font-size: 14px; font-weight: 600">${key}</span>${paint(PEOPLE[key].color, 40, '', '')}<span style="font-size: 12px; color: ${MUTED}">${PAINT[PEOPLE[key].color].name}</span></div>
<p style="margin: 2px 0 0; font-size: 14.5px; line-height: 1.4">${text}</p>
</div>
</div>`;
files.CoverSpread = page('표지 SNS 3 펼침면', `<div style="${ROOT(`padding-top: 54px; display: flex; flex-direction: column; background: ${PAPER}; color: ${INK}`)}">
<header style="flex-shrink: 0; height: 48px; display: flex; align-items: center; justify-content: space-between; padding: 0 12px 0 6px">
<a href="CoverFeed.dc.html" aria-label="표지로 돌아가기" style="width: 48px; height: 48px; display: flex; align-items: center; justify-content: center">${icon('down', 24)}</a>
<span style="font-family: ${SERIF}; font-style: italic; font-size: 18px">dana · Nº 038</span>
<button type="button" style="height: 44px; display: flex; align-items: center">${pill('구독', INK)}</button>
</header>
<main style="flex: 1 1 0; min-height: 0; overflow: hidden; padding: 0 20px">
<div style="display: flex; align-items: baseline; justify-content: space-between; height: 30px; font-family: ${SERIF}; font-style: italic; font-size: 16px"><span>01</span><span>${PEOPLE.dana.time}</span></div>
<h1 style="margin: 6px 0 0; font-family: ${SERIF}; font-size: 34px; font-weight: 400; line-height: 1.22; letter-spacing: -0.01em">난간에 기대서,<br>셔츠 하나로.</h1>
<a href="CoverShelf.dc.html" style="height: 48px; display: flex; align-items: center; gap: 8px">${avatar('dana', 32)}<span style="margin-left: 2px; font-size: 15px; font-weight: 600">dana</span>${paint('powder', 48, '', '')}<span style="font-size: 13px; color: ${MUTED}">파우더 블루</span></a>
<div style="display: flex; gap: 8px; margin: 6px -20px 0 0; overflow: hidden">
${cover('dana', 210, 280, 0.58, 0.45, '; flex-shrink: 0; border-radius: 4px')}
${crop('dana', 210, 280, 2.6, 0.55, 0.8, 105, 140, { extra: '; flex-shrink: 0; border-radius: 4px', alt: '셔츠 끈 매듭과 데님 허리 부분' })}
</div>
<div style="display: flex; align-items: center; margin-left: -12px">
${stat('heart', '좋아요', '128', LIKE_ATTRS)}
${stat('bookmark', '스크랩', '34')}
</div>
<h2 style="margin: 4px 0 2px; display: flex; align-items: baseline; gap: 8px; font-family: ${SERIF}; font-size: 21px; font-weight: 400">독자 한 줄<span style="font-family: ${SANS}; font-size: 13px; color: ${MUTED}">12</span></h2>
${reader('zuri', '셔츠 끈 매듭이 다 했네요.')}
${reader('kofi', '하늘이랑 셔츠 색이 똑같아요.')}
${reader('riva', '파란 계열끼리 반가워요.')}
</main>
<div style="position: absolute; left: 16px; right: 16px; bottom: 34px">
<label for="one-line" style="position: absolute; width: 1px; height: 1px; overflow: hidden; clip-path: inset(50%)">한 줄 남기기</label>
<input id="one-line" type="text" placeholder="한 줄 남기기" class="esel-glass" style="width: 100%; height: 50px; box-sizing: border-box; padding: 0 20px; border: 0; border-radius: 25px; font-size: 15px">
</div>
</div>`);

// Small covers used on the stand and the shelf.
function miniCover({ key, w, h, mast = 'Esel', mastColor = '#FFFFFF', name = key, style = 'plain', px = 0.5, py = 0.5, href = 'CoverFeed.dc.html', label, fs }) {
  const size = fs ?? Math.round(w * 0.44);
  let img;
  if (style === 'neck') img = neckDown(key, w, h);
  else if (style === 'zoom') { const p = PEOPLE[key]; img = crop(key, w, h, 1.7, p.fx, p.fy, w / 2, h * 0.2); }
  else if (style === 'detail') img = crop(key, w, h, 2.4, 0.55, 0.8, w / 2, h / 2, { alt: `${PEOPLE[key].alt}의 디테일` });
  else if (style === 'mono') img = cover(key, w, h, px, py, '; filter: grayscale(1) contrast(1.06)');
  else img = `<span style="position: relative; display: block; width: ${w}px; height: ${h}px; overflow: hidden">${cover(key, w, h, px, py)}${style === 'paint' ? faceStroke(key, w, h, px, py) : ''}</span>`;
  return `<a href="${href}" aria-label="${label ?? `${name}의 표지 보기`}" style="position: relative; display: block; width: ${w}px; height: ${h}px; flex-shrink: 0; overflow: hidden; background: #EDEEEA; color: ${mastColor}; box-shadow: 0 4px 12px rgba(41, 42, 39, 0.16)">
${img}
<span aria-hidden="true" style="position: absolute; left: 0; right: 0; top: ${Math.round(h * 0.03)}px; text-align: center; font-family: ${SERIF}; font-size: ${size}px; line-height: 0.9; letter-spacing: -0.05em; padding-right: ${Math.round(size * 0.05)}px">${mast}</span>
<span aria-hidden="true" style="position: absolute; left: 0; right: 0; bottom: 0; height: 40%; background: linear-gradient(rgba(0, 0, 0, 0), rgba(0, 0, 0, 0.55))"></span>
${name ? `<span style="position: absolute; left: ${Math.round(w * 0.06)}px; bottom: ${Math.round(h * 0.035)}px; color: #FFFFFF; font-family: ${SERIF}; font-style: italic; font-size: ${Math.round(size * 0.34)}px; line-height: 1">${name}</span>` : ''}
</a>`;
}

// C4 가판대
const chip = (label, color, active = false) => `<button type="button" aria-pressed="${active}" style="height: 44px; flex-shrink: 0; display: flex; align-items: center"><span style="height: 38px; padding: 0 ${color ? '14px 0 8px' : '16px'}; border-radius: 19px; display: flex; align-items: center; gap: 4px; font-size: 14px; font-weight: 500; white-space: nowrap; ${active ? `background: ${INK}; color: ${PAPER}` : 'background: #FFFFFF; box-shadow: inset 0 0 0 1px #E0E1DC'}">${color ? paint(color, 40, '', '') : ''}<span>${label}</span></span></button>`;
const shelfRow = (a, b) => `<div style="flex-shrink: 0; display: flex; justify-content: space-between; padding: 0 16px">${miniCover({ ...a, w: 174, h: 250 })}${miniCover({ ...b, w: 174, h: 250 })}</div>
<span aria-hidden="true" style="flex-shrink: 0; height: 2px; margin-bottom: 16px; background: ${INK}"></span>`;
files.CoverStand = page('표지 SNS 4 가판대', `<div style="${ROOT(`padding-top: 54px; display: flex; flex-direction: column; background: ${PAPER}; color: ${INK}`)}">
<header style="flex-shrink: 0; height: 48px; display: flex; align-items: baseline; justify-content: space-between; padding: 8px 18px 0; box-sizing: border-box">
<h1 style="margin: 0; font-family: ${SERIF}; font-size: 32px; font-weight: 400; line-height: 1">가판대</h1>
<span style="font-family: ${SERIF}; font-style: italic; font-size: 17px">9. 6. 일요일</span>
</header>
<div style="flex-shrink: 0; display: flex; gap: 8px; padding: 4px 16px 10px; overflow: hidden">
${chip('전체', null, true)}
${COLOR_ORDER.map((c) => chip(PAINT[c].name, c)).join('\n')}
</div>
${shelfRow({ key: 'ama', py: 0.3 }, { key: 'lise', style: 'paint', py: 0.3 })}
${shelfRow({ key: 'kofi', mastColor: INK, px: 0.7, py: 0.2 }, { key: 'riva', py: 0.3 })}
${shelfRow({ key: 'maya', style: 'neck', mastColor: INK }, { key: 'selin', mastColor: INK, py: 0.5 })}
${capsule({ color: PEOPLE[ME].color })}
</div>`);

// C5 서가 · dana의 잡지. 호수는 발행할 때만 1씩 오르므로 결호 없이 이어진다.
const ISSUES = 38;
const DARK_SPINE = new Set(['burgundy', 'olive', 'charcoal', 'cobalt', 'terracotta']);
const OLDER_COLORS = ['coral', 'sage', 'butter', 'cobalt', 'cream', 'powder', 'lilac', 'camel', 'olive', 'powder', 'terracotta', 'charcoal', 'sage', 'powder', 'burgundy', 'butter', 'powder', 'coral', 'cream', 'powder'];
const issueDate = (i) => { const d = new Date(Date.UTC(2026, 8, 6 - Math.floor(i * 1.6))); return `${d.getUTCMonth() + 1}. ${d.getUTCDate()}.`; };
const shelfIssues = Array.from({ length: 26 }, (_, i) => ({ no: String(ISSUES - i).padStart(3, '0'), color: i < 6 ? 'powder' : OLDER_COLORS[(i - 6) % OLDER_COLORS.length], date: issueDate(i) }));
const issue = (style, i) => { const it = shelfIssues[i]; return `<div style="width: 113px">
${miniCover({ key: 'dana', w: 113, h: 166, mast: 'dana', mastColor: INK, name: '', style, px: 0.58, py: 0.5, fs: 46, label: `Nº ${it.no} 표지 보기` })}
<div style="height: 26px; display: flex; align-items: center; justify-content: space-between; font-family: ${MONO}; font-size: 11px"><span>Nº ${it.no}</span><span style="width: 22px; height: 4px; border-radius: 2px; background: ${PAINT[it.color].hex}"></span></div>
</div>`; };
const spine = (it) => `<a href="CoverShelf.dc.html" aria-label="Nº ${it.no} · ${PAINT[it.color].name} · ${it.date}" style="width: 22px; height: 196px; flex-shrink: 0; box-sizing: border-box; padding: 8px 0; display: flex; flex-direction: column; align-items: center; justify-content: space-between; background: ${PAINT[it.color].hex}; color: ${DARK_SPINE.has(it.color) ? '#FFFFFF' : INK}; box-shadow: inset -1px 0 0 rgba(0, 0, 0, 0.12), inset 1px 0 0 rgba(255, 255, 255, 0.35)"><span style="writing-mode: vertical-rl; font-family: ${SERIF}; font-style: italic; font-size: 13px; line-height: 1">dana</span><span style="writing-mode: vertical-rl; font-family: ${MONO}; font-size: 10px; letter-spacing: 0.04em">Nº ${it.no}</span></a>`;
const spineRow = (items) => `<div style="display: flex; gap: 5px; align-items: flex-end">${items.map(spine).join('')}</div>
<span aria-hidden="true" style="display: block; height: 2px; margin: 0 0 18px; background: ${INK}"></span>`;
const viewBtn = (label, key) => `<button type="button" aria-pressed="{{${key}Pressed}}" onClick="{{show_${key}}}" style="height: 44px; padding: 0 8px; font-size: 14px; font-weight: {{${key}Weight}}; color: {{${key}Color}}">${label}</button>`;
files.CoverShelf = page('표지 SNS 5 서가', `<div style="${ROOT(`padding-top: 54px; display: flex; flex-direction: column; background: ${PAPER}; color: ${INK}`)}">
<header style="flex-shrink: 0; height: 48px; display: flex; align-items: center; justify-content: space-between; padding: 0 18px 0 6px">
<a href="CoverFeed.dc.html" aria-label="표지로 돌아가기" style="width: 48px; height: 48px; display: flex; align-items: center; justify-content: center">${icon('left', 24)}</a>
<span style="font-family: ${MONO}; font-size: 12px">ESEL · 개인 잡지</span>
</header>
<div style="flex-shrink: 0; padding: 0 20px">
<h1 style="margin: 0; font-family: ${SERIF}; font-style: italic; font-weight: 400; font-size: 92px; line-height: 0.85; letter-spacing: -0.03em">dana</h1>
<div style="display: flex; align-items: center; justify-content: space-between; margin-top: 14px">
<div style="display: flex; flex-direction: column; gap: 2px">
<div style="display: flex; align-items: center; gap: 6px; font-size: 14px">${paint('powder', 52, '', '')}<span>오늘은 파우더 블루</span></div>
<span style="font-size: 14px; color: ${MUTED}">${ISSUES}호 · 구독자 214</span>
</div>
<button type="button" style="height: 44px; padding: 0 24px; border-radius: 22px; background: ${INK}; color: ${PAPER}; font-size: 15px; font-weight: 600">구독</button>
</div>
</div>
<div style="flex-shrink: 0; margin: 14px 20px 10px; border-bottom: 2px solid ${INK}; display: flex; align-items: center; justify-content: space-between">
<h2 style="margin: 0; font-family: ${SERIF}; font-size: 21px; font-weight: 400">지난 호</h2>
<div role="group" aria-label="지난 호 보기" style="display: flex; margin-right: -8px">${viewBtn('표지', 'covers')}${viewBtn('책등', 'spines')}</div>
</div>
<main style="flex: 1 1 0; min-height: 0; overflow: hidden; padding: 0 20px">
<div style="display: {{vCovers}}; flex-wrap: wrap; justify-content: space-between; row-gap: 8px">
${issue('plain', 0)}
${issue('paint', 1)}
${issue('zoom', 2)}
${issue('neck', 3)}
${issue('detail', 4)}
${issue('mono', 5)}
</div>
<div style="display: {{vSpines}}; flex-direction: column; padding-top: 6px">
${spineRow(shelfIssues.slice(0, 13))}
${spineRow(shelfIssues.slice(13, 26))}
</div>
</main>
${capsule({ color: PEOPLE[ME].color })}
</div>`, { logic: `const view = (this.state && this.state.view) || 'covers';
for (const k of ['covers', 'spines']) {
const on = view === k;
vals[k + 'Pressed'] = on ? 'true' : 'false';
vals[k + 'Weight'] = on ? '600' : '400';
vals[k + 'Color'] = on ? '${INK}' : '${MUTED}';
vals['show_' + k] = () => this.setState({ view: k });
}
vals.vCovers = view === 'covers' ? 'flex' : 'none';
vals.vSpines = view === 'spines' ? 'flex' : 'none';` });

// C6 표지 만들기 · 얼굴 연출과 제호 색
const MK = { W: 236, H: 350 };
const me = PEOPLE[ME];
const mkFace = `<span style="position: absolute; left: 0; top: 0; display: {{vPlain}}">${cover(ME, MK.W, MK.H, 0.5, 0.5)}</span>
<span style="position: absolute; left: 0; top: 0; width: ${MK.W}px; height: ${MK.H}px; display: {{vPaint}}">${cover(ME, MK.W, MK.H, 0.5, 0.5)}${faceStroke(ME, MK.W, MK.H, 0.5, 0.5)}</span>
<span style="position: absolute; left: 0; top: 0; display: {{vZoom}}">${crop(ME, MK.W, MK.H, 1.9, me.fx, me.fy, MK.W / 2, MK.H * 0.17)}</span>
<span style="position: absolute; left: 0; top: 0; display: {{vNeck}}">${neckDown(ME, MK.W, MK.H)}</span>
<span aria-hidden="true" style="position: absolute; left: 0; right: 0; top: 0; height: 45%; background: linear-gradient(rgba(0, 0, 0, 0.4), rgba(0, 0, 0, 0))"></span>`;
const seg = (label, key, hole) => `<button type="button" aria-pressed="{{${hole}Pressed}}" onClick="{{pick${hole}}}" style="height: 44px; flex: 1 1 0; display: flex; align-items: center"><span style="width: 100%; height: 36px; border-radius: 18px; display: flex; align-items: center; justify-content: center; font-size: 14px; font-weight: 600; background: {{${hole}Bg}}; color: {{${hole}Fg}}; box-shadow: inset 0 0 0 1.5px ${INK}">${label}</span></button>`;
files.CoverMake = page('표지 SNS 6 표지 만들기', `<div style="${ROOT(`padding-top: 54px; background: ${PAPER}; color: ${INK}`)}">
<header style="height: 48px; display: flex; align-items: center; justify-content: space-between; padding: 0 18px 0 6px">
<a href="CoverFeed.dc.html" aria-label="닫기" style="width: 48px; height: 48px; display: flex; align-items: center; justify-content: center">${icon('x', 24)}</a>
<h1 style="margin: 0; font-size: 16px; font-weight: 600">오늘 호 만들기</h1>
<span style="font-family: ${SERIF}; font-style: italic; font-size: 18px">Nº 012</span>
</header>
<div style="position: absolute; left: ${(393 - MK.W) / 2}px; top: 104px; width: ${MK.W}px; height: ${MK.H}px; overflow: hidden; background: #EDEEEA; color: {{mastColor}}; box-shadow: 0 14px 36px rgba(41, 42, 39, 0.2)">
${mkFace}
<span aria-hidden="true" style="position: absolute; left: 10px; right: 10px; top: 8px; display: flex; justify-content: space-between; font-family: ${MONO}; font-size: 8px; letter-spacing: 0.06em"><span>ESEL</span><span>Nº 012 · 9. 6.</span></span>
<span aria-hidden="true" style="position: absolute; left: 0; right: 0; top: 18px; text-align: center; font-family: ${SERIF}; font-size: ${mastSize(ME, MK.W, 128)}px; line-height: 0.9; letter-spacing: -0.05em; padding-right: 6px">${ME}</span>
<span aria-hidden="true" style="position: absolute; left: 0; right: 0; bottom: 0; height: 40%; background: linear-gradient(rgba(0, 0, 0, 0), rgba(0, 0, 0, 0.5))"></span>
<span style="position: absolute; left: 14px; bottom: 14px; color: #FFFFFF; font-size: 12px; font-weight: 500">${me.cap}</span>
</div>
<div style="position: absolute; left: 20px; right: 20px; top: 466px; display: flex; flex-direction: column">
<span style="font-size: 12px; color: ${MUTED}">얼굴</span>
<div role="group" aria-label="얼굴 연출" style="display: flex; gap: 6px; margin-top: 2px">
${seg('그대로', 'plain', 'Plain')}
${seg('물감', 'paint', 'Paint')}
${seg('제호 뒤', 'zoom', 'Zoom')}
${seg('목 아래', 'neck', 'Neck')}
</div>
<div style="display: flex; align-items: center; gap: 6px; margin-top: 10px">
<span style="font-size: 14px; margin-right: 6px">제호 색</span>
<div role="group" aria-label="제호 색" style="display: flex; gap: 6px; width: 140px">
${seg('먹', 'ink', 'Ink')}
${seg('흰', 'white', 'White')}
</div>
<span style="margin-left: auto; display: flex; align-items: center; gap: 4px; font-size: 14px">${paint(me.color, 52, '', '')}<span>${PAINT[me.color].name}</span></span>
</div>
<label for="cover-line" style="margin-top: 12px; font-size: 12px; line-height: 16px; color: ${MUTED}">표지 문구</label>
<input id="cover-line" type="text" value="${me.cap}" style="height: 44px; box-sizing: border-box; padding: 0; border: 0; border-bottom: 1.5px solid ${INK}; border-radius: 0; background: transparent; font-size: 17px">
</div>
<a href="CoverFeed.dc.html" style="position: absolute; left: 20px; right: 20px; bottom: 46px; height: 56px; border-radius: 28px; display: flex; align-items: center; justify-content: center; background: ${INK}; color: ${PAPER}; font-size: 16px; font-weight: 600">발행</a>
</div>`, { logic: `const face = (this.state && this.state.face) || 'plain';
const white = !(this.state && this.state.white === false);
const on = (k) => face === k;
const show = (b) => (b ? 'block' : 'none');
vals.vPlain = show(on('plain'));
vals.vPaint = show(on('paint'));
vals.vZoom = show(on('zoom'));
vals.vNeck = show(on('neck'));
const segVals = (name, active, pick) => {
vals[name + 'Pressed'] = active ? 'true' : 'false';
vals[name + 'Bg'] = active ? '${INK}' : 'transparent';
vals[name + 'Fg'] = active ? '${PAPER}' : '${INK}';
vals['pick' + name] = pick;
};
segVals('Plain', on('plain'), () => this.setState({ face: 'plain' }));
segVals('Paint', on('paint'), () => this.setState({ face: 'paint' }));
segVals('Zoom', on('zoom'), () => this.setState({ face: 'zoom' }));
segVals('Neck', on('neck'), () => this.setState({ face: 'neck' }));
segVals('Ink', !white, () => this.setState({ white: false }));
segVals('White', white, () => this.setState({ white: true }));
vals.mastColor = white ? '#FFFFFF' : '${INK}';` });

// C7 스크롤 시안 · 첫 장만 표지
const inner = ({ key, no, style = 'plain', px = 0.5, py = 0.3, likes }) => {
  const p = PEOPLE[key];
  let img;
  if (style === 'neck') img = neckDown(key, 393, 500);
  else img = `<span style="position: relative; display: block; width: 393px; height: 500px; overflow: hidden; background: #EDEEEA">${cover(key, 393, 500, px, py)}${style === 'paint' ? faceStroke(key, 393, 500, px, py) : ''}</span>`;
  return `<article style="padding-bottom: 22px">
<div style="display: flex; align-items: baseline; justify-content: space-between; padding: 16px 18px 8px; font-family: ${SERIF}; font-style: italic; font-size: 16px"><span>${no}</span><span>${p.time}</span></div>
${img}
<div style="display: flex; align-items: center; gap: 8px; padding: 4px 6px 0 18px">
<span style="font-size: 18px; font-weight: 600">${key}</span>
${paint(p.color, 54, '', '')}
<span style="font-size: 13px; color: ${MUTED}">${PAINT[p.color].name}</span>
<span style="margin-left: auto; display: flex">${stat('heartPlain', '좋아요', likes)}${stat('bookmark', '스크랩', '')}</span>
</div>
<p style="margin: 0; padding: 0 18px; font-size: 15px; line-height: 1.45">${p.cap}</p>
</article>`;
};
const innerPages = [
  inner({ key: 'ama', no: '02', py: 0.3, likes: '96' }),
  inner({ key: 'lise', no: '03', style: 'paint', py: 0.25, likes: '88' }),
  inner({ key: 'kofi', no: '04', px: 0.65, py: 0.15, likes: '74' }),
  inner({ key: 'rio', no: '05', py: 0.4, likes: '61' }),
  inner({ key: 'omar', no: '06', style: 'neck', likes: '58' }),
  inner({ key: 'riva', no: '07', py: 0.25, likes: '52' }),
].join('\n');
const scrollCover = ({ withTabs = true } = {}) => `<section aria-label="오늘의 표지" style="position: relative; height: 800px; overflow: hidden; background: #C9D3DC">
${cover('dana', 393, 800, 0.58, 0.5, '; position: absolute; left: 0; top: 0')}
${shade(460)}
${topBar(INK, { withTabs })}
<h1 style="position: absolute; width: 1px; height: 1px; overflow: hidden; clip-path: inset(50%); margin: 0">Esel 오늘의 표지</h1>
${coverText('dana', { same: 187, likes: '128', comments: '12', bottom: 52 })}
</section>`;
const sc = scrollLogic();
files.CoverScroll = page('표지 SNS 7 스크롤 시안', `<div style="${ROOT(`background: ${PAPER}; color: ${INK}`)}">
<div class="esel-scroll" ref="{{setScroller}}" onScroll="{{onScroll}}" style="position: absolute; left: 0; top: 0; width: 100%; height: 100%; overflow-y: auto; overscroll-behavior: contain; scrollbar-width: none">
${scrollCover()}
${innerPages}
<div aria-hidden="true" style="height: 110px"></div>
</div>
${mastLayer}
${capsule({ color: PEOPLE[ME].color })}
</div>`, sc);

for (const [name, html] of Object.entries(files)) fs.writeFileSync(path.join(OUT, `${name}.dc.html`), html);
export { scrollCover, innerPages, inner, coverText, topBar, shade, miniCover };
console.log('ok', Object.entries(files).map(([n, h]) => `${n}:${h.length}`).join(' '));
