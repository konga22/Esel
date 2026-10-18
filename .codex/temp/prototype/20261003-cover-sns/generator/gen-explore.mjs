// Explorations (10-18): palette layouts and "my sketchbook" layouts, to pick a direction before C4 / M1 change.
// The palette keeps the explore-tab grid (3 columns, a tall cell every two rows); cells carry only the photo with the
// face choice the person made. Round 1 and Q2·Q5 were dropped; Q1·Q3·Q4 stayed and round 3 builds on them.
// Rules still hold: no counts on others' work (P18), my three candidate colors stay out of the grid before I post (P01),
// my own counts appear only on my sketchbook and say so. Each person has one example photo, so my past canvases
// borrow other photos cropped below the chin (a face choice people can make anyway, P15).
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { SERIF, SANS, MONO, INK, PAPER, MUTED, HAIR, PAINT, PEOPLE, ME, TODAY_CANDIDATES, COLOR_ORDER, ROOT, cover, fit, faceStroke, neckDown, crop, avatar, paint, icon, mastSize, capsule, page } from './lib.mjs';

const OUT = path.join(path.dirname(fileURLToPath(import.meta.url)), 'project');
const files = {};

// Icons this page needs that the shared set does not have (same 24 grid, 1.7 stroke).
const svg = (d, size = 24, sw = 1.7) => `<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="${sw}" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${d}</svg>`;
const gear = (s = 24) => svg('<path d="M4.5 7h15"></path><path d="M4.5 12h15"></path><path d="M4.5 17h15"></path>', s);
const right = (s = 18) => svg('<path d="M10 6l6 6-6 6"></path>', s, 1.8);
const share = (s = 22) => svg('<path d="M12 4v11"></path><path d="M8 8l4-4 4 4"></path><path d="M5 13v6h14v-6"></path>', s);

// ───────── Palette grid (unchanged shape): 130 / 129 / 130, gap 2, cell 3:4, a tall cell every two rows.
const G = { cols: [130, 129, 130], gap: 2, cell: 173 };
G.x = [0, G.cols[0] + G.gap, G.cols[0] + G.cols[1] + G.gap * 2];
G.tall = G.cell * 2 + G.gap;
G.block = G.tall + G.gap;
const faceX = (key, w, h) => { const f = fit(key, w, h, 0, 0); return f.dw > w ? Math.max(0, Math.min(1, (f.fx - w / 2) / (f.dw - w))) : 0.5; };
// The owner's photo with the face choice they made.
function shot({ key, style = 'plain', py = 0.3 }, w, h) {
  const p = PEOPLE[key];
  if (style === 'neck') return neckDown(key, w, h);
  if (style === 'behind') return crop(key, w, h, 1.7, p.fx, p.fy, w / 2, h * 0.16);
  const px = faceX(key, w, h);
  return `<span style="position: relative; display: block; width: ${w}px; height: ${h}px; overflow: hidden">${cover(key, w, h, px, py)}${style === 'paint' ? faceStroke(key, w, h, px, py) : ''}</span>`;
}
// The sign laid on a cell, smaller for "as is" so it clears the face (same rule as C4).
function signOn(it, w, h, color = '#FFFFFF') {
  const full = mastSize(it.key, w, Math.round(w * 0.44));
  const top = Math.round(h * 0.025);
  let size = full;
  if ((it.style ?? 'plain') === 'plain') {
    const f = fit(it.key, w, h, faceX(it.key, w, h), it.py ?? 0.3);
    size = Math.max(Math.round(full * 0.62), Math.min(full, Math.floor((f.fy - f.fwPx * 0.6 - top) / 0.9)));
  }
  return `<span aria-hidden="true" style="position: absolute; left: 0; right: 0; top: 0; height: 38%; background: linear-gradient(rgba(0, 0, 0, 0.26), rgba(0, 0, 0, 0))"></span><span aria-hidden="true" style="position: absolute; left: 0; right: 0; top: ${top}px; text-align: center; font-family: ${SERIF}; font-size: ${size}px; line-height: 0.9; letter-spacing: -0.05em; padding-right: ${Math.round(size * 0.05)}px; color: ${color}; white-space: nowrap">${it.key}</span>`;
}
const cell = (inner, it, x, y, w, h, bg = '#EDEEEA') => `<a href="CoverShelf.dc.html" aria-label="${it.key}의 스케치북" style="position: absolute; left: ${x}px; top: ${y}px; width: ${w}px; height: ${h}px; overflow: hidden; background: ${bg}">${inner}</a>`;
// 추천 before I post: none of my candidate colors (camel, lilac, olive) appear (P01).
const PICKS = [
  [{ key: 'dana' }, { key: 'ama' }, { key: 'riva', py: 0.5 }, { key: 'lise', style: 'paint' }, { key: 'omar', style: 'neck' }],
  [{ key: 'vera', py: 0.5 }, { key: 'zuri' }, { key: 'elin', py: 0.2 }, { key: 'freya', style: 'behind' }, { key: 'hana', py: 0.35 }],
  [{ key: 'sol', py: 0.35 }, { key: 'nia', py: 0.4 }, { key: 'june', style: 'neck' }, { key: 'cleo', py: 0.25 }, { key: 'maya', py: 0.35 }],
];
const scroller = (inner, extra = '') => `<div class="esel-scroll" style="flex: 1 1 0; min-height: 0; overflow-y: auto; overscroll-behavior: contain; scrollbar-width: none${extra}">${inner}<div style="height: 110px"></div></div>`;
const shell = (bg, fg, inner, cap) => `<div style="${ROOT(`padding-top: 54px; display: flex; flex-direction: column; background: ${bg}; color: ${fg}`)}">
${inner}
${cap}
</div>`;
const myColor = PEOPLE[ME].color;
const candidates = [myColor, ...TODAY_CANDIDATES.filter((c) => c !== myColor)];
const others = COLOR_ORDER.filter((c) => !candidates.includes(c));

// ───────── My sketchbook (owner view). Same facts in each: avatar, sign, one line, today's color and canvas count,
// my own reactions (only I see them), color calendar, friends, twin, weekly theme, exhibition, settings, my canvases.
const DAYS = ['9. 6.', '9. 5.', '9. 4.', '9. 3.', '9. 1.', '8. 31.', '8. 30.', '8. 29.', '8. 28.'];
const MINE = [
  { key: ME, style: 'plain', py: 0.4, color: 'camel', cap: '카멜 코트와 페도라.' },
  { key: 'elin', style: 'neck', color: 'sage', cap: '라탄 의자, 세이지 셋업.' },
  { key: 'ama', style: 'neck', color: 'butter', cap: '노란 셋업에 은색 가방 하나.' },
  { key: ME, style: 'paint', py: 0.45, color: 'camel', cap: '같은 코트, 오늘은 물감 한 획.' },
  { key: 'riva', style: 'neck', color: 'cobalt', cap: '바닷가엔 코발트.' },
  { key: 'lise', style: 'neck', color: 'burgundy', cap: '창가의 버건디 코트.' },
  { key: 'zuri', style: 'neck', color: 'coral', cap: '코랄 원피스, 문턱에 서서.' },
  { key: 'freya', style: 'neck', color: 'cream', cap: '크림 수트, 파란 타일.' },
  { key: ME, style: 'behind', color: 'camel', cap: '사인 뒤로 숨은 날.' },
].map((m, i) => ({ ...m, n: String(12 - i).padStart(3, '0'), date: DAYS[i] }));
const mineShot = (m, w, h) => {
  if (m.style === 'neck') return neckDown(m.key, w, h);
  if (m.style === 'behind') { const p = PEOPLE[m.key]; return `<span style="position: relative; display: block; width: ${w}px; height: ${h}px; overflow: hidden">${crop(m.key, w, h, 1.7, p.fx, p.fy, w / 2, h * 0.17)}<span aria-hidden="true" style="position: absolute; left: 0; right: 0; top: ${Math.round(h * 0.03)}px; text-align: center; font-family: ${SERIF}; font-size: ${mastSize(ME, w, Math.round(w * 0.44))}px; line-height: 0.9; letter-spacing: -0.05em; color: #FFFFFF">${ME}</span></span>`; }
  return `<span style="position: relative; display: block; width: ${w}px; height: ${h}px; overflow: hidden">${cover(m.key, w, h, 0.5, m.py)}${m.style === 'paint' ? faceStroke(m.key, w, h, 0.5, m.py) : ''}</span>`;
};
const BIO = '옷으로 남기는 나의 계절.';
const MENU = ['색 달력', '친구', '트윈', '이번 주 주제', '전시'];
const OWN = { likes: 128, lines: 12, saves: 9 };
const meCap = capsule({ color: myColor, active: 'me', solid: true });

const mineCell = (m, w, h, label = true, tag = 'a') => `<${tag}${tag === 'a' ? ` href="#" aria-label="Nº ${m.n} · ${m.date} · ${PAINT[m.color].name}"` : ''} style="position: relative; display: block; width: ${w}px; height: ${h}px; overflow: hidden; background: #EDEEEA">${mineShot(m, w, h)}${label ? `<span style="position: absolute; left: 7px; bottom: 6px; font-family: ${MONO}; font-size: 10px; letter-spacing: 0.04em; color: #FFFFFF; text-shadow: 0 1px 3px rgba(0, 0, 0, 0.5)">Nº ${m.n}</span>` : ''}</${tag}>`;

// ───────── Palette, round 2 (10-18 feedback: the top area, the marks on cells and the plainness were the problem).
// Cells are now only the photo with the face choice the person made; the sign stays only for "behind the sign",
// because there it is what hides the face (P15). The identity moves to the top area: glass, paint and color.
const clean = (it, x, y, w, h) => cell(shot(it, w, h) + (it.style === 'behind' ? signOn(it, w, h) : ''), it, x, y, w, h);
function blockG(g, items, top, tallLeft, draw) {
  const [a, b, c, d, e] = items;
  const r2 = top + g.cell + g.gap;
  if (tallLeft) return [draw(a, g.x[0], top, g.cols[0], g.tall), draw(b, g.x[1], top, g.cols[1], g.cell), draw(c, g.x[2], top, g.cols[2], g.cell), draw(d, g.x[1], r2, g.cols[1], g.cell), draw(e, g.x[2], r2, g.cols[2], g.cell)].join('\n');
  return [draw(a, g.x[0], top, g.cols[0], g.cell), draw(b, g.x[1], top, g.cols[1], g.cell), draw(c, g.x[2], top, g.cols[2], g.tall), draw(d, g.x[0], r2, g.cols[0], g.cell), draw(e, g.x[1], r2, g.cols[1], g.cell)].join('\n');
}
const gridG = (g, top = 0, rows = PICKS) => `<section aria-label="추천" style="position: relative; height: ${g.block * rows.length}px; margin-top: ${top}px">
${rows.map((items, i) => blockG(g, items, i * g.block, i % 2 === 1, clean)).join('\n')}
</section>`;

// Q1 글라스 바: the grid runs from the very top of the screen and a glass bar floats over it, the same glass as the
// capsule below. The 색상 segment carries my paint. Nothing else sits on the photos.
const glassSeg = (inner, on) => `<a href="#"${on ? ' aria-current="page"' : ''} style="flex: 1 1 0; height: 44px; border-radius: 22px; display: flex; align-items: center; justify-content: center; gap: 4px; font-size: 15px; font-weight: 600; background: ${on ? 'rgba(255, 255, 255, 0.9)' : 'transparent'}; box-shadow: ${on ? '0 1px 6px rgba(0, 0, 0, 0.12)' : 'none'}">${inner}</a>`;
files.ExplorePalette2Glass = page('시안 Q1 팔레트 · 글라스 바', `<div style="${ROOT(`background: ${PAPER}; color: ${INK}`)}">
<div class="esel-scroll" style="position: absolute; inset: 0; overflow-y: auto; scrollbar-width: none">${gridG(G, 0, [...PICKS, PICKS[0]])}<div style="height: 110px"></div></div>
<span aria-hidden="true" style="position: absolute; left: 0; right: 0; top: 0; height: 130px; background: linear-gradient(rgba(0, 0, 0, 0.38), rgba(0, 0, 0, 0)); pointer-events: none"></span>
<nav aria-label="팔레트 보기" class="esel-glass" style="position: absolute; left: 14px; right: 14px; top: 50px; height: 52px; box-sizing: border-box; padding: 4px; border-radius: 26px; display: flex; gap: 2px">
${glassSeg('추천', true)}
${glassSeg(`${paint(myColor, 34, '', '')}<span>색상</span>${icon('down', 14, 2)}`, false)}
${glassSeg('구독', false)}
</nav>
${capsule({ color: myColor, active: 'palette' })}
</div>`);

// Q3 물감 상자: the top is almost nothing (a title and three words); choosing a color opens a paint box from below,
// twelve real paints laid in a tray, today's three candidates first with a lock (P01). Shown open.
const trayPaint = (c, locked, current) => `<button type="button" aria-label="${PAINT[c].name}${locked ? ' · 올리기 전이라 세 장만 먼저' : ''}" style="position: relative; height: 86px; border-radius: 16px; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 4px; background: ${current ? '#F1F1EE' : 'transparent'}; box-shadow: ${current ? `inset 0 0 0 1.5px ${INK}` : 'none'}">${paint(c, 78, '', '')}<span style="font-size: 12.5px; font-weight: 600">${PAINT[c].name}</span>${locked ? `<span aria-hidden="true" style="position: absolute; right: 8px; top: 8px; display: flex; color: ${MUTED}">${icon('lock', 13, 2)}</span>` : ''}</button>`;
files.ExplorePalette2Box = page('시안 Q3 팔레트 · 물감 상자', `<div style="${ROOT(`padding-top: 54px; display: flex; flex-direction: column; background: ${PAPER}; color: ${INK}`)}">
<header style="flex-shrink: 0; height: 48px; display: flex; align-items: center; gap: 18px; padding: 0 20px">
<h1 style="margin: 0; font-size: 20px; font-weight: 600">팔레트</h1>
<nav aria-label="팔레트 보기" style="display: flex; gap: 14px; font-size: 15px; font-weight: 600; color: ${MUTED}"><a href="#">추천</a><a href="#" aria-current="page" style="color: ${INK}">색상</a><a href="#">구독</a></nav>
</header>
${scroller(gridG(G, 0))}
<span aria-hidden="true" style="position: absolute; inset: 0; background: rgba(20, 20, 18, 0.38)"></span>
<section role="dialog" aria-label="물감 상자" style="position: absolute; left: 0; right: 0; bottom: 0; padding: 10px 16px 34px; border-radius: 28px 28px 0 0; background: #FFFFFF; box-shadow: 0 -10px 30px rgba(0, 0, 0, 0.12)">
<span aria-hidden="true" style="display: block; width: 36px; height: 5px; margin: 0 auto 12px; border-radius: 3px; background: #D6D6D2"></span>
<div style="display: flex; align-items: baseline; justify-content: space-between; padding: 0 6px"><h2 style="margin: 0; font-family: ${SERIF}; font-size: 26px; font-weight: 400">물감 상자</h2><span style="font-size: 12.5px; color: ${MUTED}">숫자 없이, 오늘 많이 고른 순</span></div>
<p style="margin: 14px 6px 4px; font-family: ${MONO}; font-size: 10.5px; letter-spacing: 0.08em; color: ${MUTED}">오늘 내 후보 · 올리면 함께 펼쳐져요</p>
<div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 4px">${candidates.map((c, i) => trayPaint(c, true, i === 0)).join('')}</div>
<p style="margin: 12px 6px 4px; font-family: ${MONO}; font-size: 10.5px; letter-spacing: 0.08em; color: ${MUTED}">다른 색</p>
<div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 4px">${others.map((c) => trayPaint(c, false, false)).join('')}</div>
</section>
</div>`);

// Q4 색 레일: a slim rail of upright paints down the right edge, like tubes standing on a shelf. Touch one to see that
// color's room. The grid keeps its shape in the remaining width.
const G4 = { cols: [114, 113, 114], gap: 2, cell: 152 };
G4.x = [0, G4.cols[0] + G4.gap, G4.cols[0] + G4.cols[1] + G4.gap * 2];
G4.tall = G4.cell * 2 + G4.gap;
G4.block = G4.tall + G4.gap;
const railPaint = (c, locked) => `<button type="button" aria-label="${PAINT[c].name}${locked ? ' · 올리기 전이라 세 장만 먼저' : ''}" style="position: relative; width: 48px; height: 50px; display: flex; align-items: center; justify-content: center">${paint(c, 46, '; transform: rotate(-90deg)', '')}${locked ? `<span aria-hidden="true" style="position: absolute; right: 4px; bottom: 4px; width: 14px; height: 14px; border-radius: 50%; display: flex; align-items: center; justify-content: center; background: ${INK}; color: ${PAPER}">${icon('lock', 9, 2.2)}</span>` : ''}</button>`;
files.ExplorePalette2Rail = page('시안 Q4 팔레트 · 색 레일', shell(PAPER, INK, `<header style="flex-shrink: 0; height: 56px; display: flex; align-items: center; gap: 18px; padding: 0 20px">
<h1 style="margin: 0; font-family: ${SERIF}; font-size: 30px; font-weight: 400; line-height: 1">팔레트</h1>
<nav aria-label="팔레트 보기" style="display: flex; gap: 14px; font-size: 15px; font-weight: 600; color: ${MUTED}"><a href="#" aria-current="page" style="color: ${INK}">추천</a><a href="#">구독</a></nav>
</header>
<div style="flex: 1 1 0; min-height: 0; display: flex">
<div class="esel-scroll" style="width: 341px; flex-shrink: 0; overflow-y: auto; scrollbar-width: none">${gridG(G4, 0)}<div style="height: 110px"></div></div>
<nav aria-label="색으로 보기" style="flex: 1 1 0; display: flex; flex-direction: column; align-items: center; padding-top: 2px; box-shadow: inset 1px 0 0 ${HAIR}">
${candidates.map((c) => railPaint(c, true)).join('\n')}
<span aria-hidden="true" style="width: 20px; height: 1px; margin: 4px 0; background: ${HAIR}"></span>
${others.slice(0, 8).map((c) => railPaint(c, false)).join('\n')}
</nav>
</div>`, capsule({ color: myColor, active: 'palette', solid: true })));

// ───────── Palette, round 3 (Q1 · Q3 · Q4 were "okay"): what they share is a full screen of photos, an almost empty
// top, and paints as real objects within reach. Each of these pushes one of those further.
const fullGrid = (rows = [...PICKS, PICKS[0]]) => `<div class="esel-scroll" style="position: absolute; inset: 0; overflow-y: auto; scrollbar-width: none">${gridG(G, 0, rows)}<div style="height: 110px"></div></div>
<span aria-hidden="true" style="position: absolute; left: 0; right: 0; top: 0; height: 130px; background: linear-gradient(rgba(0, 0, 0, 0.38), rgba(0, 0, 0, 0)); pointer-events: none"></span>`;
// A small glass pill for 추천 · 구독 in the top-left corner; color lives in the paints.
const glassTabs = (items, active) => `<nav aria-label="팔레트 보기" class="esel-glass" style="position: absolute; left: 14px; top: 50px; height: 48px; box-sizing: border-box; padding: 4px; border-radius: 24px; display: flex; gap: 2px">${items.map((l, i) => `<a href="#"${i === active ? ' aria-current="page"' : ''} style="height: 40px; padding: 0 16px; border-radius: 20px; display: flex; align-items: center; gap: 4px; font-size: 15px; font-weight: 600; background: ${i === active ? 'rgba(255, 255, 255, 0.92)' : 'transparent'}; box-shadow: ${i === active ? '0 1px 6px rgba(0, 0, 0, 0.12)' : 'none'}">${l}</a>`).join('')}</nav>`;
const lockDot = (size = 15, right = 2, bottom = 2) => `<span aria-hidden="true" style="position: absolute; right: ${right}px; bottom: ${bottom}px; width: ${size}px; height: ${size}px; border-radius: 50%; display: flex; align-items: center; justify-content: center; background: ${INK}; color: ${PAPER}">${icon('lock', Math.round(size * 0.62), 2.2)}</span>`;
const GLASS_SHEET = 'background: rgba(249, 249, 251, 0.84); -webkit-backdrop-filter: blur(24px) saturate(1.6); backdrop-filter: blur(24px) saturate(1.6); box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.6), 0 -10px 30px rgba(0, 0, 0, 0.14)';

// R1 글라스 + 물감 상자 (Q1 + Q3): the full-bleed grid with the glass bar, and the paint box rising as glass too,
// so the photos still show through while choosing. Shown open from the 색상 segment.
const glassTray = (c, locked, current) => `<button type="button" aria-label="${PAINT[c].name}${locked ? ' · 올리기 전이라 세 장만 먼저' : ''}" style="position: relative; height: 82px; border-radius: 18px; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 2px; background: ${current ? 'rgba(255, 255, 255, 0.95)' : 'transparent'}; box-shadow: ${current ? '0 2px 10px rgba(0, 0, 0, 0.1)' : 'none'}">${paint(c, 74, '', '')}<span style="font-size: 12.5px; font-weight: 600">${PAINT[c].name}</span>${locked ? `<span aria-hidden="true" style="position: absolute; right: 10px; top: 8px; display: flex; color: ${MUTED}">${icon('lock', 13, 2)}</span>` : ''}</button>`;
files.ExplorePalette3GlassBox = page('시안 R1 팔레트 · 글라스 + 물감 상자', `<div style="${ROOT(`background: ${PAPER}; color: ${INK}`)}">
${fullGrid()}
<nav aria-label="팔레트 보기" class="esel-glass" style="position: absolute; left: 14px; right: 14px; top: 50px; height: 52px; box-sizing: border-box; padding: 4px; border-radius: 26px; display: flex; gap: 2px">
${glassSeg('추천', false)}
${glassSeg(`${paint(myColor, 34, '', '')}<span>카멜</span>${icon('up', 14, 2)}`, true)}
${glassSeg('구독', false)}
</nav>
<span aria-hidden="true" style="position: absolute; left: 0; right: 0; top: 112px; bottom: 0; background: rgba(20, 20, 18, 0.18)"></span>
<section role="dialog" aria-label="물감 상자" style="position: absolute; left: 8px; right: 8px; bottom: 8px; padding: 10px 12px 18px; border-radius: 32px; ${GLASS_SHEET}">
<span aria-hidden="true" style="display: block; width: 36px; height: 5px; margin: 0 auto 10px; border-radius: 3px; background: rgba(41, 42, 39, 0.25)"></span>
<div style="display: flex; align-items: baseline; justify-content: space-between; padding: 0 8px"><h2 style="margin: 0; font-family: ${SERIF}; font-size: 26px; font-weight: 400">물감 상자</h2><span style="font-size: 12.5px; color: ${MUTED}">오늘 많이 고른 순</span></div>
<p style="margin: 10px 8px 2px; font-family: ${MONO}; font-size: 10.5px; letter-spacing: 0.08em; color: ${MUTED}">오늘 내 후보 · 올리면 함께 펼쳐져요</p>
<div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 2px">${candidates.map((c, i) => glassTray(c, true, i === 0)).join('')}</div>
<p style="margin: 8px 8px 2px; font-family: ${MONO}; font-size: 10.5px; letter-spacing: 0.08em; color: ${MUTED}">다른 색</p>
<div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 2px">${others.map((c) => glassTray(c, false, false)).join('')}</div>
</section>
</div>`);

// R2 글라스 물감 레일 (Q1 + Q4): photos edge to edge, a small glass pill for 추천 · 구독, and the upright paints
// floating in a glass rail on the right, over the photos instead of beside them.
const glassRailPaint = (c, locked) => `<button type="button" aria-label="${PAINT[c].name}${locked ? ' · 올리기 전이라 세 장만 먼저' : ''}" style="position: relative; width: 52px; height: 48px; flex-shrink: 0; display: flex; align-items: center; justify-content: center">${paint(c, 44, '; transform: rotate(-90deg)', '')}${locked ? lockDot(14, 6, 4) : ''}</button>`;
files.ExplorePalette3GlassRail = page('시안 R2 팔레트 · 글라스 물감 레일', `<div style="${ROOT(`background: ${PAPER}; color: ${INK}`)}">
${fullGrid()}
${glassTabs(['추천', '구독'], 0)}
<nav aria-label="색으로 보기" class="esel-glass" style="position: absolute; right: 10px; top: 112px; width: 56px; height: 628px; box-sizing: border-box; padding: 8px 2px; border-radius: 28px; display: flex; flex-direction: column; align-items: center; overflow: hidden">
${candidates.map((c) => glassRailPaint(c, true)).join('\n')}
<span aria-hidden="true" style="width: 22px; height: 1px; flex-shrink: 0; margin: 4px 0; background: rgba(41, 42, 39, 0.2)"></span>
${others.map((c) => glassRailPaint(c, false)).join('\n')}
</nav>
${capsule({ color: myColor, active: 'palette' })}
</div>`);

// R3 엄지 아래 물감 트레이: everything you touch sits where the thumb already is. The top is only photos (and the small
// 추천 · 구독 pill); a glass tray of paints floats just above the capsule and scrolls sideways.
const trayItem = (c, locked) => `<button type="button" aria-label="${PAINT[c].name}${locked ? ' · 올리기 전이라 세 장만 먼저' : ''}" style="position: relative; width: 58px; height: 54px; flex-shrink: 0; display: flex; align-items: center; justify-content: center">${paint(c, 50, '', '')}${locked ? lockDot(14, 4, 6) : ''}</button>`;
files.ExplorePalette3Tray = page('시안 R3 팔레트 · 엄지 아래 물감 트레이', `<div style="${ROOT(`background: ${PAPER}; color: ${INK}`)}">
${fullGrid()}
${glassTabs(['추천', '구독'], 0)}
<span aria-hidden="true" style="position: absolute; left: 0; right: 0; bottom: 0; height: 220px; background: linear-gradient(rgba(0, 0, 0, 0), rgba(0, 0, 0, 0.28)); pointer-events: none"></span>
<nav aria-label="색으로 보기" class="esel-glass esel-scroll" style="position: absolute; left: 12px; right: 12px; bottom: 104px; height: 62px; box-sizing: border-box; padding: 0 8px; border-radius: 31px; display: flex; align-items: center; overflow-x: auto; scrollbar-width: none">
${candidates.map((c) => trayItem(c, true)).join('\n')}
<span aria-hidden="true" style="width: 1px; height: 28px; flex-shrink: 0; margin: 0 6px; background: rgba(41, 42, 39, 0.2)"></span>
${others.map((c) => trayItem(c, false)).join('\n')}
</nav>
${capsule({ color: myColor, active: 'palette' })}
</div>`);

// R4 레일 · 카멜 방: Q4 after touching a paint. The chosen tube steps out of the rail with its name, the top says which
// room this is, and before I post the room shows its newest three and keeps the rest blurred until I post (P01).
const LOCK_OPEN = [{ key: 'leo', style: 'neck' }, { key: 'noor', style: 'behind' }, { key: 'mara', py: 0.3 }];
const camelBlur = (n) => (_, x, y, w, h) => `<span style="position: absolute; left: ${x}px; top: ${y}px; width: ${w}px; height: ${h}px; background: ${PAINT[myColor].hex}; opacity: ${0.3 + ((n * 7 + x + y) % 4) * 0.07}"></span>`;
const railPaintSel = (c, locked, sel) => `<button type="button" aria-label="${PAINT[c].name}${locked ? ' · 올리기 전이라 세 장만 먼저' : ''}"${sel ? ' aria-current="true"' : ''} style="position: relative; width: 48px; height: 50px; display: flex; align-items: center; justify-content: center">${sel ? `<span aria-hidden="true" style="position: absolute; inset: 2px 4px; border-radius: 14px; background: #FFFFFF; box-shadow: inset 0 0 0 1.5px ${INK}"></span>` : ''}<span style="position: relative; display: flex">${paint(c, 46, '; transform: rotate(-90deg)', '')}</span>${locked ? `<span aria-hidden="true" style="position: absolute; right: 4px; bottom: 4px; width: 14px; height: 14px; border-radius: 50%; display: flex; align-items: center; justify-content: center; background: ${INK}; color: ${PAPER}">${icon('lock', 9, 2.2)}</span>` : ''}</button>`;
files.ExplorePalette3RailRoom = page('시안 R4 팔레트 · 레일 · 카멜 방', shell(PAPER, INK, `<header style="flex-shrink: 0; height: 56px; display: flex; align-items: center; gap: 10px; padding: 0 20px">
${paint(myColor, 52, '', '')}<h1 style="margin: 0; font-family: ${SERIF}; font-size: 30px; font-weight: 400; line-height: 1">카멜</h1>
<span style="font-size: 13px; color: ${MUTED}">같은 색 64명 · 먼저 3장</span>
<a href="#" aria-label="추천으로" style="margin-left: auto; width: 44px; height: 44px; display: flex; align-items: center; justify-content: center">${icon('x', 22)}</a>
</header>
<div style="flex: 1 1 0; min-height: 0; display: flex">
<div style="position: relative; width: 341px; flex-shrink: 0; overflow: hidden">
${LOCK_OPEN.map((it, i) => clean(it, G4.x[i], 0, G4.cols[i], G4.cell)).join('\n')}
<div aria-hidden="true" style="position: absolute; left: 0; right: 0; top: ${G4.cell + G4.gap}px; filter: blur(1.5px)">
${blockG(G4, [0, 1, 2, 3, 4], 0, true, camelBlur(0))}
${blockG(G4, [5, 6, 7, 8, 9], G4.block, false, camelBlur(1))}
</div>
<div style="position: absolute; left: 50%; top: ${G4.cell + 70}px; transform: translateX(-50%); width: 280px; padding: 18px 16px 16px; box-sizing: border-box; border-radius: 22px; display: flex; flex-direction: column; align-items: center; gap: 4px; text-align: center; background: rgba(249, 249, 251, 0.95); box-shadow: inset 0 0 0 1px ${HAIR}, 0 10px 28px rgba(0, 0, 0, 0.1)">
${icon('lock', 20, 1.8)}
<p style="margin: 2px 0 0; font-family: ${SERIF}; font-size: 22px; line-height: 1.2">올리면 함께 펼쳐집니다</p>
<p style="margin: 0; font-size: 13px; line-height: 1.45; color: ${MUTED}">카멜 61장이 더 있어요.<br>자정이 지나면 모두 펼쳐져요.</p>
<a href="#" style="margin-top: 10px; height: 48px; padding: 0 20px; border-radius: 24px; display: flex; align-items: center; gap: 6px; background: ${INK}; color: ${PAPER}; font-size: 15px; font-weight: 600">${icon('plus', 18, 2)}<span>오늘의 캔버스 만들기</span></a>
</div>
</div>
<nav aria-label="색으로 보기" style="flex: 1 1 0; display: flex; flex-direction: column; align-items: center; padding-top: 2px; box-shadow: inset 1px 0 0 ${HAIR}">
${candidates.map((c, i) => railPaintSel(c, true, i === 0)).join('\n')}
<span aria-hidden="true" style="width: 20px; height: 1px; margin: 4px 0; background: ${HAIR}"></span>
${others.slice(0, 8).map((c) => railPaintSel(c, false, false)).join('\n')}
</nav>
</div>`, capsule({ color: myColor, active: 'palette', solid: true })));

// R5 손안의 팔레트: one glass button with my paint sits above the capsule on the right. Pressing it fans the paints out
// in two arcs around the thumb, my three candidates on the inner arc, the most chosen colors on the outer one.
const FAB = { cx: 347, cy: 718, d: 60 };
const arcItem = (c, locked, r, deg) => {
  const a = (deg * Math.PI) / 180;
  const x = Math.round(FAB.cx + r * Math.cos(a));
  const y = Math.round(FAB.cy + r * Math.sin(a));
  return `<button type="button" aria-label="${PAINT[c].name}${locked ? ' · 올리기 전이라 세 장만 먼저' : ''}" class="esel-glass" style="position: absolute; left: ${x - 28}px; top: ${y - 28}px; width: 56px; height: 56px; border-radius: 50%; display: flex; align-items: center; justify-content: center">${paint(c, 46, '', '')}${locked ? lockDot(16, -2, -2) : ''}</button>`;
};
const arc = (list, r, from, to, locked = r < 150) => list.map((c, i) => arcItem(c, locked, r, from + ((to - from) * i) / Math.max(1, list.length - 1))).join('\n');
files.ExplorePalette3Fan = page('시안 R5 팔레트 · 손안의 팔레트', `<div style="${ROOT(`background: ${PAPER}; color: ${INK}`)}">
${fullGrid()}
${glassTabs(['추천', '구독'], 0)}
<span aria-hidden="true" style="position: absolute; inset: 0; background: radial-gradient(circle at ${FAB.cx}px ${FAB.cy}px, rgba(20, 20, 18, 0.45), rgba(20, 20, 18, 0.12) 300px)"></span>
${arc(candidates, 108, 192, 258)}
${arc(others.slice(0, 6), 196, 182, 268)}
<button type="button" aria-label="물감 닫기" aria-expanded="true" style="position: absolute; left: ${FAB.cx - FAB.d / 2}px; top: ${FAB.cy - FAB.d / 2}px; width: ${FAB.d}px; height: ${FAB.d}px; border-radius: 50%; display: flex; align-items: center; justify-content: center; background: ${INK}; color: ${PAPER}; box-shadow: 0 10px 28px rgba(0, 0, 0, 0.24)">${icon('x', 22, 2)}</button>
${capsule({ color: myColor, active: 'palette' })}
</div>`);

// R5 follow-up: does the 추천 · 구독 pill hide the photos at the top? Two answers, both interactive on the canvas
// (tap the round button to open and close the paints; scroll R5-1 to see the words step aside).
const fanLogic = (openByDefault) => `const open = this.state && this.state.fan !== undefined ? this.state.fan : ${openByDefault};
vals.fanDisplay = open ? 'block' : 'none';
vals.fabExpanded = open ? 'true' : 'false';
vals.fabLabel = open ? '물감 닫기' : '물감 열기';
vals.fabPaint = open ? 'none' : 'flex';
vals.fabClose = open ? 'flex' : 'none';
vals.fabSkin = open ? 'background: ${INK}; color: ${PAPER}; box-shadow: 0 10px 28px rgba(0, 0, 0, 0.24)' : 'background: rgba(249, 249, 251, 0.58); -webkit-backdrop-filter: blur(22px) saturate(1.6); backdrop-filter: blur(22px) saturate(1.6); box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.6), 0 10px 28px rgba(0, 0, 0, 0.18)';
vals.toggleFan = () => this.setState({ fan: !open });`;
const fab = `<button type="button" aria-label="{{fabLabel}}" aria-expanded="{{fabExpanded}}" onClick="{{toggleFan}}" style="position: absolute; left: ${FAB.cx - FAB.d / 2}px; top: ${FAB.cy - FAB.d / 2}px; width: ${FAB.d}px; height: ${FAB.d}px; border-radius: 50%; display: flex; align-items: center; justify-content: center; {{fabSkin}}"><span style="display: {{fabPaint}}">${paint(myColor, 46, '', '')}</span><span style="display: {{fabClose}}">${icon('x', 22, 2)}</span></button>`;
const fanLayer = (extra = '') => `<div style="display: {{fanDisplay}}">
<span aria-hidden="true" onClick="{{toggleFan}}" style="position: absolute; inset: 0; background: radial-gradient(circle at ${FAB.cx}px ${FAB.cy}px, rgba(20, 20, 18, 0.45), rgba(20, 20, 18, 0.12) 300px)"></span>
${arc(candidates, 108, 192, 258)}
${arc(others.slice(0, 6), 196, 182, 268)}
${extra}
</div>`;

// R5-1 글자 토글 · 내리면 숨김: no glass pill at the top, only two words over the photo's own shade, and they step
// out of the way as soon as you scroll down, coming back when you scroll up (the same habit as the home masthead).
const wordTab = (label, on) => `<a href="#"${on ? ' aria-current="page"' : ''} style="height: 44px; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 3px; font-size: 17px; font-weight: ${on ? 700 : 600}; color: #FFFFFF; opacity: ${on ? 1 : 0.62}; text-shadow: 0 1px 6px rgba(0, 0, 0, 0.35)"><span>${label}</span><span style="width: 4px; height: 4px; border-radius: 50%; background: ${on ? '#FFFFFF' : 'transparent'}"></span></a>`;
files.ExplorePalette3FanWords = page('시안 R5-1 팔레트 · 글자 토글 · 내리면 숨김', `<div style="${ROOT(`background: ${PAPER}; color: ${INK}`)}">
<div class="esel-scroll" onScroll="{{onScroll}}" style="position: absolute; inset: 0; overflow-y: auto; scrollbar-width: none">${gridG(G, 0, [...PICKS, PICKS[0], PICKS[1]])}<div style="height: 110px"></div></div>
<span aria-hidden="true" style="position: absolute; left: 0; right: 0; top: 0; height: 120px; background: linear-gradient(rgba(0, 0, 0, 0.34), rgba(0, 0, 0, 0)); pointer-events: none"></span>
<nav aria-label="팔레트 보기" ref="{{setTabs}}" style="position: absolute; left: 20px; top: 50px; display: flex; gap: 18px">
${wordTab('추천', true)}
${wordTab('구독', false)}
</nav>
${fanLayer()}
${fab}
${capsule({ color: myColor, active: 'palette' })}
</div>`, { logic: `${fanLogic(false)}
if (!this._tabs) { const refs = {}; this._tabs = { refs: refs, y: 0, dir: 0, acc: 0, hidden: false, set: (el) => { if (el) refs.tabs = el; } }; }
vals.setTabs = this._tabs.set;
vals.onScroll = (e) => this.tabsScroll(e.currentTarget.scrollTop);`, methods: `tabsScroll(raw) {
const t = this._tabs;
const y = Math.max(0, raw);
const d = y - t.y;
t.y = y;
if (d !== 0) { const dir = d > 0 ? 1 : -1; if (dir !== t.dir) { t.dir = dir; t.acc = 0; } t.acc += Math.abs(d); }
let hide = t.hidden;
if (y <= 40) hide = false;
else if (t.acc >= 24) hide = t.dir > 0;
if (hide === t.hidden || !t.refs.tabs) return;
t.hidden = hide;
const calm = !!(window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches);
const el = t.refs.tabs;
el.style.transition = calm ? 'opacity 160ms ease-out' : 'transform 240ms cubic-bezier(0.23, 1, 0.32, 1), opacity 200ms ease-out';
el.style.transform = hide && !calm ? 'translateY(-120%)' : 'none';
el.style.opacity = hide ? '0' : '1';
el.style.pointerEvents = hide ? 'none' : 'auto';
}` });

// R5-2 추천 · 구독도 부채 안에: the top is only photos. Which view you are on shows as a small word beside the round
// button; opening the paints also opens the 추천 · 구독 switch above the arc. Shown open.
files.ExplorePalette3FanAll = page('시안 R5-2 팔레트 · 추천·구독도 부채 안에', `<div style="${ROOT(`background: ${PAPER}; color: ${INK}`)}">
${fullGrid()}
<span style="position: absolute; right: ${393 - FAB.cx + FAB.d / 2 + 8}px; top: ${FAB.cy - 15}px; height: 30px; padding: 0 12px; border-radius: 15px; display: {{fabPaint}}; align-items: center; font-size: 13px; font-weight: 600" class="esel-glass">추천</span>
${fanLayer(`<div role="tablist" aria-label="팔레트 보기" class="esel-glass" style="position: absolute; left: 150px; top: 440px; width: 200px; height: 48px; box-sizing: border-box; padding: 4px; border-radius: 24px; display: flex; gap: 2px">${['추천', '구독'].map((l, i) => `<button type="button" role="tab" aria-selected="${i === 0}" style="flex: 1 1 0; border-radius: 20px; display: flex; align-items: center; justify-content: center; font-size: 15px; font-weight: 600; background: ${i === 0 ? 'rgba(255, 255, 255, 0.92)' : 'transparent'}; box-shadow: ${i === 0 ? '0 1px 6px rgba(0, 0, 0, 0.12)' : 'none'}">${l}</button>`).join('')}</div>`)}
${fab}
${capsule({ color: myColor, active: 'palette' })}
</div>`, { logic: fanLogic(true) });

// R5-2, improved (10-18): keep the top empty but make 추천 · 구독 one tap away and always visible.
// Both are interactive: the switch really swaps the grid, the round button opens and closes the paints.
// Subscriptions before I post also leave out my candidate colors (P01).
const SUBS = [PICKS[2], [{ key: 'ayo', py: 0.3 }, { key: 'rio', py: 0.4 }, { key: 'mira', py: 0.25 }, { key: 'ines', style: 'paint', py: 0.2 }, { key: 'elin', style: 'behind' }], [...PICKS[0]].reverse()];
const viewLogic = `const sub = !!(this.state && this.state.view === 'sub');
vals.pickDisplay = sub ? 'none' : 'block';
vals.subDisplay = sub ? 'block' : 'none';
vals.pickOn = sub ? 'false' : 'true';
vals.subOn = sub ? 'true' : 'false';
vals.pickSkin = sub ? 'background: transparent; box-shadow: none' : 'background: rgba(255, 255, 255, 0.92); box-shadow: 0 1px 6px rgba(0, 0, 0, 0.12)';
vals.subSkin = sub ? 'background: rgba(255, 255, 255, 0.92); box-shadow: 0 1px 6px rgba(0, 0, 0, 0.12)' : 'background: transparent; box-shadow: none';
vals.showPick = () => this.setState({ view: 'pick', fan: false });
vals.showSub = () => this.setState({ view: 'sub', fan: false });`;
const twoGrids = `<div class="esel-scroll" style="position: absolute; inset: 0; overflow-y: auto; scrollbar-width: none">
<div style="display: {{pickDisplay}}">${gridG(G, 0, [...PICKS, PICKS[0]])}</div>
<div style="display: {{subDisplay}}">${gridG(G, 0, [...SUBS, SUBS[0]])}</div>
<div style="height: 110px"></div></div>
<span aria-hidden="true" style="position: absolute; left: 0; right: 0; top: 0; height: 110px; background: linear-gradient(rgba(0, 0, 0, 0.32), rgba(0, 0, 0, 0)); pointer-events: none"></span>`;

// R5-3 엄지 옆 토글: a small glass 추천 | 구독 switch sits beside the round button, where the thumb already is.
// One tap switches, the current view is always visible, and nothing covers the top of the photos.
files.ExplorePalette3FanThumb = page('시안 R5-3 팔레트 · 엄지 옆 토글', `<div style="${ROOT(`background: ${PAPER}; color: ${INK}`)}">
${twoGrids}
${fanLayer()}
<div role="tablist" aria-label="팔레트 보기" class="esel-glass" style="position: absolute; right: ${393 - FAB.cx + FAB.d / 2 + 10}px; top: ${FAB.cy - 22}px; height: 44px; box-sizing: border-box; padding: 3px; border-radius: 22px; display: flex; gap: 2px">
<button type="button" role="tab" aria-selected="{{pickOn}}" onClick="{{showPick}}" style="height: 38px; padding: 0 14px; border-radius: 19px; font-size: 14px; font-weight: 600; {{pickSkin}}">추천</button>
<button type="button" role="tab" aria-selected="{{subOn}}" onClick="{{showSub}}" style="height: 38px; padding: 0 14px; border-radius: 19px; font-size: 14px; font-weight: 600; {{subSkin}}">구독</button>
</div>
${fab}
${capsule({ color: myColor, active: 'palette' })}
</div>`, { logic: `${fanLogic(false)}\n${viewLogic}` });

// R5-4 구독도 고르는 것 중 하나: the palette is one place to choose what to look at. The fan's inner arc holds 추천 and
// 구독, the next arc my three candidates, the outer arc the most chosen colors. The round button always shows the
// current view: three dabs for 추천, faces for 구독 (a chosen color would show that paint).
const dabs = `<span aria-hidden="true" style="position: relative; display: block; width: 46px; height: 34px">${paint('powder', 30, '; position: absolute; left: 0; top: 0; transform: rotate(-12deg)', '')}${paint('coral', 30, '; position: absolute; left: 14px; top: 9px; transform: rotate(-12deg)', '')}${paint('sage', 30, '; position: absolute; left: 6px; top: 18px; transform: rotate(-12deg)', '')}</span>`;
const faces = `<span aria-hidden="true" style="display: flex">${['dana', 'zuri', 'sol'].map((k, i) => `<span style="margin-left: ${i ? -9 : 0}px; border-radius: 50%; box-shadow: 0 0 0 2px #FFFFFF">${avatar(k, 22)}</span>`).join('')}</span>`;
const pickItem = (label, inner, deg, hole) => {
  const a = (deg * Math.PI) / 180;
  const x = Math.round(FAB.cx + 80 * Math.cos(a));
  const y = Math.round(FAB.cy + 80 * Math.sin(a));
  return `<button type="button" aria-label="${label}" aria-pressed="{{${hole}On}}" onClick="{{show${hole === 'pick' ? 'Pick' : 'Sub'}}}" class="esel-glass" style="position: absolute; left: ${x - 30}px; top: ${y - 30}px; width: 60px; height: 60px; border-radius: 50%; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 1px">${inner}<span style="font-size: 10.5px; font-weight: 700">${label}</span></button>`;
};
const r54Page = (title, openByDefault) => page(title, `<div style="${ROOT(`background: ${PAPER}; color: ${INK}`)}">
${twoGrids}
<div style="display: {{fanDisplay}}">
<span aria-hidden="true" onClick="{{toggleFan}}" style="position: absolute; inset: 0; background: radial-gradient(circle at ${FAB.cx}px ${FAB.cy}px, rgba(20, 20, 18, 0.5), rgba(20, 20, 18, 0.14) 280px)"></span>
${pickItem('추천', dabs.replace('width: 46px; height: 34px', 'width: 40px; height: 28px'), 200, 'pick')}
${pickItem('구독', faces, 250, 'sub')}
${arc(candidates, 142, 192, 258, true)}
${arc(others.slice(0, 5), 202, 182, 268)}
</div>
<button type="button" aria-label="{{fabLabel}}" aria-expanded="{{fabExpanded}}" onClick="{{toggleFan}}" style="position: absolute; left: ${FAB.cx - FAB.d / 2}px; top: ${FAB.cy - FAB.d / 2}px; width: ${FAB.d}px; height: ${FAB.d}px; border-radius: 50%; display: flex; align-items: center; justify-content: center; {{fabSkin}}"><span style="display: {{facePick}}">${dabs}</span><span style="display: {{faceSub}}">${faces}</span><span style="display: {{fabClose}}">${icon('x', 22, 2)}</span></button>
<span style="position: absolute; right: ${393 - FAB.cx + FAB.d / 2 + 8}px; top: ${FAB.cy - 15}px; height: 30px; padding: 0 12px; border-radius: 15px; display: {{fabPaint}}; align-items: center; font-size: 13px; font-weight: 600" class="esel-glass">{{viewName}}</span>
${capsule({ color: myColor, active: 'palette' })}
</div>`, { logic: `${fanLogic(openByDefault)}\n${viewLogic}
vals.facePick = !open && !sub ? 'flex' : 'none';
vals.faceSub = !open && sub ? 'flex' : 'none';
vals.viewName = sub ? '구독' : '추천';` });
files.ExplorePalette3FanChoose = r54Page('시안 R5-4 팔레트 · 구독도 고르는 것 중 하나', true);

// Icons and the plain grid used by the my-page layouts (one stroke weight, no labels on cells).
const ico = {
  grid: svg('<rect x="4.5" y="4.5" width="6" height="6" rx="1"></rect><rect x="13.5" y="4.5" width="6" height="6" rx="1"></rect><rect x="4.5" y="13.5" width="6" height="6" rx="1"></rect><rect x="13.5" y="13.5" width="6" height="6" rx="1"></rect>', 20),
  calendar: svg('<rect x="4" y="5.5" width="16" height="14" rx="2"></rect><path d="M4 10h16M8.5 3.5v4M15.5 3.5v4"></path>', 21),
  friends: svg('<circle cx="9" cy="9" r="3"></circle><path d="M3.5 19c.6-3 2.8-4.6 5.5-4.6s4.9 1.6 5.5 4.6"></path><circle cx="16.5" cy="8.5" r="2.4"></circle><path d="M15.5 14.2c2.4.1 4.3 1.6 4.9 4.3"></path>', 21),
  twin: svg('<circle cx="9.5" cy="12" r="5"></circle><circle cx="14.5" cy="12" r="5"></circle>', 21),
  theme: svg('<path d="M12 3.5l1.8 5.2 5.2 1.8-5.2 1.8L12 17.5l-1.8-5.2L5 10.5l5.2-1.8z"></path><path d="M18 16.5l.7 1.8 1.8.7-1.8.7-.7 1.8-.7-1.8-1.8-.7 1.8-.7z"></path>', 21),
  frame: svg('<rect x="4" y="4" width="16" height="16" rx="1"></rect><rect x="7.5" y="7.5" width="9" height="9"></rect>', 21),
  sliders: svg('<path d="M4 7h10M18 7h2M4 17h4M12 17h8"></path><circle cx="16" cy="7" r="2"></circle><circle cx="10" cy="17" r="2"></circle>', 21),
  more: svg('<circle cx="6" cy="12" r="1.3" fill="currentColor"></circle><circle cx="12" cy="12" r="1.3" fill="currentColor"></circle><circle cx="18" cy="12" r="1.3" fill="currentColor"></circle>', 24, 1.2),
  heart: icon('heartPlain', 21, 1.7),
};
const plainGrid = (list, gap = 2, bg = 'transparent') => `<section aria-label="내 캔버스" style="display: grid; grid-template-columns: 130px 129px 130px; gap: ${gap}px; background: ${bg}">${list.map((m) => mineCell(m, 130, 173, false)).join('')}</section>`;

// ───────── My sketchbook as a "my page", round 4 (10-18: "it's a my page"; "don't push the photos, keep them moderate").
// The page now has a job: how others see me, my archive, and the tools only I use. Photos are thumbnails and a grid,
// not a full-screen hero. 저장함 (saved canvases) is shown as a proposed new feature: the 저장 button exists, a list does not yet.
const SAVED = [{ key: 'riva', py: 0.5, color: 'cobalt' }, { key: 'zuri', color: 'coral' }, { key: 'ama', color: 'butter' }, { key: 'freya', style: 'behind', color: 'cream' }, { key: 'dana', color: 'powder' }, { key: 'vera', py: 0.5, color: 'terracotta' }];
const savedShot = (it, w, h) => `<span style="position: relative; display: block; width: ${w}px; height: ${h}px; overflow: hidden">${shot(it, w, h)}${it.style === 'behind' ? signOn(it, w, h) : ''}</span>`;
const week = MINE.slice(0, 7).reverse();
const weekDots = `<span style="display: flex; gap: 4px">${week.map((m) => `<span style="width: 9px; height: 9px; border-radius: 50%; background: ${PAINT[m.color].hex}"></span>`).join('')}</span>`;
const SOFT = '#EFEFEC';
const pillBtn = (label, extra = '') => `<a href="#" style="flex: 1 1 0; height: 40px; border-radius: 12px; display: flex; align-items: center; justify-content: center; gap: 6px; background: ${SOFT}; font-size: 14px; font-weight: 600${extra}">${label}</a>`;
const topIcons = (color = INK) => `<div style="position: absolute; right: 8px; top: 50px; display: flex; color: ${color}"><a href="#" aria-label="내 스케치북 공유" style="width: 44px; height: 44px; display: flex; align-items: center; justify-content: center">${share(22)}</a><a href="#" aria-label="설정" style="width: 44px; height: 44px; display: flex; align-items: center; justify-content: center">${gear(23)}</a></div>`;
const tabsTwo = `<nav aria-label="보관함" style="position: sticky; top: 0; z-index: 1; display: flex; background: ${PAPER}; border-bottom: 1px solid ${HAIR}">
<a href="#" aria-current="page" style="flex: 1 1 0; height: 46px; display: flex; align-items: center; justify-content: center; gap: 6px; font-size: 14px; font-weight: 600; box-shadow: inset 0 -1.5px 0 ${INK}">${ico.grid}내 캔버스</a>
<a href="#" style="flex: 1 1 0; height: 46px; display: flex; align-items: center; justify-content: center; gap: 6px; font-size: 14px; font-weight: 600; color: ${MUTED}">${icon('bookmark', 19, 1.7)}저장함<span style="font-size: 10px; font-weight: 700; color: ${INK}; background: #E4E0D6; padding: 1px 6px; border-radius: 8px">새 기능</span></a>
</nav>`;
const card = (inner, extra = '') => `<a href="#" style="display: flex; flex-direction: column; justify-content: space-between; padding: 14px; box-sizing: border-box; border-radius: 18px; background: #FFFFFF; box-shadow: inset 0 0 0 1px ${HAIR}${extra}">${inner}</a>`;
const cardHead = (ic, label, lock = false) => `<span style="display: flex; align-items: center; gap: 6px; font-size: 13px; font-weight: 600; color: ${MUTED}">${ic}${label}${lock ? `<span style="margin-left: auto; display: flex">${icon('lock', 12, 1.8)}</span>` : ''}</span>`;
const roundTool = (ic, label) => `<a href="#" style="width: 64px; display: flex; flex-direction: column; align-items: center; gap: 6px; font-size: 12px; font-weight: 600"><span style="width: 52px; height: 52px; border-radius: 50%; display: flex; align-items: center; justify-content: center; background: ${SOFT}">${ic}</span>${label}</a>`;
const myPage = (title, body, bg = PAPER) => page(title, `<div style="${ROOT(`background: ${bg}; color: ${INK}`)}">
<div class="esel-scroll" style="position: absolute; inset: 0; overflow-y: auto; scrollbar-width: none">${body}${plainGrid(MINE)}<div style="height: 110px"></div></div>
${meCap}
</div>`);

// V1 정돈된 프로필: the familiar profile order, done carefully. Me, two buttons, today's canvas in one line, then the
// three things only I see as equal tiles, the people and content tools as round buttons, and the archive tabs.
files.ExploreMy1Profile = myPage('시안 V1 마이페이지 · 정돈된 프로필', `${topIcons()}
<header style="padding: 104px 20px 0">
<div style="display: flex; align-items: center; gap: 16px">${avatar(ME, 76)}<div><h1 style="margin: 0; font-family: ${SERIF}; font-style: italic; font-weight: 400; font-size: 40px; line-height: 1">${ME}</h1><p style="margin: 6px 0 0; font-size: 14px; line-height: 1.45; color: ${MUTED}">${BIO}</p></div></div>
<div style="margin-top: 16px; display: flex; gap: 8px">${pillBtn('프로필 편집')}${pillBtn('공유')}</div>
<a href="#" style="margin-top: 14px; padding: 10px 12px; border-radius: 16px; display: flex; align-items: center; gap: 12px; background: #FFFFFF; box-shadow: inset 0 0 0 1px ${HAIR}">${mineCell(MINE[0], 40, 54, false, 'span')}<span style="display: flex; flex-direction: column; gap: 2px"><span style="font-size: 12px; color: ${MUTED}">오늘의 캔버스 · 올렸어요</span><span style="display: flex; align-items: center; gap: 4px; font-size: 15px; font-weight: 600">${paint(myColor, 32, '', '')}${PAINT[myColor].name} · Nº 012</span></span><span style="margin-left: auto; display: flex; color: ${MUTED}">${right(18)}</span></a>
<p style="margin: 20px 2px 8px; display: flex; align-items: center; gap: 5px; font-size: 12px; font-weight: 600; color: ${MUTED}">${icon('lock', 12, 1.8)}나에게만 보여요</p>
<div style="display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 8px">
${card(`${cardHead(ico.heart, '반응')}<span style="font-size: 26px; font-weight: 600; letter-spacing: -0.02em">${OWN.likes}</span><span style="font-size: 11px; color: ${MUTED}">이번 주 좋아요</span>`, '; height: 112px')}
${card(`${cardHead(ico.calendar, '색 달력')}${weekDots}<span style="font-size: 11px; color: ${MUTED}">최근 7일</span>`, '; height: 112px')}
${card(`${cardHead(icon('bookmark', 19, 1.7), '저장함')}<span style="font-size: 26px; font-weight: 600; letter-spacing: -0.02em">24</span><span style="font-size: 11px; color: ${MUTED}">저장한 캔버스</span>`, '; height: 112px')}
</div>
<nav aria-label="함께" style="margin: 20px 0 18px; display: flex; justify-content: space-between">${roundTool(ico.friends, '친구')}${roundTool(ico.twin, '트윈')}${roundTool(ico.theme, '이번 주 주제')}${roundTool(ico.frame, '전시')}</nav>
</header>
${tabsTwo}`);

// V2 표지와 대시보드: my latest canvas as a small cover on the left (how others see me), my facts on the right, then a
// two-by-two board of what I check: reactions, color calendar, friends and twin, this week's theme.
const monthDots = `<span style="display: grid; grid-template-columns: repeat(7, 9px); gap: 4px">${Array.from({ length: 21 }, (_, i) => { const d = i - 14; const m = MINE.find((x) => x.date === `9. ${6 + d}.` || x.date === `8. ${31 + d + 6}.`); return `<span style="width: 9px; height: 9px; border-radius: 50%; background: ${m ? PAINT[m.color].hex : 'transparent'}; box-shadow: ${m ? 'none' : `inset 0 0 0 1px ${HAIR}`}"></span>`; }).join('')}</span>`;
files.ExploreMy2Board = myPage('시안 V2 마이페이지 · 표지와 대시보드', `${topIcons()}
<header style="padding: 104px 20px 0">
<div style="display: flex; gap: 16px">
<a href="#" aria-label="남에게 보이는 내 표지" style="flex-shrink: 0; position: relative; width: 132px; height: 176px; border-radius: 4px; overflow: hidden; box-shadow: 0 10px 24px rgba(41, 42, 39, 0.18); color: #FFFFFF">${cover(ME, 132, 176, 0.5, 0.25)}<span aria-hidden="true" style="position: absolute; left: 0; right: 0; top: 0; height: 40%; background: linear-gradient(rgba(0, 0, 0, 0.3), rgba(0, 0, 0, 0))"></span><span aria-hidden="true" style="position: absolute; left: 0; right: 0; top: 6px; text-align: center; font-family: ${SERIF}; font-size: 42px; line-height: 0.9; letter-spacing: -0.05em">${ME}</span></a>
<div style="flex: 1 1 0; min-width: 0; display: flex; flex-direction: column">
<h1 style="margin: 0; font-family: ${SERIF}; font-style: italic; font-weight: 400; font-size: 36px; line-height: 1">${ME}</h1>
<p style="margin: 6px 0 0; font-size: 14px; line-height: 1.45; color: ${MUTED}">${BIO}</p>
<span style="margin-top: 8px; display: flex; align-items: center; gap: 4px; font-size: 13px; font-weight: 600">${paint(myColor, 32, '', '')}오늘은 ${PAINT[myColor].name}</span>
<div style="margin-top: auto; display: flex; gap: 6px">${pillBtn('편집', '; height: 36px; font-size: 13px')}${pillBtn('공유', '; height: 36px; font-size: 13px')}</div>
</div>
</div>
<div style="margin: 20px 0 18px; display: grid; grid-template-columns: 1fr 1fr; gap: 10px">
${card(`${cardHead(ico.heart, '내 반응', true)}<span style="display: flex; align-items: baseline; gap: 10px"><span style="font-size: 26px; font-weight: 600">${OWN.likes}</span><span style="font-size: 12px; color: ${MUTED}">한 줄 ${OWN.lines} · 저장 ${OWN.saves}</span></span>`, '; height: 104px')}
${card(`${cardHead(ico.calendar, '색 달력')}${monthDots}`, '; height: 104px')}
${card(`${cardHead(ico.friends, '친구 · 트윈')}<span style="display: flex; align-items: center; gap: 8px"><span style="display: flex">${['dana', 'zuri', 'ama'].map((k, i) => `<span style="margin-left: ${i ? -10 : 0}px; border-radius: 50%; box-shadow: 0 0 0 2px #FFFFFF">${avatar(k, 28)}</span>`).join('')}</span><span style="font-size: 12px; color: ${MUTED}">친구 8 · 트윈 1</span></span>`, '; height: 104px')}
${card(`${cardHead(ico.theme, '이번 주 주제')}<span style="font-family: ${SERIF}; font-size: 19px; line-height: 1.15">같은 옷, 다른 코디</span>`, '; height: 104px')}
</div>
</header>
${tabsTwo}`);

// ───────── My page, round 5 (10-18: keep V1 and V2, ten more in that vein). Same family: an organised profile, a small
// cover at most, the things only I see gathered in cards, round tools, the archive tabs. Each varies one part.
const signH = (size = 40) => `<h1 style="margin: 0; font-family: ${SERIF}; font-style: italic; font-weight: 400; font-size: ${size}px; line-height: 1">${ME}</h1>`;
const bioP = (extra = '') => `<p style="margin: 6px 0 0; font-size: 14px; line-height: 1.45; color: ${MUTED}${extra}">${BIO}</p>`;
const btns = (extra = '') => `<div style="margin-top: 16px; display: flex; gap: 8px${extra}">${pillBtn('프로필 편집')}${pillBtn('공유')}</div>`;
const todayLine = `<a href="#" style="margin-top: 14px; padding: 10px 12px; border-radius: 16px; display: flex; align-items: center; gap: 12px; background: #FFFFFF; box-shadow: inset 0 0 0 1px ${HAIR}">${mineCell(MINE[0], 40, 54, false, 'span')}<span style="display: flex; flex-direction: column; gap: 2px"><span style="font-size: 12px; color: ${MUTED}">오늘의 캔버스 · 올렸어요</span><span style="display: flex; align-items: center; gap: 4px; font-size: 15px; font-weight: 600">${paint(myColor, 32, '', '')}${PAINT[myColor].name} · Nº 012</span></span><span style="margin-left: auto; display: flex; color: ${MUTED}">${right(18)}</span></a>`;
const onlyMe = (m = '20px 2px 8px') => `<p style="margin: ${m}; display: flex; align-items: center; gap: 5px; font-size: 12px; font-weight: 600; color: ${MUTED}">${icon('lock', 12, 1.8)}나에게만 보여요</p>`;
const bigNum = (n, label) => `<span style="font-size: 26px; font-weight: 600; letter-spacing: -0.02em">${n}</span><span style="font-size: 11px; color: ${MUTED}">${label}</span>`;
const tilesThree = (h = 112, extra = '') => `<div style="display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 8px">
${card(`${cardHead(ico.heart, '반응')}${bigNum(OWN.likes, '이번 주 좋아요')}`, `; height: ${h}px${extra}`)}
${card(`${cardHead(ico.calendar, '색 달력')}${weekDots}<span style="font-size: 11px; color: ${MUTED}">최근 7일</span>`, `; height: ${h}px${extra}`)}
${card(`${cardHead(icon('bookmark', 19, 1.7), '저장함')}${bigNum(24, '저장한 캔버스')}`, `; height: ${h}px${extra}`)}
</div>`;
const toolsFour = (m = '20px 0 18px') => `<nav aria-label="함께" style="margin: ${m}; display: flex; justify-content: space-between">${roundTool(ico.friends, '친구')}${roundTool(ico.twin, '트윈')}${roundTool(ico.theme, '이번 주 주제')}${roundTool(ico.frame, '전시')}</nav>`;
const smallCover = (w, h, fs) => `<a href="#" aria-label="남에게 보이는 내 표지" style="flex-shrink: 0; position: relative; width: ${w}px; height: ${h}px; border-radius: 4px; overflow: hidden; box-shadow: 0 10px 24px rgba(41, 42, 39, 0.18); color: #FFFFFF">${cover(ME, w, h, 0.5, 0.25)}<span aria-hidden="true" style="position: absolute; left: 0; right: 0; top: 0; height: 40%; background: linear-gradient(rgba(0, 0, 0, 0.3), rgba(0, 0, 0, 0))"></span><span aria-hidden="true" style="position: absolute; left: 0; right: 0; top: 5px; text-align: center; font-family: ${SERIF}; font-size: ${fs}px; line-height: 0.9; letter-spacing: -0.05em">${ME}</span></a>`;
const avatars3 = (d = 28) => `<span style="display: flex">${['dana', 'zuri', 'ama'].map((k, i) => `<span style="margin-left: ${i ? -10 : 0}px; border-radius: 50%; box-shadow: 0 0 0 2px #FFFFFF">${avatar(k, d)}</span>`).join('')}</span>`;
const themeTitle = (fs = 19) => `<span style="font-family: ${SERIF}; font-size: ${fs}px; line-height: 1.15">같은 옷, 다른 코디</span>`;
const v2Head = (cw = 132, ch = 176, fs = 42) => `<div style="display: flex; gap: 16px">${smallCover(cw, ch, fs)}<div style="flex: 1 1 0; min-width: 0; display: flex; flex-direction: column">${signH(36)}${bioP()}<span style="margin-top: 8px; display: flex; align-items: center; gap: 4px; font-size: 13px; font-weight: 600">${paint(myColor, 32, '', '')}오늘은 ${PAINT[myColor].name}</span><div style="margin-top: auto; display: flex; gap: 6px">${pillBtn('편집', '; height: 36px; font-size: 13px')}${pillBtn('공유', '; height: 36px; font-size: 13px')}</div></div></div>`;
const head = (inner) => `${topIcons()}<header style="padding: 104px 20px 0">${inner}</header>`;

// W1 표지 썸네일 + 카드 3칸: V2's small cover in V1's place of the face, then V1 as it was.
files.ExploreMy6CoverTiles = myPage('시안 W1 마이페이지 · 표지 썸네일 + 카드 3칸', head(`<div style="display: flex; align-items: center; gap: 16px">${smallCover(96, 128, 31)}<div>${signH(38)}${bioP()}<span style="margin-top: 6px; display: flex; align-items: center; gap: 4px; font-size: 13px; font-weight: 600">${paint(myColor, 30, '', '')}오늘은 ${PAINT[myColor].name}</span></div></div>
${btns()}${onlyMe()}${tilesThree()}${toolsFour()}`) + tabsTwo);

// W2 가로로 넘기는 카드: V2's head, and the dashboard becomes a row of larger cards you swipe through, saved canvases
// shown as a small stack of prints.
const swipeCard = (inner) => `<a href="#" style="flex-shrink: 0; width: 148px; height: 132px; padding: 14px; box-sizing: border-box; border-radius: 18px; display: flex; flex-direction: column; justify-content: space-between; background: #FFFFFF; box-shadow: inset 0 0 0 1px ${HAIR}">${inner}</a>`;
const savedStack = `<span style="position: relative; display: block; height: 62px">${SAVED.slice(0, 3).map((it, i) => `<span style="position: absolute; left: ${i * 26}px; top: ${i % 2 ? 4 : 0}px; border-radius: 4px; overflow: hidden; box-shadow: 0 4px 10px rgba(41, 42, 39, 0.18); transform: rotate(${(i - 1) * 6}deg)">${savedShot(it, 44, 58)}</span>`).join('')}</span>`;
files.ExploreMy7Swipe = myPage('시안 W2 마이페이지 · 가로로 넘기는 카드', head(`${v2Head()}
<p style="margin: 22px 2px 10px; display: flex; align-items: center; justify-content: space-between; font-size: 13px; font-weight: 600"><span>나의 요약</span><span style="display: flex; align-items: center; gap: 4px; font-weight: 500; color: ${MUTED}">${icon('lock', 12, 1.8)}나에게만</span></p>`) + `<div class="esel-scroll" style="display: flex; gap: 10px; overflow-x: auto; padding: 0 20px 20px; scrollbar-width: none">
${swipeCard(`${cardHead(ico.heart, '내 반응')}<span style="display: flex; flex-direction: column"><span style="font-size: 30px; font-weight: 600; letter-spacing: -0.02em">${OWN.likes}</span><span style="font-size: 12px; color: ${MUTED}">한 줄 ${OWN.lines} · 저장 ${OWN.saves}</span></span>`)}
${swipeCard(`${cardHead(ico.calendar, '색 달력')}${monthDots}`)}
${swipeCard(`${cardHead(icon('bookmark', 19, 1.7), '저장함')}${savedStack}`)}
${swipeCard(`${cardHead(ico.friends, '친구 · 트윈')}<span style="display: flex; flex-direction: column; gap: 8px">${avatars3(30)}<span style="font-size: 12px; color: ${MUTED}">친구 8 · 트윈 1</span></span>`)}
${swipeCard(`${cardHead(ico.theme, '이번 주 주제')}${themeTitle(20)}`)}
</div>` + tabsTwo);

// W3 숫자 줄 + 2×2: V1's head with a quiet line of three numbers under it (two of them only I see), then a 2×2 board.
const statCol = (n, label, lock = false) => `<a href="#" style="flex: 1 1 0; display: flex; flex-direction: column; align-items: center; gap: 2px"><span style="font-size: 20px; font-weight: 600">${n}</span><span style="display: flex; align-items: center; gap: 3px; font-size: 12px; color: ${MUTED}">${lock ? icon('lock', 11, 1.8) : ''}${label}</span></a>`;
files.ExploreMy8Stats = myPage('시안 W3 마이페이지 · 숫자 줄 + 2×2', head(`<div style="display: flex; align-items: center; gap: 16px">${avatar(ME, 76)}<div>${signH(40)}${bioP()}</div></div>
<div style="margin-top: 18px; padding: 12px 0; display: flex; align-items: center; border-top: 1px solid ${HAIR}; border-bottom: 1px solid ${HAIR}">${statCol(12, '캔버스')}<span style="width: 1px; height: 28px; background: ${HAIR}"></span>${statCol(OWN.likes, '이번 주 반응', true)}<span style="width: 1px; height: 28px; background: ${HAIR}"></span>${statCol(8, '친구')}</div>
${btns()}
<div style="margin: 18px 0; display: grid; grid-template-columns: 1fr 1fr; gap: 10px">
${card(`${cardHead(ico.calendar, '색 달력')}${monthDots}`, '; height: 104px')}
${card(`${cardHead(icon('bookmark', 19, 1.7), '저장함')}${bigNum(24, '저장한 캔버스')}`, '; height: 104px')}
${card(`${cardHead(ico.twin, '트윈')}<span style="font-size: 14px; font-weight: 600">dana와 진행 중</span>`, '; height: 104px')}
${card(`${cardHead(ico.theme, '이번 주 주제')}${themeTitle(18)}`, '; height: 104px')}
</div>`) + tabsTwo);

// W4 오늘 큰 카드: today's canvas gets a proper card (print, my line, number, two actions), the rest compacts below it.
files.ExploreMy9Today = myPage('시안 W4 마이페이지 · 오늘 큰 카드', head(`<div style="display: flex; align-items: center; gap: 12px">${avatar(ME, 56)}<div style="flex: 1 1 0">${signH(32)}${bioP('; margin-top: 4px; font-size: 13.5px')}</div><a href="#" style="height: 34px; padding: 0 14px; border-radius: 17px; display: flex; align-items: center; background: ${SOFT}; font-size: 13px; font-weight: 600">편집</a></div>
<section style="margin-top: 18px; padding: 14px; border-radius: 20px; display: flex; gap: 14px; background: #FFFFFF; box-shadow: inset 0 0 0 1px ${HAIR}">
<span style="flex-shrink: 0; border-radius: 4px; overflow: hidden; box-shadow: 0 6px 16px rgba(41, 42, 39, 0.14)">${mineCell(MINE[0], 96, 128, false, 'span')}</span>
<div style="flex: 1 1 0; display: flex; flex-direction: column; gap: 4px">
<span style="font-size: 12px; font-weight: 600; color: ${MUTED}">오늘의 캔버스 · 9월 6일</span>
<span style="font-family: ${SERIF}; font-style: italic; font-size: 20px; line-height: 1.2">${MINE[0].cap}</span>
<span style="display: flex; align-items: center; gap: 4px; font-size: 13px; font-weight: 600">${paint(myColor, 30, '', '')}${PAINT[myColor].name} · Nº 012</span>
<span style="margin-top: auto; display: flex; gap: 6px">${pillBtn('자세히', '; flex: 0 0 auto; height: 32px; padding: 0 12px; font-size: 12.5px')}${pillBtn('공유', '; flex: 0 0 auto; height: 32px; padding: 0 12px; font-size: 12.5px')}</span>
</div>
</section>
${onlyMe('18px 2px 8px')}${tilesThree(92)}${toolsFour()}`) + tabsTwo);

// W5 색 달력 크게: V2's head, then the month as the main card (a dot per day in that day's color), with reactions and
// saved as two small cards beside each other.
const SEPT_DOTS = {};
MINE.forEach((m) => { const [mo, d] = m.date.split('.').map((x) => parseInt(x.trim(), 10)); if (mo === 9) SEPT_DOTS[d] = m.color; });
const monthCard = `<a href="#" style="margin-top: 18px; padding: 14px 16px; border-radius: 18px; display: block; background: #FFFFFF; box-shadow: inset 0 0 0 1px ${HAIR}">
<span style="display: flex; align-items: baseline; justify-content: space-between"><span style="font-family: ${SERIF}; font-size: 22px">9월의 색</span><span style="display: flex; align-items: center; font-size: 13px; font-weight: 600">색 달력${right(15)}</span></span>
<span style="margin-top: 10px; display: grid; grid-template-columns: repeat(7, 1fr); row-gap: 8px; justify-items: center">${['일', '월', '화', '수', '목', '금', '토'].map((d) => `<span style="font-size: 10px; color: ${MUTED}">${d}</span>`).join('')}${'<span></span>'.repeat(new Date(Date.UTC(2026, 8, 1)).getUTCDay())}${Array.from({ length: 30 }, (_, i) => { const d = i + 1; const c = SEPT_DOTS[d]; return `<span style="width: 18px; height: 18px; border-radius: 50%; background: ${c ? PAINT[c].hex : 'transparent'}; box-shadow: ${d === 6 ? `0 0 0 2px #FFFFFF, 0 0 0 3.5px ${INK}` : c ? 'none' : `inset 0 0 0 1px ${d < 6 ? '#D3D3CE' : '#EDEDEA'}`}"></span>`; }).join('')}</span>
</a>`;
files.ExploreMy10Month = myPage('시안 W5 마이페이지 · 색 달력 크게', head(`${v2Head(112, 150, 36)}${monthCard}
<div style="margin-top: 10px; display: grid; grid-template-columns: 1fr 1fr; gap: 10px">
${card(`${cardHead(ico.heart, '내 반응', true)}<span style="display: flex; align-items: baseline; gap: 8px"><span style="font-size: 24px; font-weight: 600">${OWN.likes}</span><span style="font-size: 12px; color: ${MUTED}">이번 주</span></span>`, '; height: 92px')}
${card(`${cardHead(icon('bookmark', 19, 1.7), '저장함')}<span style="display: flex; align-items: baseline; gap: 8px"><span style="font-size: 24px; font-weight: 600">24</span><span style="font-size: 12px; color: ${MUTED}">캔버스</span></span>`, '; height: 92px')}
</div>${toolsFour('18px 0 18px')}`) + tabsTwo);

// W6 세그먼트 대시보드: one switch (요약 · 기록 · 사람) changes what the board shows, so the page never grows long.
const seg3 = `<div role="tablist" aria-label="대시보드" style="margin-top: 18px; height: 40px; padding: 3px; box-sizing: border-box; border-radius: 20px; display: flex; background: #ECECEA">${['요약', '기록', '사람'].map((l, i) => `<button type="button" role="tab" aria-selected="${i === 0}" style="flex: 1 1 0; display: flex; align-items: center; justify-content: center; text-align: center; border-radius: 17px; font-size: 14px; font-weight: 600; background: ${i === 0 ? '#FFFFFF' : 'transparent'}; color: ${i === 0 ? INK : MUTED}; box-shadow: ${i === 0 ? '0 1px 4px rgba(0, 0, 0, 0.12)' : 'none'}">${l}</button>`).join('')}</div>`;
files.ExploreMy11Segment = myPage('시안 W6 마이페이지 · 세그먼트 대시보드', head(`<div style="display: flex; align-items: center; gap: 16px">${avatar(ME, 76)}<div>${signH(40)}${bioP()}</div></div>${btns()}${seg3}
<div style="margin: 12px 0 18px; display: grid; grid-template-columns: 1fr 1fr; gap: 10px">
${card(`${cardHead(ico.heart, '내 반응', true)}${bigNum(OWN.likes, `한 줄 ${OWN.lines} · 저장 ${OWN.saves}`)}`, '; height: 108px')}
${card(`${cardHead(paint(myColor, 24, '', ''), '오늘의 캔버스')}<span style="font-size: 15px; font-weight: 600">Nº 012 · 올렸어요</span><span style="font-size: 11px; color: ${MUTED}">${PAINT[myColor].name}</span>`, '; height: 108px')}
${card(`${cardHead(icon('bookmark', 19, 1.7), '저장함')}${bigNum(24, '저장한 캔버스')}`, '; height: 108px')}
${card(`${cardHead(ico.theme, '이번 주 주제')}${themeTitle(18)}`, '; height: 108px')}
</div>`) + tabsTwo);

// W7 먹색 카드: V2 with the board in ink, the one dark block on a light page, so the things only I see feel private.
const inkCard = (inner, extra = '') => `<a href="#" style="display: flex; flex-direction: column; justify-content: space-between; padding: 14px; box-sizing: border-box; border-radius: 18px; background: #262624; color: #F4F4F1${extra}">${inner}</a>`;
const inkHead = (ic, label, lock = false) => `<span style="display: flex; align-items: center; gap: 6px; font-size: 13px; font-weight: 600; color: #A9AAA3">${ic}${label}${lock ? `<span style="margin-left: auto; display: flex">${icon('lock', 12, 1.8)}</span>` : ''}</span>`;
files.ExploreMy12Ink = myPage('시안 W7 마이페이지 · 먹색 카드', head(`${v2Head()}
<div style="margin: 20px 0 18px; display: grid; grid-template-columns: 1fr 1fr; gap: 10px">
${inkCard(`${inkHead(ico.heart, '내 반응', true)}<span style="display: flex; align-items: baseline; gap: 10px"><span style="font-size: 26px; font-weight: 600">${OWN.likes}</span><span style="font-size: 12px; color: #A9AAA3">한 줄 ${OWN.lines} · 저장 ${OWN.saves}</span></span>`, '; height: 104px')}
${inkCard(`${inkHead(ico.calendar, '색 달력')}${monthDots.replaceAll(`inset 0 0 0 1px ${HAIR}`, 'inset 0 0 0 1px #4A4A46')}`, '; height: 104px')}
${inkCard(`${inkHead(ico.friends, '친구 · 트윈')}<span style="display: flex; align-items: center; gap: 8px">${avatars3(28).replaceAll('#FFFFFF', '#262624')}<span style="font-size: 12px; color: #A9AAA3">친구 8 · 트윈 1</span></span>`, '; height: 104px')}
${inkCard(`${inkHead(ico.theme, '이번 주 주제')}${themeTitle(19)}`, '; height: 104px')}
</div>`) + tabsTwo);

// W8 오늘의 색으로 물든 페이지: V1, but the page takes today's color as its accent (buttons, card tint, the ring round
// my face). Tomorrow it changes with the color I choose: the page itself is a record of the day.
const AC = { tint: '#F3EADF', deep: '#7E5A33', ring: PAINT[myColor].hex };
const acCard = (inner) => `<a href="#" style="height: 112px; display: flex; flex-direction: column; justify-content: space-between; padding: 14px; box-sizing: border-box; border-radius: 18px; background: #FFFFFF; box-shadow: inset 0 0 0 1px ${HAIR}">${inner}</a>`;
const acHead = (ic, label) => `<span style="display: flex; align-items: center; gap: 6px; font-size: 13px; font-weight: 600; color: ${AC.deep}">${ic}${label}</span>`;
files.ExploreMy13Accent = myPage('시안 W8 마이페이지 · 오늘의 색으로 물든 페이지', head(`<div style="display: flex; align-items: center; gap: 16px"><span style="border-radius: 50%; box-shadow: 0 0 0 3px ${PAPER}, 0 0 0 6px ${AC.ring}">${avatar(ME, 72)}</span><div>${signH(40)}${bioP()}</div></div>
<div style="margin-top: 18px; display: flex; gap: 8px">${pillBtn('프로필 편집', `; background: ${AC.tint}; color: ${AC.deep}`)}${pillBtn('공유', `; background: ${AC.tint}; color: ${AC.deep}`)}</div>
<a href="#" style="margin-top: 14px; padding: 12px 14px; border-radius: 16px; display: flex; align-items: center; gap: 10px; background: ${AC.tint}">${paint(myColor, 52, '', '')}<span style="display: flex; flex-direction: column"><span style="font-size: 12px; color: ${AC.deep}">오늘은 ${PAINT[myColor].name}</span><span style="font-size: 15px; font-weight: 600">Nº 012 올렸어요</span></span><span style="margin-left: auto; display: flex; color: ${AC.deep}">${right(18)}</span></a>
${onlyMe()}
<div style="display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 8px">
${acCard(`${acHead(ico.heart, '반응')}${bigNum(OWN.likes, '이번 주 좋아요')}`)}
${acCard(`${acHead(ico.calendar, '색 달력')}${weekDots}<span style="font-size: 11px; color: ${MUTED}">최근 7일</span>`)}
${acCard(`${acHead(icon('bookmark', 19, 1.7), '저장함')}${bigNum(24, '저장한 캔버스')}`)}
</div>
${toolsFour().replaceAll(`background: ${SOFT}`, `background: ${AC.tint}; color: ${AC.deep}`)}`) + tabsTwo);

// W9 비대칭 대시보드: one large card for my reactions with a week of bars, two small cards stacked beside it.
const WEEK_LIKES = [8, 14, 22, 12, 30, 18, 24];
const bars = `<span style="display: flex; align-items: flex-end; gap: 6px; height: 54px">${WEEK_LIKES.map((v, i) => `<span style="width: 12px; height: ${Math.round((v / 30) * 54)}px; border-radius: 3px; background: ${i === 6 ? INK : '#D9D6CF'}"></span>`).join('')}</span>`;
files.ExploreMy14Asym = myPage('시안 W9 마이페이지 · 비대칭 대시보드', head(`<div style="display: flex; align-items: center; gap: 16px">${avatar(ME, 76)}<div>${signH(40)}${bioP()}</div></div>${btns()}${onlyMe()}
<div style="display: grid; grid-template-columns: 1.25fr 1fr; gap: 10px">
${card(`${cardHead(ico.heart, '이번 주 반응')}<span style="display: flex; align-items: flex-end; justify-content: space-between"><span style="display: flex; flex-direction: column"><span style="font-size: 32px; font-weight: 600; letter-spacing: -0.02em">${OWN.likes}</span><span style="font-size: 11px; color: ${MUTED}">한 줄 ${OWN.lines} · 저장 ${OWN.saves}</span></span>${bars}</span>`, '; height: 156px')}
<div style="display: flex; flex-direction: column; gap: 10px">
${card(`${cardHead(ico.calendar, '색 달력')}${weekDots}`, '; height: 73px')}
${card(`${cardHead(icon('bookmark', 19, 1.7), '저장함')}<span style="font-size: 20px; font-weight: 600">24</span>`, '; height: 73px')}
</div>
</div>${toolsFour()}`) + tabsTwo);

// W10 가운데 정렬: V1 centred, a calmer, more formal profile; today's color as a single chip under my line.
files.ExploreMy15Center = myPage('시안 W10 마이페이지 · 가운데 정렬', `${topIcons()}<header style="padding: 100px 20px 0; display: flex; flex-direction: column; align-items: center; text-align: center">${avatar(ME, 80)}<div style="margin-top: 12px">${signH(42)}</div>${bioP()}
<span style="margin-top: 10px; height: 32px; padding: 0 12px 0 6px; border-radius: 16px; display: inline-flex; align-items: center; gap: 4px; background: #FFFFFF; box-shadow: inset 0 0 0 1px ${HAIR}; font-size: 13px; font-weight: 600">${paint(myColor, 30, '', '')}오늘은 ${PAINT[myColor].name} · 올렸어요</span>
<div style="margin-top: 16px; width: 100%; display: flex; gap: 8px">${pillBtn('프로필 편집')}${pillBtn('공유')}</div>
<div style="width: 100%; text-align: left">${onlyMe()}${tilesThree()}</div>
<div style="width: 100%">${toolsFour()}</div>
</header>` + tabsTwo);

// ───────── My page from references (10-18: the user named Instagram, Pinterest and 29CM / W Concept). What they share:
// a short "about me", the photos or saved collections right away, and order made with type and thin rules rather than
// grey round icons and cards. Each layout leans on one reference and keeps Esel's serif sign and paint.
const BLACK = '#111111';
const LINE = '#E6E6E3';
const sqBtn = (label, filled = false, extra = '') => `<a href="#" style="flex: 1 1 0; height: 38px; display: flex; align-items: center; justify-content: center; border-radius: 4px; font-size: 13.5px; font-weight: 600; ${filled ? `background: ${BLACK}; color: #FFFFFF` : `box-shadow: inset 0 0 0 1px ${BLACK}`}${extra}">${label}</a>`;
const igStat = (n, label, lock = false) => `<a href="#" style="flex: 1 1 0; display: flex; flex-direction: column; align-items: center; gap: 1px"><span style="font-size: 17px; font-weight: 700">${n}</span><span style="display: flex; align-items: center; gap: 2px; font-size: 12.5px; color: ${INK}">${lock ? icon('lock', 10, 2) : ''}${label}</span></a>`;
const iconTabs = (active = 0) => `<nav aria-label="보관함" style="position: sticky; top: 0; z-index: 1; display: flex; background: #FFFFFF; border-bottom: 1px solid ${LINE}">${[[ico.grid, '내 캔버스'], [icon('bookmark', 20, 1.7), '저장함']].map(([ic, label], i) => `<a href="#" aria-label="${label}"${i === active ? ' aria-current="page"' : ''} style="flex: 1 1 0; height: 44px; display: flex; align-items: center; justify-content: center; color: ${i === active ? INK : '#A3A49E'}; box-shadow: ${i === active ? `inset 0 -1.5px 0 ${INK}` : 'none'}">${ic}</a>`).join('')}</nav>`;
// Instagram-style highlights, but each circle is something of mine: this month's colors, my friends, the twin, the theme.
const ring = (inner, label) => `<a href="#" style="flex-shrink: 0; width: 66px; display: flex; flex-direction: column; align-items: center; gap: 5px; font-size: 11.5px"><span style="width: 62px; height: 62px; border-radius: 50%; display: flex; align-items: center; justify-content: center; box-shadow: inset 0 0 0 1px ${LINE}; background: #FFFFFF">${inner}</span>${label}</a>`;
const colorRing = `<span style="position: relative; width: 54px; height: 54px; border-radius: 50%; overflow: hidden; background: conic-gradient(${week.map((m, i) => `${PAINT[m.color].hex} ${(i / week.length) * 100}% ${((i + 1) / week.length) * 100}%`).join(', ')})"><span style="position: absolute; inset: 14px; border-radius: 50%; background: #FFFFFF"></span></span>`;
const pair = `<span style="position: relative; width: 54px; height: 54px"><span style="position: absolute; left: 2px; top: 6px; border-radius: 50%; box-shadow: 0 0 0 2px #FFFFFF">${avatar('dana', 34)}</span><span style="position: absolute; right: 2px; bottom: 6px; border-radius: 50%; box-shadow: 0 0 0 2px #FFFFFF">${avatar(ME, 34)}</span></span>`;
const photoRing = (key) => `<span style="width: 54px; height: 54px; border-radius: 50%; overflow: hidden">${avatar(key, 54)}</span>`;
const refPage = (title, body, bg = '#FFFFFF') => page(title, `<div style="${ROOT(`background: ${bg}; color: ${INK}`)}">
<div class="esel-scroll" style="position: absolute; inset: 0; overflow-y: auto; scrollbar-width: none">${body}<div style="height: 110px"></div></div>
${meCap}
</div>`);
const topBarRef = (left) => `<header style="height: 44px; margin-top: 50px; padding: 0 8px 0 16px; display: flex; align-items: center; gap: 8px">${left}<span style="margin-left: auto; display: flex"><a href="#" aria-label="공유" style="width: 44px; height: 44px; display: flex; align-items: center; justify-content: center">${share(22)}</a><a href="#" aria-label="설정" style="width: 44px; height: 44px; display: flex; align-items: center; justify-content: center">${gear(23)}</a></span></header>`;

// X1 인스타그램 + Esel: face and three numbers in a row (the follower count only I see), a short bio, today's paint,
// edit and share, highlights that are my own things, then straight to the grid.
files.ExploreRef1Insta = refPage('시안 X1 마이페이지 · 인스타그램 결', `${topBarRef(`<span style="font-family: ${SERIF}; font-style: italic; font-size: 28px; line-height: 1">${ME}</span>`)}
<section style="padding: 8px 16px 0">
<div style="display: flex; align-items: center; gap: 18px">${avatar(ME, 84)}<div style="flex: 1 1 0; display: flex">${igStat(12, '캔버스')}${igStat(34, '구독자', true)}${igStat(21, '구독')}</div></div>
<p style="margin: 12px 0 0; font-size: 14px; line-height: 1.45">${BIO}</p>
<span style="margin-top: 6px; display: flex; align-items: center; gap: 4px; font-size: 13px; color: ${MUTED}">${paint(myColor, 30, '', '')}오늘은 ${PAINT[myColor].name} · Nº 012<a href="#" style="margin-left: auto; display: flex; align-items: center; gap: 3px; color: ${INK}; font-weight: 600">${icon('lock', 11, 2)}반응 ${OWN.likes}</a></span>
<div style="margin-top: 12px; display: flex; gap: 6px">${pillBtn('프로필 편집', '; height: 34px; border-radius: 8px; font-size: 13.5px')}${pillBtn('공유', '; height: 34px; border-radius: 8px; font-size: 13.5px')}</div>
<nav aria-label="내 기록" class="esel-scroll" style="margin: 16px -16px 0; padding: 0 16px 14px; display: flex; gap: 12px; overflow-x: auto; scrollbar-width: none">${ring(colorRing, '색 달력')}${ring(photoRing('dana'), '친구')}${ring(pair, '트윈')}${ring(photoRing('elin'), '이번 주 주제')}${ring(photoRing('freya'), '전시')}</nav>
</section>
${iconTabs(0)}
${plainGrid(MINE, 2)}`);

// X2 핀터레스트 + Esel: centred face and serif name, two text buttons, then 캔버스 · 저장함 · 색 달력 as words, and
// saved canvases kept as named boards (a big print and two small ones), like collections.
const board = (title, items, n) => `<a href="#" style="display: flex; flex-direction: column; gap: 6px"><span style="display: flex; gap: 2px; height: 188px; border-radius: 16px; overflow: hidden"><span style="flex: 2 1 0">${savedShot(items[0], 116, 188)}</span><span style="flex: 1 1 0; display: flex; flex-direction: column; gap: 2px">${savedShot(items[1], 56, 93)}${savedShot(items[2], 56, 93)}</span></span><span style="padding: 0 4px; font-size: 15px; font-weight: 600">${title}</span><span style="padding: 0 4px; margin-top: -4px; font-size: 12px; color: ${MUTED}">캔버스 ${n}</span></a>`;
const wordTabs = (labels, active = 0) => `<nav aria-label="보관함" style="display: flex; justify-content: center; gap: 22px">${labels.map((l, i) => `<a href="#"${i === active ? ' aria-current="page"' : ''} style="height: 40px; display: flex; align-items: center; font-size: 15px; font-weight: 600; color: ${i === active ? INK : MUTED}; box-shadow: ${i === active ? `inset 0 -2px 0 ${INK}` : 'none'}">${l}</a>`).join('')}</nav>`;
files.ExploreRef2Pin = refPage('시안 X2 마이페이지 · 핀터레스트 결', `${topBarRef('')}
<section style="padding: 4px 20px 0; display: flex; flex-direction: column; align-items: center; text-align: center">
${avatar(ME, 96)}
<h1 style="margin: 12px 0 0; font-family: ${SERIF}; font-style: italic; font-weight: 400; font-size: 40px; line-height: 1">${ME}</h1>
<p style="margin: 6px 0 0; font-size: 14px; color: ${MUTED}">${BIO}</p>
<span style="margin-top: 6px; display: flex; align-items: center; gap: 4px; font-size: 13px">구독 21 · ${paint(myColor, 26, '', '')}오늘은 ${PAINT[myColor].name}</span>
<div style="margin-top: 14px; display: flex; gap: 8px">${pillBtn('공유', '; flex: 0 0 auto; padding: 0 18px; height: 40px; border-radius: 20px')}${pillBtn('프로필 편집', '; flex: 0 0 auto; padding: 0 18px; height: 40px; border-radius: 20px')}</div>
</section>
<div style="margin-top: 18px">${wordTabs(['캔버스', '저장함', '색 달력'], 1)}</div>
<section aria-label="저장함" style="padding: 16px 16px 0; display: grid; grid-template-columns: 1fr 1fr; gap: 18px 12px">
${board('코발트 모음', [SAVED[0], { key: 'ayo', py: 0.3 }, { key: 'riva', py: 0.2 }], 7)}
${board('이번 주 주제', [SAVED[1], SAVED[2], SAVED[4]], 5)}
${board('크림 & 버터', [SAVED[3], { key: 'maya', py: 0.35 }, { key: 'hana', py: 0.35 }], 6)}
${board('따라 입어 볼 것', [SAVED[5], { key: 'nia', py: 0.4 }, { key: 'sol', py: 0.35 }], 6)}
</section>`);

// X3 29CM 결: a fashion app's my page. Small English section labels, a large serif sign set left, a thin-ruled text
// menu with values on the right (no icons, no cards), then MY CANVASES. Black, white, one paint.
const menuRow = (ko, value = '', lock = false) => `<a href="#" style="height: 54px; display: flex; align-items: center; border-bottom: 1px solid ${LINE}; font-size: 15px"><span style="font-weight: 500">${ko}</span><span style="margin-left: auto; display: flex; align-items: center; gap: 6px; font-size: 14px; color: ${MUTED}">${lock ? icon('lock', 12, 1.8) : ''}${value}${right(16)}</span></a>`;
const label = (en, extra = '') => `<p style="margin: 0; font-family: ${MONO}; font-size: 10.5px; letter-spacing: 0.12em; color: ${MUTED}${extra}">${en}</p>`;
files.ExploreRef3Editorial = refPage('시안 X3 마이페이지 · 29CM 결', `${topBarRef(label('MY SKETCHBOOK'))}
<section style="padding: 10px 20px 0">
<div style="display: flex; align-items: flex-end; justify-content: space-between">
<h1 style="margin: 0; font-family: ${SERIF}; font-style: italic; font-weight: 400; font-size: 64px; line-height: 0.85; letter-spacing: -0.03em">${ME}</h1>
${avatar(ME, 56)}
</div>
<p style="margin: 14px 0 0; font-size: 14px; line-height: 1.5">${BIO}</p>
<div style="margin-top: 18px; display: flex; gap: 8px">${sqBtn('프로필 편집', true)}${sqBtn('공유')}</div>
${label('TODAY', '; margin-top: 30px')}
<a href="#" style="margin-top: 10px; padding-bottom: 14px; display: flex; align-items: center; gap: 12px; border-bottom: 1px solid ${BLACK}"><span style="flex-shrink: 0">${mineCell(MINE[0], 48, 64, false, 'span')}</span><span style="display: flex; flex-direction: column; gap: 3px"><span style="display: flex; align-items: center; gap: 4px; font-size: 15px; font-weight: 600">${paint(myColor, 30, '', '')}${PAINT[myColor].name} · Nº 012</span><span style="font-size: 13px; color: ${MUTED}">${MINE[0].cap}</span></span><span style="margin-left: auto; display: flex">${right(16)}</span></a>
${label('ONLY ME', '; margin-top: 26px')}
<div style="margin-top: 4px">${menuRow('내 캔버스의 반응', `좋아요 ${OWN.likes}`, true)}${menuRow('색 달력', weekDots)}${menuRow('저장함', '24')}</div>
${label('TOGETHER', '; margin-top: 26px')}
<div style="margin-top: 4px">${menuRow('친구', '8')}${menuRow('트윈', 'dana와 진행 중')}${menuRow('이번 주 주제', '같은 옷, 다른 코디')}${menuRow('전시', '이번 주')}</div>
<div style="margin-top: 30px; display: flex; align-items: baseline; justify-content: space-between">${label('MY CANVASES')}<span style="font-size: 13px; color: ${MUTED}">12</span></div>
</section>
<div style="margin-top: 10px">${plainGrid(MINE, 2)}</div>`);

// X4 인스타그램 + 29CM: Instagram's quick top block and grid, dressed like a fashion app: black square buttons, thin
// black rules, mono labels, and the things only I see as one ruled line instead of cards.
files.ExploreRef4Mix = refPage('시안 X4 마이페이지 · 인스타그램 + 29CM', `${topBarRef(label('MY SKETCHBOOK'))}
<section style="padding: 6px 16px 0">
<div style="display: flex; align-items: center; gap: 16px">${avatar(ME, 80)}<div style="flex: 1 1 0"><h1 style="margin: 0; font-family: ${SERIF}; font-style: italic; font-weight: 400; font-size: 38px; line-height: 1">${ME}</h1><p style="margin: 4px 0 0; font-size: 13.5px; line-height: 1.45; color: ${MUTED}">${BIO}</p></div></div>
<div style="margin-top: 16px; padding: 12px 0; display: flex; border-top: 1px solid ${BLACK}; border-bottom: 1px solid ${LINE}">${igStat(12, '캔버스')}${igStat(34, '구독자', true)}${igStat(21, '구독')}${igStat(OWN.likes, '이번 주 반응', true)}</div>
<div style="margin-top: 12px; display: flex; gap: 6px">${sqBtn('프로필 편집', true)}${sqBtn('공유')}</div>
<nav aria-label="내 기록" style="margin-top: 14px; display: flex; border-top: 1px solid ${LINE}; border-bottom: 1px solid ${LINE}">${[['색 달력', paint(myColor, 26, '', '')], ['저장함', '24'], ['친구', '8'], ['트윈', '1'], ['주제', '']].map(([l, v], i) => `<a href="#" style="flex: 1 1 0; height: 56px; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 2px; font-size: 12.5px; font-weight: 600; ${i ? `box-shadow: inset 1px 0 0 ${LINE}` : ''}"><span style="height: 18px; display: flex; align-items: center; font-size: 14px; font-weight: 700">${v || icon('right', 14, 2)}</span>${l}</a>`).join('')}</nav>
</section>
<div style="margin-top: 14px">${iconTabs(0)}</div>
${plainGrid(MINE, 2)}`);

// X5 W컨셉 결 + 핀터레스트: a quiet, centred header on warm paper, and the page organised as collections: my canvases
// by month, saved boards, this month's colors, each a titled editorial row you can open.
const shelfRow = (title, sub, items) => `<a href="#" style="display: block; padding: 18px 0; border-bottom: 1px solid ${LINE}"><span style="display: flex; align-items: baseline; justify-content: space-between"><span style="font-family: ${SERIF}; font-size: 22px">${title}</span><span style="display: flex; align-items: center; gap: 2px; font-size: 12.5px; color: ${MUTED}">${sub}${right(14)}</span></span><span style="margin-top: 10px; display: flex; gap: 4px">${items}</span></a>`;
files.ExploreRef5Shelf = refPage('시안 X5 마이페이지 · W컨셉 + 핀터레스트', `${topBarRef('')}
<section style="padding: 0 20px; display: flex; flex-direction: column; align-items: center; text-align: center">
${avatar(ME, 72)}
<h1 style="margin: 10px 0 0; font-family: ${SERIF}; font-style: italic; font-weight: 400; font-size: 44px; line-height: 1">${ME}</h1>
<p style="margin: 6px 0 0; font-size: 13.5px; color: ${MUTED}">${BIO}</p>
<div style="margin-top: 14px; width: 100%; display: flex; gap: 8px">${sqBtn('프로필 편집', true)}${sqBtn('공유')}</div>
<p style="margin: 14px 0 0; display: flex; align-items: center; gap: 4px; font-size: 12.5px; color: ${MUTED}">${icon('lock', 11, 1.8)}이번 주 좋아요 ${OWN.likes} · 한 줄 ${OWN.lines} · 저장 ${OWN.saves}</p>
</section>
<section style="padding: 6px 20px 0">
${shelfRow('9월의 캔버스', '5장', MINE.slice(0, 5).map((m) => `<span style="flex: 1 1 0; border-radius: 3px; overflow: hidden">${mineCell(m, 68, 90, false, 'span')}</span>`).join(''))}
${shelfRow('저장함', '보드 4 · 24장', SAVED.slice(0, 5).map((it) => `<span style="flex: 1 1 0; border-radius: 3px; overflow: hidden">${savedShot(it, 68, 90)}</span>`).join(''))}
${shelfRow('9월의 색', '색 달력', `<span style="display: flex; gap: 2px">${week.concat(week.slice(0, 3)).map((m) => paint(m.color, 34, '; transform: rotate(-90deg); margin: 8px -4px', '')).join('')}</span>`)}
${shelfRow('함께', '친구 8 · 트윈 1', `<span style="display: flex; align-items: center; gap: 10px">${avatars3(36)}<span style="font-size: 13px; color: ${MUTED}">dana와 트윈 진행 중</span></span>`)}
${shelfRow('이번 주 주제', '참여하기', `<span style="font-size: 14px">같은 옷, 다른 코디</span>`)}
</section>`, '#FAF9F6');

// ───────── X4 follow-ups (10-18): edit and share go into the ≡ menu, 주제 leaves, and 색 달력 · 저장함 · 친구 · 트윈
// stop sitting on the page. Three ways to put them away; in each, ≡ really opens the menu sheet on the canvas.
const menuLogic = (openByDefault) => `const menuOpen = this.state && this.state.menu !== undefined ? this.state.menu : ${openByDefault};
vals.menuDisplay = menuOpen ? 'block' : 'none';
vals.menuExpanded = menuOpen ? 'true' : 'false';
vals.toggleMenu = () => this.setState({ menu: !menuOpen });`;
const menuBar = `<header style="height: 44px; margin-top: 50px; padding: 0 8px 0 16px; display: flex; align-items: center">${label('MY SKETCHBOOK')}<button type="button" aria-label="메뉴" aria-expanded="{{menuExpanded}}" onClick="{{toggleMenu}}" style="margin-left: auto; width: 44px; height: 44px; display: flex; align-items: center; justify-content: center">${gear(24)}</button></header>`;
const sheetRow = (ic, text, value = '', strong = false) => `<a href="#" style="height: 54px; display: flex; align-items: center; gap: 14px; border-bottom: 1px solid ${LINE}; font-size: 15px; font-weight: ${strong ? 600 : 500}"><span style="width: 22px; display: flex; justify-content: center">${ic}</span>${text}<span style="margin-left: auto; display: flex; align-items: center; gap: 4px; font-size: 13.5px; font-weight: 500; color: ${MUTED}">${value}${right(15)}</span></a>`;
const editIco = svg('<path d="M4.5 19.5l3.8-.9L19 7.9a1.9 1.9 0 0 0 0-2.7l-.2-.2a1.9 1.9 0 0 0-2.7 0L5.4 15.7z"></path><path d="M14.5 6.5l3 3"></path>', 21);
const menuSheet = (rows) => `<div style="display: {{menuDisplay}}; position: absolute; inset: 0; z-index: 30">
<span aria-hidden="true" onClick="{{toggleMenu}}" style="position: absolute; inset: 0; background: rgba(20, 20, 18, 0.34)"></span>
<section role="dialog" aria-label="메뉴" style="position: absolute; left: 0; right: 0; bottom: 0; padding: 10px 20px 40px; border-radius: 24px 24px 0 0; background: #FFFFFF; box-shadow: 0 -10px 30px rgba(0, 0, 0, 0.12)">
<span aria-hidden="true" style="display: block; width: 36px; height: 5px; margin: 0 auto 10px; border-radius: 3px; background: #D6D6D2"></span>
${rows.join('\n')}
</section>
</div>`;
const baseRows = [sheetRow(editIco, '프로필 편집'), sheetRow(share(20), '내 스케치북 공유'), sheetRow(ico.sliders, '설정과 계정')];
const x4Head = (stats) => `<section style="padding: 6px 16px 0">
<div style="display: flex; align-items: center; gap: 16px">${avatar(ME, 80)}<div style="flex: 1 1 0"><h1 style="margin: 0; font-family: ${SERIF}; font-style: italic; font-weight: 400; font-size: 38px; line-height: 1">${ME}</h1><p style="margin: 4px 0 0; font-size: 13.5px; line-height: 1.45; color: ${MUTED}">${BIO}</p></div></div>
<div style="margin-top: 16px; padding: 12px 0; display: flex; border-top: 1px solid ${BLACK}; border-bottom: 1px solid ${LINE}">${stats}</div>
</section>`;
const tabsIcons = (items, active = 0) => `<nav aria-label="보관함" style="position: sticky; top: 0; z-index: 1; margin-top: 10px; display: flex; background: #FFFFFF; border-bottom: 1px solid ${LINE}">${items.map(([ic, l], i) => `<a href="#" aria-label="${l}"${i === active ? ' aria-current="page"' : ''} style="flex: 1 1 0; height: 44px; display: flex; align-items: center; justify-content: center; color: ${i === active ? INK : '#A3A49E'}; box-shadow: ${i === active ? `inset 0 -1.5px 0 ${INK}` : 'none'}">${ic}</a>`).join('')}</nav>`;
const x4Page = (title, inner, rows, openByDefault = false) => page(title, `<div style="${ROOT(`background: #FFFFFF; color: ${INK}`)}">
<div class="esel-scroll" style="position: absolute; inset: 0; overflow-y: auto; scrollbar-width: none">${menuBar}${inner}${plainGrid(MINE, 2)}<div style="height: 110px"></div></div>
${meCap}
${menuSheet(rows)}
</div>`, { logic: menuLogic(openByDefault) });

// X4-1 제자리로 나누기: each thing moves to where people already look for it. 저장함 and 색 달력 become tabs over the
// grid (as saved posts are on Instagram); 친구 joins the number row and opens friends with the twin inside; ≡ holds
// edit, share and settings.
files.ExploreRefY1Homes = x4Page('시안 X4-1 마이페이지 · 제자리로 나누기', `${x4Head(`${igStat(12, '캔버스')}${igStat(34, '구독자', true)}${igStat(21, '구독')}${igStat(8, '친구 · 트윈')}`)}
${tabsIcons([[ico.grid, '내 캔버스'], [ico.calendar, '색 달력'], [icon('bookmark', 20, 1.7), '저장함']])}`, baseRows);

// X4-2 햄버거 + 저장함 탭 (10-18: "take 저장함 out"): the page is me, my numbers and two worded tabs over the grid,
// 내 캔버스 and 저장함; the tabs really switch the grid. Everything else, edit and share included, lives in the ≡ sheet,
// today's color and my reactions at its top.
const SAVED_ALL = [...SAVED, { key: 'ayo', py: 0.3, color: 'cobalt' }, { key: 'hana', py: 0.35, color: 'butter' }, { key: 'nia', py: 0.4, color: 'terracotta' }];
const savedGrid = `<section aria-label="저장함" style="display: grid; grid-template-columns: 130px 129px 130px; gap: 2px">${SAVED_ALL.map((it) => `<a href="#" aria-label="${it.key}의 캔버스" style="display: block">${savedShot(it, 130, 173)}</a>`).join('')}</section>`;
const tabWord = (ic, text, hole) => `<button type="button" role="tab" aria-selected="{{${hole}On}}" onClick="{{show${hole}}}" style="flex: 1 1 0; height: 46px; display: flex; align-items: center; justify-content: center; gap: 6px; font-size: 14px; font-weight: 600; color: {{${hole}Fg}}; box-shadow: {{${hole}Line}}">${ic}${text}</button>`;
const savedTabLogic = `const saved = !!(this.state && this.state.tab === 'saved');
vals.mineGrid = saved ? 'none' : 'block';
vals.savedGrid = saved ? 'block' : 'none';
vals.MineOn = saved ? 'false' : 'true';
vals.SavedOn = saved ? 'true' : 'false';
vals.MineFg = saved ? '#A3A49E' : '${INK}';
vals.SavedFg = saved ? '${INK}' : '#A3A49E';
vals.MineLine = saved ? 'none' : 'inset 0 -1.5px 0 ${INK}';
vals.SavedLine = saved ? 'inset 0 -1.5px 0 ${INK}' : 'none';
vals.showMine = () => this.setState({ tab: 'mine' });
vals.showSaved = () => this.setState({ tab: 'saved' });`;
files.ExploreRefY2Drawer = page('시안 X4-2 마이페이지 · 햄버거 + 저장함 탭', `<div style="${ROOT(`background: #FFFFFF; color: ${INK}`)}">
<div class="esel-scroll" style="position: absolute; inset: 0; overflow-y: auto; scrollbar-width: none">${menuBar}${x4Head(`${igStat(12, '캔버스')}${igStat(34, '구독자', true)}${igStat(21, '구독')}`)}
<nav role="tablist" aria-label="보관함" style="position: sticky; top: 0; z-index: 1; margin-top: 10px; display: flex; background: #FFFFFF; border-bottom: 1px solid ${LINE}">${tabWord(ico.grid, '내 캔버스', 'Mine')}${tabWord(icon('bookmark', 19, 1.7), '저장함', 'Saved')}</nav>
<div style="display: {{mineGrid}}">${plainGrid(MINE, 2)}</div>
<div style="display: {{savedGrid}}">${savedGrid}</div>
<div style="height: 110px"></div></div>
${meCap}
${menuSheet([
  `<a href="#" style="margin-bottom: 6px; padding: 12px 14px; border-radius: 14px; display: flex; align-items: center; gap: 10px; background: #F6F5F1">${paint(myColor, 44, '', '')}<span style="display: flex; flex-direction: column"><span style="font-size: 12px; color: ${MUTED}">오늘은 ${PAINT[myColor].name}</span><span style="font-size: 15px; font-weight: 600">Nº 012 올렸어요</span></span><span style="margin-left: auto; display: flex; align-items: center; gap: 4px; font-size: 13px; font-weight: 600">${icon('lock', 12, 1.8)}반응 ${OWN.likes}</span></a>`,
  sheetRow(ico.calendar, '색 달력', weekDots), sheetRow(ico.friends, '친구', '8'), sheetRow(ico.twin, '트윈', 'dana와 진행 중'),
  ...baseRows,
])}
</div>`, { logic: `${menuLogic(false)}\n${savedTabLogic}` });

// X4-3 숫자 줄이 입구: the number row is the door. 친구 and 저장 are numbers you tap; today's paint beside my name opens
// the color calendar; the twin shows as a small tag under my line only while one is running. ≡ holds edit, share and settings.
files.ExploreRefY3Numbers = x4Page('시안 X4-3 마이페이지 · 숫자 줄이 입구', `<section style="padding: 6px 16px 0">
<div style="display: flex; align-items: center; gap: 16px">${avatar(ME, 80)}<div style="flex: 1 1 0">
<div style="display: flex; align-items: center; gap: 8px"><h1 style="margin: 0; font-family: ${SERIF}; font-style: italic; font-weight: 400; font-size: 38px; line-height: 1">${ME}</h1><a href="#" aria-label="색 달력 · 오늘은 ${PAINT[myColor].name}" style="height: 30px; padding: 0 8px 0 2px; border-radius: 15px; display: flex; align-items: center; gap: 2px; box-shadow: inset 0 0 0 1px ${LINE}; font-size: 11.5px; font-weight: 600">${paint(myColor, 30, '', '')}${right(12)}</a></div>
<p style="margin: 4px 0 0; font-size: 13.5px; line-height: 1.45; color: ${MUTED}">${BIO}</p>
<a href="#" style="margin-top: 6px; display: inline-flex; align-items: center; gap: 4px; font-size: 12px; font-weight: 600">${ico.twin.replace('width="21" height="21"', 'width="15" height="15"')}dana와 트윈 진행 중</a>
</div></div>
<div style="margin-top: 16px; padding: 12px 0; display: flex; border-top: 1px solid ${BLACK}; border-bottom: 1px solid ${LINE}">${igStat(12, '캔버스')}${igStat(34, '구독자', true)}${igStat(8, '친구')}${igStat(24, '저장')}</div>
</section>
${tabsIcons([[ico.grid, '내 캔버스']])}`, baseRows);

// ───────── Adopted (10-18): the cover page boards C4, C8 and M1 are built here from the chosen layouts, so the
// exploration page and the canvas share one source. gen-cover2.mjs writes them under their Cover* names.
export const adopted = {};
// C4 팔레트 · 추천: R5-4 with the fan closed (tap the round button to open it on the canvas).
adopted.CoverStand = r54Page('표지 SNS 4 팔레트', false);
// C8 팔레트 · 카멜 방, before I post: a short head names the room; the newest three, the rest blurred, and the round
// button shows the room's paint (P01).
const roomFab = `<span class="esel-glass" style="position: absolute; right: ${393 - FAB.cx + FAB.d / 2 + 8}px; top: ${FAB.cy - 15}px; height: 30px; padding: 0 12px; border-radius: 15px; display: flex; align-items: center; font-size: 13px; font-weight: 600">${PAINT[myColor].name}</span>
<button type="button" aria-label="볼 것 고르기 · 지금 ${PAINT[myColor].name}" class="esel-glass" style="position: absolute; left: ${FAB.cx - FAB.d / 2}px; top: ${FAB.cy - FAB.d / 2}px; width: ${FAB.d}px; height: ${FAB.d}px; border-radius: 50%; display: flex; align-items: center; justify-content: center">${paint(myColor, 46, '', '')}</button>`;
const RH = 54 + 52;
adopted.CoverStandLocked = page('표지 SNS 8 팔레트 · 카멜 방 · 올리기 전', `<div style="${ROOT(`background: ${PAPER}; color: ${INK}`)}">
<header style="position: absolute; left: 0; right: 0; top: 54px; height: 52px; display: flex; align-items: center; gap: 6px; padding: 0 18px 0 12px">${paint(myColor, 48, '', '')}<h1 style="margin: 0; font-family: ${SERIF}; font-size: 30px; font-weight: 400; line-height: 1">${PAINT[myColor].name}</h1><span style="margin-left: 4px; font-size: 13px; color: ${MUTED}">같은 색 64명 · 먼저 3장</span><span style="margin-left: auto; display: flex; color: ${MUTED}">${icon('lock', 15, 1.8)}</span></header>
<div style="position: absolute; left: 0; right: 0; top: ${RH}px">${LOCK_OPEN.map((it, i) => clean(it, G.x[i], 0, G.cols[i], G.cell)).join('\n')}</div>
<section aria-label="카멜 사진 61장 · 오늘의 캔버스를 올리면 펼쳐져요" style="position: absolute; left: 0; right: 0; top: ${RH + G.cell + G.gap}px; bottom: 0; overflow: hidden">
<div aria-hidden="true" style="position: absolute; left: 0; right: 0; top: 0; filter: blur(1.5px)">${blockG(G, [0, 1, 2, 3, 4], 0, true, camelBlur(0))}${blockG(G, [5, 6, 7, 8, 9], G.block, false, camelBlur(1))}</div>
<div style="position: absolute; left: 50%; top: 58px; transform: translateX(-50%); width: 300px; padding: 18px 18px 16px; box-sizing: border-box; border-radius: 22px; display: flex; flex-direction: column; align-items: center; gap: 4px; text-align: center; background: rgba(249, 249, 251, 0.95); box-shadow: inset 0 0 0 1px ${HAIR}, 0 10px 28px rgba(0, 0, 0, 0.1)">
${icon('lock', 20, 1.8)}
<p style="margin: 2px 0 0; font-family: ${SERIF}; font-size: 22px; line-height: 1.2">올리면 함께 펼쳐집니다</p>
<p style="margin: 0; font-size: 13px; line-height: 1.45; color: ${MUTED}">카멜 61장이 더 있어요.<br>자정이 지나면 모두 펼쳐져요.</p>
<a href="CoverMake.dc.html" style="margin-top: 10px; height: 48px; padding: 0 22px; border-radius: 24px; display: flex; align-items: center; gap: 6px; background: ${INK}; color: ${PAPER}; font-size: 15px; font-weight: 600">${icon('plus', 18, 2)}<span>오늘의 캔버스 만들기</span></a>
</div>
</section>
${roomFab}
${capsule({ color: myColor, active: 'palette' })}
</div>`);
// M1 내 스케치북 (my page): X4-1 with worded tabs (내 캔버스 · 색 달력 · 저장함); ≡ opens edit, share and settings.
const wordedTabs = `<nav aria-label="내 보관함" style="position: sticky; top: 0; z-index: 1; margin-top: 10px; display: flex; background: #FFFFFF; border-bottom: 1px solid ${LINE}">${[[ico.grid, '내 캔버스'], [ico.calendar, '색 달력'], [icon('bookmark', 19, 1.7), '저장함']].map(([ic, l], i) => `<a href="#"${i === 0 ? ' aria-current="page"' : ''} style="flex: 1 1 0; height: 46px; display: flex; align-items: center; justify-content: center; gap: 6px; font-size: 14px; font-weight: 600; color: ${i === 0 ? INK : '#A3A49E'}; box-shadow: ${i === 0 ? `inset 0 -1.5px 0 ${INK}` : 'none'}">${ic}${l}</a>`).join('')}</nav>`;
adopted.CoverMe = x4Page('표지 SNS 9 내 스케치북', `${x4Head(`${igStat(12, '캔버스')}${igStat(34, '구독자', true)}${igStat(21, '구독')}${igStat(8, '친구 · 트윈')}`)}
${wordedTabs}`, baseRows);

for (const [name, html] of Object.entries(files)) fs.writeFileSync(path.join(OUT, `${name}.dc.html`), html);

if (process.argv.includes('--index')) {
  const f = path.join(OUT, 'canvas.json');
  const c = JSON.parse(fs.readFileSync(f, 'utf8'));
  // After the 10-18 choice (palette R5-4, my page X4-1) the exploration page moves next to the other archives.
  c.pages = c.pages.filter((p) => p.id !== 'explore');
  c.pages.splice(c.pages.findIndex((p) => p.id === 'feeds'), 0, { id: 'explore', name: '보관 · 팔레트 · 마이페이지 시안' });
  c.boards['CoverMe.dc.html'] = { x: 946, y: 1240, w: 393, h: 852, page: 'cover', title: 'M1 내 스케치북 · 마이페이지', is_interactive: true, radius: 28 };
  if (!c.order.includes('CoverMe.dc.html')) c.order.splice(c.order.indexOf('CoverScroll.dc.html') + 1, 0, 'CoverMe.dc.html');
  c.boards['CoverStand.dc.html'].title = 'C4 팔레트 · 추천 (둥근 버튼을 눌러 부채 열기)';
  c.boards['CoverStandLocked.dc.html'].title = 'C8 팔레트 · 카멜 방 · 올리기 전';
  c.notes['cover-scroll'].text = '스크롤 · 색 방 · 마이페이지 — C7은 Play로 열어 내리고 다시 올려 보기, M1은 ≡를 눌러 메뉴 열기';
  // Boards dropped from this page (rejected rounds) leave the canvas too.
  for (const file of Object.keys(c.boards)) if (c.boards[file].page === 'explore' && !files[file.replace('.dc.html', '')]) delete c.boards[file];
  c.order = c.order.filter((file) => !file.startsWith('Explore') || files[file.replace('.dc.html', '')]);
  delete c.notes['explore-palette'];
  const titles = {
    ExploreRef1Insta: 'X1 인스타그램 결', ExploreRef2Pin: 'X2 핀터레스트 결', ExploreRef3Editorial: 'X3 29CM 결', ExploreRef4Mix: 'X4 인스타그램 + 29CM', ExploreRef5Shelf: 'X5 W컨셉 + 핀터레스트', ExploreRefY1Homes: 'X4-1 제자리로 나누기', ExploreRefY2Drawer: 'X4-2 햄버거 + 저장함 탭', ExploreRefY3Numbers: 'X4-3 숫자 줄이 입구',
    ExploreMy1Profile: 'V1 정돈된 프로필', ExploreMy2Board: 'V2 표지와 대시보드',
    ExploreMy6CoverTiles: 'W1 표지 썸네일 + 카드 3칸', ExploreMy7Swipe: 'W2 가로로 넘기는 카드', ExploreMy8Stats: 'W3 숫자 줄 + 2×2', ExploreMy9Today: 'W4 오늘 큰 카드', ExploreMy10Month: 'W5 색 달력 크게',
    ExploreMy11Segment: 'W6 세그먼트 대시보드', ExploreMy12Ink: 'W7 먹색 카드', ExploreMy13Accent: 'W8 오늘의 색으로 물든 페이지', ExploreMy14Asym: 'W9 비대칭 대시보드', ExploreMy15Center: 'W10 가운데 정렬',
    ExplorePalette3GlassBox: 'R1 글라스 + 물감 상자', ExplorePalette3GlassRail: 'R2 글라스 물감 레일', ExplorePalette3Tray: 'R3 엄지 아래 물감 트레이', ExplorePalette3RailRoom: 'R4 레일 · 카멜 방(올리기 전)', ExplorePalette3Fan: 'R5 손안의 팔레트', ExplorePalette3FanWords: 'R5-1 글자 토글 · 내리면 숨김', ExplorePalette3FanAll: 'R5-2 추천·구독도 부채 안에', ExplorePalette3FanThumb: 'R5-3 엄지 옆 토글', ExplorePalette3FanChoose: 'R5-4 구독도 고르는 것 중 하나',
    ExplorePalette2Glass: 'Q1 글라스 바', ExplorePalette2Box: 'Q3 물감 상자', ExplorePalette2Rail: 'Q4 색 레일',
  };
  // Reference-based my pages first, then V1, V2 and W1–W10 (six to a row), then the palette rounds.
  const place = (list, row0, perRow) => list.forEach((name, i) => {
    const file = `${name}.dc.html`;
    c.boards[file] = { x: (i % perRow) * 473, y: (row0 + Math.floor(i / perRow)) * 1240, w: 393, h: 852, page: 'explore', title: titles[name], is_interactive: true, radius: 28 };
    if (!c.order.includes(file)) c.order.push(file);
  });
  const names = Object.keys(files);
  place(names.filter((n) => n.startsWith('ExploreRef')), 0, 9);
  place(names.filter((n) => n.startsWith('ExploreMy')), 1, 6);
  place(names.filter((n) => n.startsWith('ExplorePalette3')), 3, 9);
  place(names.filter((n) => n.startsWith('ExplorePalette2')), 4, 9);
  for (const k of ['explore-sketch', 'explore-sketch2', 'explore-sketch3']) delete c.notes[k];
  c.notes['explore-ref'] = { x: 0, y: -260, text: '마이페이지 참고 앱 시안 5 + X4 변형 3 — 편집·공유는 ≡ 안으로, 주제 뺌, 색 달력·저장함·친구·트윈 숨기는 방법 셋 (≡를 눌러 메뉴 열기)', kind: 'title1', maxW: 4177, page: 'explore' };
  c.notes['explore-my'] = { x: 0, y: 980, text: '마이페이지 — V1·V2 남김 + 새 시안 10 (W1~W10). 남에게 보이는 나 · 나만 보는 것 · 함께 · 보관함. 저장함은 새 기능 제안', kind: 'title1', maxW: 2758, page: 'explore' };
  c.notes['explore-palette3'] = { x: 0, y: 3460, text: '팔레트 3차 시안 (R5-4로 결정) — Q1·Q3·Q4에서 이어서: 사진은 화면 가득, 위는 비우고, 물감은 손 닿는 곳에. R5-1~4는 Play로 열어 둥근 버튼·추천/구독을 눌러 보기, R5-1은 내려 보기', kind: 'title1', maxW: 4177, page: 'explore' };
  c.notes['explore-palette2'] = { x: 0, y: 4700, text: '남긴 2차 시안 — Q1 글라스 바 · Q3 물감 상자 · Q4 색 레일 (칸은 사진만, 사인 뒤로를 고른 사람만 사인)', kind: 'title1', maxW: 1339, page: 'explore' };
  c.launch = { view: 'canvas', page: 'cover' };
  fs.writeFileSync(f, JSON.stringify(c, null, 2) + '\n');
}
console.log('ok', Object.entries(files).map(([n, h]) => `${n}:${h.length}`).join(' '));
