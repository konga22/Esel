// Cover-SNS screens (C1–C8): home feed, detail with garment info, palette (explore), sketchbook, make.
// Structure follows a familiar SNS (home feed + explore tab, 10-18); screens keep the magazine look and the words are art tools.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { mastSize, SANS, SERIF, MONO, INK, PAPER, MUTED, HAIR, PAINT, PEOPLE, ME, COLOR_ORDER, TODAY_CANDIDATES, ROOT, cover, fit, faceStroke, cropStroke, cropFace, neckDown, crop, avatar, paint, icon, stat, LIKE_ATTRS, pill, masthead, capsule, tagDot, wearPill, page } from './lib.mjs';
import { mastLayer, scrollLogic } from './scroll.mjs';
import { adopted } from './gen-explore.mjs';

const OUT = path.join(path.dirname(fileURLToPath(import.meta.url)), 'project');
const files = {};
// Home is one feed mixing subscriptions and recommendations, so it has no 전체/구독 tabs (10-18; subscriptions live in the palette).
const topBar = (fg, { issue = 249, home = true } = {}) => `<div style="position: absolute; left: 14px; right: 20px; top: 48px; height: 44px; display: flex; align-items: center; justify-content: space-between; color: ${fg}; font-size: 13px; font-weight: 600; letter-spacing: 0.04em">
${home ? '<span></span>' : '<span style="padding-left: 6px">오늘의 표지</span>'}
<span style="font-size: 12px">Nº ${issue} · 2026. 9. 6.</span>
</div>`;
// How many garments each example post tagged (garment info is optional, P19 draft).
const WEAR = { dana: 3, theo: 2, ama: 2, kofi: 4, riva: 2 };
const wearLink = (n, extra = '') => `<a href="CoverSpread.dc.html" aria-label="착용 정보 ${n}개 보기" style="height: 44px; display: flex; align-items: center${extra}">${wearPill(n)}</a>`;
// Popularity counts (likes, one-lines, subscribers) are shown only to the publisher, never on others' covers.
const coverText = (key, { same, bottom = 100 }) => {
  const p = PEOPLE[key];
  return `<div style="position: absolute; left: 20px; right: 8px; bottom: ${bottom}px; color: #FFFFFF">
<div style="display: flex; align-items: flex-end; gap: 12px">
<a href="CoverShelf.dc.html" style="font-family: ${SERIF}; font-style: italic; font-size: 76px; line-height: 0.9; letter-spacing: -0.03em">${key}</a>
<button type="button" style="height: 44px; display: flex; align-items: center">${pill('구독', '#FFFFFF')}</button>
${WEAR[key] ? wearLink(WEAR[key], '; margin-left: auto; padding-right: 4px') : ''}
</div>
<a href="CoverStand.dc.html" style="height: 44px; margin-top: 4px; display: flex; align-items: center; gap: 8px; font-size: 14px; font-weight: 600">${paint(p.color, 60)}<span>${PAINT[p.color].name} · 같은 색 ${same}명</span>${icon('arrow', 18, 1.8)}</a>
<p style="margin: 0; font-size: 15px; line-height: 1.45">${p.cap}</p>
<div style="display: flex; align-items: center; margin: 2px 0 0 -12px">
${stat('heart', '좋아요', '', LIKE_ATTRS)}
${stat('comment', '한 줄', '')}
${stat('bookmark', '저장', '')}
<a href="CoverSpread.dc.html" style="margin-left: auto; height: 48px; padding: 0 12px; display: flex; align-items: center; gap: 4px; font-size: 14px; font-weight: 600"><span>자세히 보기</span>${icon('up', 20, 1.8)}</a>
</div>
</div>`;
};
const shade = (h = 480) => `<div aria-hidden="true" style="position: absolute; left: 0; right: 0; bottom: 0; height: ${h}px; background: linear-gradient(rgba(0, 0, 0, 0), rgba(0, 0, 0, 0.72))"></div>`;
const topShade = `<div aria-hidden="true" style="position: absolute; left: 0; right: 0; top: 0; height: 300px; background: linear-gradient(rgba(0, 0, 0, 0.4), rgba(0, 0, 0, 0))"></div>`;

// C1 홈 피드
files.CoverFeed = page('표지 SNS 1 홈 피드', `<div style="${ROOT(`background: #C9D3DC; color: ${INK}`)}">
${cover('dana', 393, 852, 0.58, 0.5, '; position: absolute; left: 0; top: 0')}
${shade()}
${topBar(INK)}
${masthead('Esel', INK)}
${coverText('dana', { same: 187 })}
${capsule({ color: PEOPLE[ME].color, active: 'home' })}
</div>`);

// C2 홈 · 다음 표지 · 어두운 사진
files.CoverNext = page('표지 SNS 2 홈 · 다음 표지', `<div style="${ROOT('background: #26252C; color: #FFFFFF')}">
${cover('theo', 393, 852, 0.5, 0.5, '; position: absolute; left: 0; top: 0')}
${topShade}
${shade()}
${topBar('#FFFFFF')}
${masthead('Esel', '#FFFFFF')}
${coverText('theo', { same: 96 })}
${capsule({ color: PEOPLE[ME].color, active: 'home' })}
</div>`);

// C3 자세히 보기 · 착용 정보
// Garments: kind, optional name or brand, optional note, whether it carries the color of the day, and where it sits on the photo (fractions).
// No price, no shopping link (P19 draft).
const GARMENTS = {
  dana: [
    { kind: '셔츠', name: '크롭 셔츠', note: '직접 줄여 입음', today: true, at: [0.6, 0.63] },
    { kind: '데님', name: '끈 장식 와이드', note: '빈티지', at: [0.52, 0.87] },
    { kind: '반지', note: '물려받음', at: [0.3, 0.71] },
  ],
};
const garmentRow = (g, color) => `<li style="min-height: 42px; display: flex; align-items: center; gap: 10px; border-bottom: 1px solid ${HAIR}">
<span style="width: 48px; flex-shrink: 0; font-size: 14px; font-weight: 600">${g.kind}</span>
<span style="flex: 1 1 0; min-width: 0; font-size: 14px; line-height: 1.35">${[g.name, g.note && `<span style="color: ${MUTED}">${g.note}</span>`].filter(Boolean).join(`<span style="color: ${MUTED}"> · </span>`)}</span>
${g.today ? `<span style="flex-shrink: 0; display: flex; align-items: center; gap: 2px; font-size: 12px; color: ${MUTED}">${paint(color, 40, '', '')}<span>${PAINT[color].name}</span></span>` : ''}
</li>`;
const reader = (key, text) => `<div style="display: flex; gap: 10px; padding: 7px 0">
${avatar(key, 30)}
<div style="min-width: 0">
<div style="display: flex; align-items: center; gap: 6px; height: 18px"><span style="font-size: 14px; font-weight: 600">${key}</span>${paint(PEOPLE[key].color, 40, '', '')}<span style="font-size: 12px; color: ${MUTED}">${PAINT[PEOPLE[key].color].name}</span></div>
<p style="margin: 2px 0 0; font-size: 14.5px; line-height: 1.4">${text}</p>
</div>
</div>`;
const SP = { W: 236, H: 290, px: 0.58, py: 0.72 };
const spreadPhoto = (() => {
  const f = fit('dana', SP.W, SP.H, SP.px, SP.py);
  const dots = GARMENTS.dana.map((g) => tagDot(g.at[0] * f.dw - f.ox, g.at[1] * f.dh - f.oy)).join('');
  return `<span style="position: relative; display: block; width: ${SP.W}px; height: ${SP.H}px; flex-shrink: 0; overflow: hidden; border-radius: 4px">${cover('dana', SP.W, SP.H, SP.px, SP.py)}${dots}<span style="position: absolute; right: 8px; bottom: 8px">${wearPill(GARMENTS.dana.length)}</span></span>`;
})();
files.CoverSpread = page('표지 SNS 3 자세히 보기', `<div style="${ROOT(`padding-top: 54px; display: flex; flex-direction: column; background: ${PAPER}; color: ${INK}`)}">
<header style="flex-shrink: 0; height: 48px; display: flex; align-items: center; justify-content: space-between; padding: 0 12px 0 6px">
<a href="CoverFeed.dc.html" aria-label="표지로 돌아가기" style="width: 48px; height: 48px; display: flex; align-items: center; justify-content: center">${icon('down', 24)}</a>
<span style="font-family: ${SERIF}; font-style: italic; font-size: 18px">dana · Nº 038</span>
<button type="button" style="height: 44px; display: flex; align-items: center">${pill('구독', INK)}</button>
</header>
<main style="flex: 1 1 0; min-height: 0; overflow: hidden; padding: 0 20px">
<div style="display: flex; align-items: baseline; justify-content: space-between; height: 28px; font-family: ${SERIF}; font-style: italic; font-size: 16px"><span>01</span><span>${PEOPLE.dana.time}</span></div>
<h1 style="margin: 2px 0 0; font-family: ${SERIF}; font-size: 30px; font-weight: 400; line-height: 1.2; letter-spacing: -0.01em">난간에 기대서,<br>셔츠 하나로.</h1>
<div style="height: 48px; display: flex; align-items: center; gap: 8px">
<a href="CoverShelf.dc.html" style="height: 48px; display: flex; align-items: center; gap: 8px">${avatar('dana', 28)}<span style="font-size: 15px; font-weight: 600">dana</span>${paint('powder', 44, '', '')}<span style="font-size: 13px; color: ${MUTED}">파우더 블루</span></a>
<span style="margin: 0 -12px 0 auto; display: flex">${stat('heart', '좋아요', '', LIKE_ATTRS)}${stat('bookmark', '저장', '')}</span>
</div>
<div style="display: flex; gap: 8px; margin: 4px -20px 0 0; overflow: hidden">
${spreadPhoto}
${crop('dana', 210, SP.H, 2.6, 0.55, 0.8, 105, 145, { extra: '; flex-shrink: 0; border-radius: 4px', alt: '셔츠 끈 매듭과 데님 허리 부분' })}
</div>
<h2 style="margin: 14px 0 2px; font-family: ${SERIF}; font-size: 21px; font-weight: 400">착용 정보</h2>
<ul style="margin: 0; padding: 0; list-style: none">
${GARMENTS.dana.map((g) => garmentRow(g, 'powder')).join('\n')}
</ul>
<h2 style="margin: 14px 0 2px; font-family: ${SERIF}; font-size: 21px; font-weight: 400">한 줄</h2>
${reader('zuri', '셔츠 끈 매듭이 다 했네요.')}
${reader('kofi', '하늘이랑 셔츠 색이 똑같아요.')}
</main>
<div style="position: absolute; left: 16px; right: 16px; bottom: 34px">
<label for="one-line" style="position: absolute; width: 1px; height: 1px; overflow: hidden; clip-path: inset(50%)">한 줄 남기기</label>
<input id="one-line" type="text" placeholder="한 줄 남기기" class="esel-glass" style="width: 100%; height: 50px; box-sizing: border-box; padding: 0 20px; border: 0; border-radius: 25px; font-size: 15px">
</div>
</div>`);

// Small covers (with a sign) used on the boards.
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

// ───────── 팔레트 (탐색). 작은 3열 격자: 2px 간격, 3:4 칸, 두 줄마다 세로로 긴 칸 하나를 좌우 번갈아.
// Cells carry no number. Each is the owner's cover scaled down, keeping the face choice they made.
const GRID = { cols: [130, 129, 130], gap: 2, cell: 173 };
GRID.x = [0, GRID.cols[0] + GRID.gap, GRID.cols[0] + GRID.cols[1] + GRID.gap * 2];
GRID.tall = GRID.cell * 2 + GRID.gap;
GRID.block = GRID.tall + GRID.gap;
// Horizontal crop that keeps the face in the cell.
const faceX = (key, w, h) => { const f = fit(key, w, h, 0, 0); return f.dw > w ? Math.max(0, Math.min(1, (f.fx - w / 2) / (f.dw - w))) : 0.5; };
// A palette cell is the owner's cover, only smaller: the photo with the face choice they made and their sign on top,
// scaled to the cell (10-18). "Behind the sign" still hides the face because the sign shrinks with the cell.
// For "as is" the sign shrinks further so it never touches the face, the same rule as the big cover.
function tileImg({ key, w, h, style = 'plain', py = 0.3, mastColor = '#FFFFFF' }) {
  const p = PEOPLE[key];
  const full = mastSize(key, w, Math.round(w * 0.44));
  const top = Math.round(h * 0.025);
  let img;
  let size = full;
  if (style === 'neck') img = neckDown(key, w, h);
  else if (style === 'behind') img = crop(key, w, h, 1.7, p.fx, p.fy, w / 2, top + full * 0.55);
  else {
    const px = faceX(key, w, h);
    img = `<span style="position: relative; display: block; width: ${w}px; height: ${h}px; overflow: hidden">${cover(key, w, h, px, py)}${style === 'paint' ? faceStroke(key, w, h, px, py) : ''}</span>`;
    if (style === 'plain') {
      const f = fit(key, w, h, px, py);
      size = Math.max(Math.round(full * 0.62), Math.min(full, Math.floor((f.fy - f.fwPx * 0.6 - top) / 0.9)));
    }
  }
  return `<span style="position: relative; display: block; width: ${w}px; height: ${h}px; overflow: hidden">${img}
<span aria-hidden="true" style="position: absolute; left: 0; right: 0; top: 0; height: 38%; background: linear-gradient(rgba(0, 0, 0, 0.26), rgba(0, 0, 0, 0))"></span>
<span aria-hidden="true" style="position: absolute; left: 0; right: 0; top: ${top}px; text-align: center; font-family: ${SERIF}; font-size: ${size}px; line-height: 0.9; letter-spacing: -0.05em; padding-right: ${Math.round(size * 0.05)}px; color: ${mastColor}; white-space: nowrap">${key}</span></span>`;
}
const tile = (it, x, y, w, h) => `<a href="${it.href ?? 'CoverShelf.dc.html'}" aria-label="${it.key}의 스케치북" style="position: absolute; left: ${x}px; top: ${y}px; width: ${w}px; height: ${h}px; overflow: hidden; background: #EDEEEA">${tileImg({ ...it, w, h })}</a>`;
// One block = two rows with one tall cell (right or left) and four small cells.
function gridBlock(items, top, tallLeft, draw = tile) {
  const [a, b, c, d, e] = items;
  const { x, cols, cell, tall, gap } = GRID;
  const r2 = top + cell + gap;
  if (tallLeft) return [draw(a, x[0], top, cols[0], tall), draw(b, x[1], top, cols[1], cell), draw(c, x[2], top, cols[2], cell), draw(d, x[1], r2, cols[1], cell), draw(e, x[2], r2, cols[2], cell)].join('\n');
  return [draw(a, x[0], top, cols[0], cell), draw(b, x[1], top, cols[1], cell), draw(c, x[2], top, cols[2], tall), draw(d, x[0], r2, cols[0], cell), draw(e, x[1], r2, cols[1], cell)].join('\n');
}

// C4 팔레트 · 추천 and C8 카멜 방 come from the adopted layouts in gen-explore.mjs (R5-4, 10-18); see the end of this file.

// The color list (used by the "모든 색" sample on the components board). LOCK.color marks my color as the current one.
const LOCK = { color: PEOPLE[ME].color };
// Color list: my three candidates (locked before I post, mine first), then the rest in an assumed "picked most today" order. No numbers.
const PICK_ORDER = ['powder', 'butter', 'cobalt', 'coral', 'sage', 'cream', 'charcoal', 'terracotta', 'burgundy'];
const myCandidates = [PEOPLE[ME].color, ...TODAY_CANDIDATES.filter((c) => c !== PEOPLE[ME].color)];
const colorList = [...myCandidates, ...PICK_ORDER.filter((c) => !myCandidates.includes(c)), ...COLOR_ORDER.filter((c) => !myCandidates.includes(c) && !PICK_ORDER.includes(c))];
const colorRow = (c) => {
  const locked = myCandidates.includes(c);
  const current = c === LOCK.color;
  return `<button type="button" onClick="{{closeList}}" aria-label="${PAINT[c].name}${locked ? ' · 올리기 전이라 세 장만 먼저 보여요' : ''}"${current ? ' aria-current="true"' : ''} style="width: calc(100% - 12px); height: 48px; margin: 0 6px; box-sizing: border-box; padding: 0 8px 0 4px; border-radius: 10px; display: flex; align-items: center; gap: 4px; font-size: 15px; font-weight: ${current ? 600 : 500}; background: ${current ? '#F1F1EE' : 'transparent'}">${paint(c, 44, '', '')}<span>${PAINT[c].name}</span><span style="margin-left: auto; display: flex; align-items: center; gap: 8px">${locked ? icon('lock', 15, 1.8) : ''}<span style="width: 18px; display: flex">${current ? icon('check', 18, 2) : ''}</span></span></button>`;
};
// C5 스케치북 · dana. 팔레트 격자에서 사람을 누르면 온다. 그 사람의 사진이 최신부터 세로로 이어진다.
// Issue numbers rise only by posting, so they run without gaps (P04).
const ISSUES = 38;
const issueDate = (i) => { const d = new Date(Date.UTC(2026, 8, 6 - Math.floor(i * 1.6))); return `${d.getUTCMonth() + 1}. ${d.getUTCDate()}.`; };
const SK = { H: 420 };
const iconBtn = (name, label, attrs = '') => `<button type="button" aria-label="${label}"${attrs} style="width: 44px; height: 44px; display: flex; align-items: center; justify-content: center">${icon(name, 23)}</button>`;
const sketchPost = ({ i, style = 'plain', py = 0.62, cap, wear }) => {
  const key = 'dana';
  const color = PEOPLE[key].color;
  const img = style === 'neck' ? neckDown(key, 393, SK.H)
    : `<span style="position: relative; display: block; width: 393px; height: ${SK.H}px; overflow: hidden; background: #EDEEEA">${cover(key, 393, SK.H, 0.58, py)}${style === 'paint' ? faceStroke(key, 393, SK.H, 0.58, py) : ''}</span>`;
  return `<article style="padding-bottom: 18px">
<div style="position: relative">${img}${wear ? `<span style="position: absolute; right: 10px; bottom: 4px">${wearLink(wear)}</span>` : ''}</div>
<div style="height: 48px; display: flex; align-items: center; gap: 6px; padding: 0 6px 0 18px">
<span style="font-family: ${MONO}; font-size: 12px; letter-spacing: 0.06em">Nº ${String(ISSUES - i).padStart(3, '0')} · ${issueDate(i)}</span>
${paint(color, 44, '; margin-left: 4px', '')}
<span style="font-size: 13px; color: ${MUTED}">${PAINT[color].name}</span>
<span style="margin-left: auto; display: flex">${i === 0 ? iconBtn('heart', '좋아요', LIKE_ATTRS) : iconBtn('heartPlain', '좋아요')}${iconBtn('comment', '한 줄')}${iconBtn('bookmark', '저장')}</span>
</div>
<p style="margin: 0; padding: 0 18px; font-size: 15px; line-height: 1.45">${cap}</p>
</article>`;
};
files.CoverShelf = page('표지 SNS 5 스케치북', `<div style="${ROOT(`padding-top: 54px; display: flex; flex-direction: column; background: ${PAPER}; color: ${INK}`)}">
<header style="flex-shrink: 0; height: 48px; display: flex; align-items: center; justify-content: space-between; padding: 0 18px 0 6px">
<a href="CoverStand.dc.html" aria-label="팔레트로 돌아가기" style="width: 48px; height: 48px; display: flex; align-items: center; justify-content: center">${icon('left', 24)}</a>
<span style="font-family: ${MONO}; font-size: 12px; letter-spacing: 0.06em">ESEL · 스케치북</span>
</header>
<div style="flex-shrink: 0; padding: 4px 20px 0">
<div style="display: flex; align-items: center; gap: 14px">
${avatar('dana', 60)}
<h1 style="margin: 0; font-family: ${SERIF}; font-style: italic; font-weight: 400; font-size: 76px; line-height: 0.85; letter-spacing: -0.03em; padding-bottom: 8px">dana</h1>
<button type="button" style="margin-left: auto; height: 44px; padding: 0 22px; border-radius: 22px; background: ${INK}; color: ${PAPER}; font-size: 15px; font-weight: 600">구독</button>
</div>
<p style="margin: 10px 0 0; font-size: 15px; line-height: 1.45">하늘색 셔츠를 제일 자주 입어요.</p>
<div style="height: 36px; display: flex; align-items: center; gap: 4px; font-size: 14px">${paint('powder', 44, '', '')}<span>오늘은 파우더 블루</span><span style="color: ${MUTED}">· 캔버스 ${ISSUES}장</span></div>
</div>
<span aria-hidden="true" style="flex-shrink: 0; height: 1px; margin: 10px 0 0; background: ${HAIR}"></span>
<main style="flex: 1 1 0; min-height: 0; overflow: hidden">
${sketchPost({ i: 0, cap: PEOPLE.dana.cap, wear: WEAR.dana })}
${sketchPost({ i: 1, style: 'paint', py: 0.55, cap: '같은 셔츠, 오늘은 물감 한 획.' })}
</main>
${capsule({ color: PEOPLE[ME].color, active: 'palette' })}
</div>`);

// C6 오늘의 캔버스 만들기 · 자르기 하나(그대로 · 사인 뒤로 · 목 아래) + 물감 한 획 켜기·끄기, 사인 색, 착용 정보
const MK = { W: 200, H: 296, top: 108 };
const me = PEOPLE[ME];
const zoom = [MK.W, MK.H, 1.9, me.fx, me.fy, MK.W / 2, MK.H * 0.21];
const mkFace = `<span style="position: absolute; left: 0; top: 0; display: {{vPlain}}">${cover(ME, MK.W, MK.H, 0.5, 0.5)}</span>
<span style="position: absolute; left: 0; top: 0; display: {{vZoom}}">${crop(ME, ...zoom)}</span>
<span style="position: absolute; left: 0; top: 0; display: {{vNeck}}">${neckDown(ME, MK.W, MK.H)}</span>
<span aria-hidden="true" style="position: absolute; left: 0; top: 0; width: ${MK.W}px; height: ${MK.H}px; display: {{vPlainPaint}}">${faceStroke(ME, MK.W, MK.H, 0.5, 0.5)}</span>
<span aria-hidden="true" style="position: absolute; left: 0; top: 0; width: ${MK.W}px; height: ${MK.H}px; display: {{vZoomPaint}}">${cropStroke(ME, ...zoom)}</span>
<span aria-hidden="true" style="position: absolute; left: 0; right: 0; top: 0; height: 45%; background: linear-gradient(rgba(0, 0, 0, 0.4), rgba(0, 0, 0, 0))"></span>`;
const seg = (label, hole, extra = '') => `<button type="button" aria-pressed="{{${hole}Pressed}}" onClick="{{pick${hole}}}"${extra} style="height: 44px; flex: 1 1 0; display: flex; align-items: center"><span style="width: 100%; height: 36px; border-radius: 18px; display: flex; align-items: center; justify-content: center; font-size: 14px; font-weight: 600; background: {{${hole}Bg}}; color: {{${hole}Fg}}; box-shadow: inset 0 0 0 1.5px ${INK}">${label}</span></button>`;
// Garments added so far: the one in today's color carries its paint and color name; brand is optional.
const MK_GARMENTS = [{ label: '카멜 코트', color: me.color }, { label: '페도라' }, { label: '니트' }];
const garmentChip = (g) => `<button type="button" aria-label="${g.label}${g.color ? ' · 오늘의 색' : ''} 고치기" style="height: 44px; flex-shrink: 0; display: flex; align-items: center"><span style="height: 38px; padding: 0 ${g.color ? '14px 0 6px' : '14px'}; border-radius: 19px; display: flex; align-items: center; gap: 2px; background: #FFFFFF; box-shadow: inset 0 0 0 1px ${HAIR}; font-size: 14px; font-weight: 500; white-space: nowrap">${g.color ? paint(g.color, 36, '', '') : ''}<span>${g.label}</span></span></button>`;
const addChip = `<button type="button" aria-label="착용 정보 더하기" style="width: 44px; height: 44px; flex-shrink: 0; display: flex; align-items: center; justify-content: center"><span style="width: 38px; height: 38px; border-radius: 50%; display: flex; align-items: center; justify-content: center; box-shadow: inset 0 0 0 1.5px ${INK}">${icon('plus', 18, 2)}</span></button>`;
files.CoverMake = page('표지 SNS 6 오늘의 캔버스 만들기', `<div style="${ROOT(`padding-top: 54px; background: ${PAPER}; color: ${INK}`)}">
<header style="height: 48px; display: flex; align-items: center; justify-content: space-between; padding: 0 18px 0 6px">
<a href="CoverFeed.dc.html" aria-label="닫기" style="width: 48px; height: 48px; display: flex; align-items: center; justify-content: center">${icon('x', 24)}</a>
<h1 style="margin: 0; font-size: 16px; font-weight: 600">오늘의 캔버스 만들기</h1>
<span style="font-family: ${SERIF}; font-style: italic; font-size: 18px">Nº 012</span>
</header>
<div style="position: absolute; left: ${(393 - MK.W) / 2}px; top: ${MK.top}px; width: ${MK.W}px; height: ${MK.H}px; overflow: hidden; background: #EDEEEA; color: {{mastColor}}; box-shadow: 0 14px 36px rgba(41, 42, 39, 0.2)">
${mkFace}
<span aria-hidden="true" style="position: absolute; left: 10px; right: 10px; top: 8px; display: flex; justify-content: space-between; font-family: ${MONO}; font-size: 8px; letter-spacing: 0.06em"><span>ESEL</span><span>Nº 012 · 9. 6.</span></span>
<span aria-hidden="true" style="position: absolute; left: 0; right: 0; top: 18px; text-align: center; font-family: ${SERIF}; font-size: ${mastSize(ME, MK.W, 128)}px; line-height: 0.9; letter-spacing: -0.05em; padding-right: 5px">${ME}</span>
<span aria-hidden="true" style="position: absolute; left: 0; right: 0; bottom: 0; height: 40%; background: linear-gradient(rgba(0, 0, 0, 0), rgba(0, 0, 0, 0.5))"></span>
<span style="position: absolute; left: 12px; bottom: 12px; color: #FFFFFF; font-size: 11px; font-weight: 500">${me.cap}</span>
</div>
<div style="position: absolute; left: 20px; right: 20px; top: ${MK.top + MK.H + 10}px; display: flex; flex-direction: column">
<span style="font-size: 12px; line-height: 16px; color: ${MUTED}">얼굴 · 자르기</span>
<div role="group" aria-label="자르기" style="display: flex; gap: 6px">
${seg('그대로', 'Plain')}
${seg('사인 뒤로', 'Zoom')}
${seg('목 아래', 'Neck')}
</div>
<div style="height: 44px; display: flex; align-items: center; gap: 2px; opacity: {{paintRowOpacity}}">
<span style="font-size: 14px; margin-right: 2px">물감 한 획</span>${paint(me.color, 40, '', '')}<span style="font-size: 13px; color: ${MUTED}">${PAINT[me.color].name}</span>
<div role="group" aria-label="물감 한 획" style="margin-left: auto; display: flex; gap: 6px; width: 140px">
${seg('끔', 'Off', ' aria-disabled="{{paintDisabled}}"')}
${seg('켬', 'On', ' aria-disabled="{{paintDisabled}}"')}
</div>
</div>
<p style="margin: 0; font-size: 12px; line-height: 18px; color: ${MUTED}; display: {{neckNote}}">목 아래는 얼굴이 없어 물감을 쓰지 않아요.</p>
<div style="height: 44px; display: flex; align-items: center; gap: 6px">
<span style="font-size: 14px">사인 색</span>
<div role="group" aria-label="사인 색" style="margin-left: auto; display: flex; gap: 6px; width: 140px">
${seg('먹', 'Ink')}
${seg('흰', 'White')}
</div>
</div>
<span style="margin-top: 8px; font-size: 12px; line-height: 16px; color: ${MUTED}">착용 정보 · 브랜드는 쓰지 않아도 돼요</span>
<div style="display: flex; align-items: center; gap: 6px">
${MK_GARMENTS.map(garmentChip).join('\n')}
${addChip}
</div>
<label for="cover-line" style="margin-top: 8px; font-size: 12px; line-height: 16px; color: ${MUTED}">표지 문구</label>
<input id="cover-line" type="text" value="${me.cap}" style="height: 42px; box-sizing: border-box; padding: 0; border: 0; border-bottom: 1.5px solid ${INK}; border-radius: 0; background: transparent; font-size: 17px">
</div>
<a href="CoverFeed.dc.html" style="position: absolute; left: 20px; right: 20px; bottom: 40px; height: 56px; border-radius: 28px; display: flex; align-items: center; justify-content: center; background: ${INK}; color: ${PAPER}; font-size: 16px; font-weight: 600">올리기</a>
</div>`, { logic: faceLogic({ crop: 'plain', paint: false }) });

// Face presentation shared with J6: one crop (plain · behind the sign · neck down) plus the paint stroke on or off.
// Neck down has no face, so the stroke is switched off there.
export function faceLogic(defaults) {
  return `const st = this.state || {};
const cropK = st.crop || '${defaults.crop}';
const neck = cropK === 'neck';
const painted = !neck && (st.paint != null ? !!st.paint : ${defaults.paint});
const white = !(st.white === false);
const show = (b) => (b ? 'block' : 'none');
vals.vPlain = show(cropK === 'plain');
vals.vZoom = show(cropK === 'zoom');
vals.vNeck = show(neck);
vals.vPlainPaint = show(cropK === 'plain' && painted);
vals.vZoomPaint = show(cropK === 'zoom' && painted);
const segVals = (name, active, pick) => {
vals[name + 'Pressed'] = active ? 'true' : 'false';
vals[name + 'Bg'] = active ? '${INK}' : 'transparent';
vals[name + 'Fg'] = active ? '${PAPER}' : '${INK}';
vals['pick' + name] = pick;
};
segVals('Plain', cropK === 'plain', () => this.setState({ crop: 'plain' }));
segVals('Zoom', cropK === 'zoom', () => this.setState({ crop: 'zoom' }));
segVals('Neck', neck, () => this.setState({ crop: 'neck' }));
segVals('Off', !painted, () => { if (!neck) this.setState({ paint: false }); });
segVals('On', painted, () => { if (!neck) this.setState({ paint: true }); });
segVals('Ink', !white, () => this.setState({ white: false }));
segVals('White', white, () => this.setState({ white: true }));
vals.paintDisabled = neck ? 'true' : 'false';
vals.paintRowOpacity = neck ? '0.38' : '1';
vals.neckNote = neck ? 'block' : 'none';
vals.mastColor = white ? '#FFFFFF' : '${INK}';`;
}

// C7 스크롤 시안 · 첫 장만 표지
const inner = ({ key, no, style = 'plain', px = 0.5, py = 0.3 }) => {
  const p = PEOPLE[key];
  let img;
  if (style === 'neck') img = neckDown(key, 393, 500);
  else img = `<span style="position: relative; display: block; width: 393px; height: 500px; overflow: hidden; background: #EDEEEA">${cover(key, 393, 500, px, py)}${style === 'paint' ? faceStroke(key, 393, 500, px, py) : ''}</span>`;
  return `<article style="padding-bottom: 22px">
<div style="display: flex; align-items: baseline; justify-content: space-between; padding: 16px 18px 8px; font-family: ${SERIF}; font-style: italic; font-size: 16px"><span>${no}</span><span>${p.time}</span></div>
<div style="position: relative">${img}${WEAR[key] ? `<span style="position: absolute; right: 10px; bottom: 4px">${wearLink(WEAR[key])}</span>` : ''}</div>
<div style="display: flex; align-items: center; gap: 8px; padding: 4px 6px 0 18px">
<span style="font-size: 18px; font-weight: 600">${key}</span>
${paint(p.color, 54, '', '')}
<span style="font-size: 13px; color: ${MUTED}">${PAINT[p.color].name}</span>
<span style="margin-left: auto; display: flex">${stat('heartPlain', '좋아요', '')}${stat('bookmark', '저장', '')}</span>
</div>
<p style="margin: 0; padding: 0 18px; font-size: 15px; line-height: 1.45">${p.cap}</p>
</article>`;
};
const innerPages = [
  inner({ key: 'ama', no: '02', py: 0.3 }),
  inner({ key: 'lise', no: '03', style: 'paint', py: 0.25 }),
  inner({ key: 'kofi', no: '04', px: 0.65, py: 0.15 }),
  inner({ key: 'rio', no: '05', py: 0.4 }),
  inner({ key: 'omar', no: '06', style: 'neck' }),
  inner({ key: 'riva', no: '07', py: 0.25 }),
].join('\n');
const scrollCover = ({ home = true } = {}) => `<section aria-label="오늘의 표지" style="position: relative; height: 800px; overflow: hidden; background: #C9D3DC">
${cover('dana', 393, 800, 0.58, 0.5, '; position: absolute; left: 0; top: 0')}
${shade(460)}
${topBar(INK, { home })}
<h1 style="position: absolute; width: 1px; height: 1px; overflow: hidden; clip-path: inset(50%); margin: 0">Esel 오늘의 표지</h1>
${coverText('dana', { same: 187, bottom: 52 })}
</section>`;
const sc = scrollLogic();
files.CoverScroll = page('표지 SNS 7 스크롤 시안', `<div style="${ROOT(`background: ${PAPER}; color: ${INK}`)}">
<div class="esel-scroll" ref="{{setScroller}}" onScroll="{{onScroll}}" style="position: absolute; left: 0; top: 0; width: 100%; height: 100%; overflow-y: auto; overscroll-behavior: contain; scrollbar-width: none">
${scrollCover()}
${innerPages}
<div aria-hidden="true" style="height: 110px"></div>
</div>
${mastLayer}
${capsule({ color: PEOPLE[ME].color, active: 'home' })}
</div>`, sc);

// Palette and my page follow the layouts chosen on 10-18 (palette R5-4, my page X4-1).
Object.assign(files, { CoverStand: adopted.CoverStand, CoverStandLocked: adopted.CoverStandLocked, CoverMe: adopted.CoverMe });
for (const [name, html] of Object.entries(files)) fs.writeFileSync(path.join(OUT, `${name}.dc.html`), html);
export { scrollCover, innerPages, inner, coverText, topBar, shade, miniCover, GRID, gridBlock, tile, tileImg, colorRow, colorList, myCandidates, GARMENTS, garmentRow, WEAR };
console.log('ok', Object.entries(files).map(([n, h]) => `${n}:${h.length}`).join(' '));
