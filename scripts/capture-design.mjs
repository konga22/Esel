// Captures the canvas boards and screens into docs/design as PNG, using local photos and paint instead of canvas blobs.
// Needs Google Chrome. Set CHROME to its binary if it is not in the default macOS location.
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const manifest = JSON.parse(fs.readFileSync(path.join(root, 'harness.json'), 'utf8'));
const design = manifest.activeDesign;
const { PAINT, PEOPLE } = await import(pathToFileURL(path.join(root, design.library)).href);
const index = JSON.parse(fs.readFileSync(path.join(root, design.output, 'canvas.json'), 'utf8'));
const chrome = process.env.CHROME || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const out = path.join(root, 'docs/design');
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'esel-capture-'));

// Canvas blob id → local file.
const local = {};
for (const [key, person] of Object.entries(PEOPLE)) local[person.id] = path.join(root, manifest.demoPeople[key]);
for (const [key, color] of Object.entries(PAINT)) local[color.id] = path.join(root, design.paint, `esel-paint-${key}.png`);

// Turns a .dc.html artboard into a plain page: holes get the first renderVals(), `scroll` replays scroll positions, `css` is appended.
function plain(name, { state = {}, scroll = null, css = '' } = {}) {
  let html = fs.readFileSync(path.join(root, design.output, `${name}.dc.html`), 'utf8');
  const logic = html.match(/<script type="text\/x-dc"[^>]*>([\s\S]*?)<\/script>/)[1];
  const Component = new Function('DCLogic', `${logic}\nreturn Component;`)(class { constructor() { this.state = {}; this.props = {}; } setState() {} });
  const component = new Component();
  component.state = state;
  const vals = component.renderVals();
  html = html.replace(/ref="\{\{(\w+)\}\}"/g, 'data-ref="$1"')
    .replace('<script src="./support.js"></script>', '')
    .replace(/\/_blob\/([0-9a-f]{32})/g, (match, id) => {
      if (!local[id]) throw new Error(`${name}: 로컬 파일이 없는 이미지 ${id}`);
      return pathToFileURL(local[id]).href;
    })
    .replace(/<script type="text\/x-dc"[\s\S]*?<\/script>/, '')
    .replace(/<\/?x-dc>|<\/?helmet>/g, '')
    .replace(/\{\{(\w+)\}\}/g, (match, key) => (typeof vals[key] === 'string' || typeof vals[key] === 'number' ? String(vals[key]) : ''));
  if (css) html = html.replace('</body>', `<style>${css}</style></body>`);
  if (scroll) {
    html = html.replace('</body>', `<script>class DCLogic{constructor(){this.state={};this.props={}}setState(x){Object.assign(this.state,x)}}${logic}
const c=new Component();const v=c.renderVals();document.querySelectorAll('[data-ref]').forEach(el=>v[el.dataset.ref]&&v[el.dataset.ref](el));
const sc=document.querySelector('.esel-scroll');for(const y of ${JSON.stringify(scroll)}){sc.scrollTop=y;v.onScroll({currentTarget:sc});}</script></body>`);
  }
  const file = path.join(tmp, `${name}-${Object.keys(state).join('-') || 'base'}-${scroll ? scroll.length : 0}.html`);
  fs.writeFileSync(file, html);
  return file;
}

function shoot(file, target, width, height, scale) {
  fs.mkdirSync(path.dirname(target), { recursive: true });
  execFileSync(chrome, ['--headless=new', '--disable-gpu', '--allow-file-access-from-files', '--hide-scrollbars', `--force-device-scale-factor=${scale}`,
    `--window-size=${width},${height}`, '--virtual-time-budget=5000', `--screenshot=${target}`, pathToFileURL(file).href], { stdio: 'ignore' });
}

const steps = (from, to, step) => Array.from({ length: Math.floor(Math.abs(to - from) / step) + 1 }, (_, i) => from + Math.sign(to - from) * i * step);
// The motion samples loop on the canvas; a still shows each one paused where its effect is clearest (seconds into its loop).
const MOTION_FRAME = { melt: 1, meltpill: 1, show: 1.5, press: 0.84, login: 2.4, spread: 2.7, spreadtext: 2.7, squeeze: 2.4, stamp: 2.4, roll: 2.4, zoom: 2.7, chip: 2.4, tile: 2.7, pull: 1.28, heart: 1.6 };
const motionStill = `[class^="m-"],[class*=" m-"]{animation-play-state:paused!important}\n${Object.entries(MOTION_FRAME).map(([k, t]) => `.m-${k}{animation-delay:-${t}s!important}`).join('\n')}`;
const boards = [['BoardMood', '00-mood'], ['BoardTokens', '01-tokens'], ['BoardComponents', '02-components'], ['BoardMotion', '04-motion', { css: motionStill }]];
const screens = [
  ['CoverFeed', 'c1-feed'], ['CoverNext', 'c2-next'], ['CoverSpread', 'c3-spread'], ['CoverStand', 'c4-stand'],
  ['CoverShelf', 'c5-shelf'], ['CoverShelf', 'c5-shelf-spines', { state: { view: 'spines' } }],
  ['CoverMake', 'c6-make'], ['CoverMake', 'c6-make-paint', { state: { face: 'paint' } }], ['CoverMake', 'c6-make-behind', { state: { face: 'zoom' } }], ['CoverMake', 'c6-make-neck', { state: { face: 'neck', white: false } }],
  ['CoverScroll', 'c7-scroll'], ['CoverScroll', 'c7-scroll-inner', { scroll: steps(0, 1000, 20) }], ['CoverScroll', 'c7-scroll-melting', { scroll: [...steps(0, 1500, 20), ...steps(1490, 180, 10)] }],
  ['CoverStandLocked', 'c8-same-color-locked'],
  ['JoinScroll', 'j1-logged-out'], ['JoinScroll', 'j1-login-bar', { scroll: steps(0, 1300, 20) }], ['JoinLogin', 'j2-login'], ['JoinColor', 'j3-color'],
  ['JoinShoot', 'j4-shoot'], ['JoinName', 'j5-name'], ['JoinFace', 'j6-face'], ['JoinDone', 'j7-first-issue'],
];
for (const [name, target, opts] of boards) shoot(plain(name, opts), path.join(out, 'boards', `${target}.png`), 1440, index.boards[`${name}.dc.html`].h, 2);
// Screens are mostly photographs, so JPEG keeps them light; boards are mostly text and stay PNG.
for (const [name, target, opts] of screens) shoot(plain(name, opts), path.join(out, 'screens', `${target}.jpg`), 393, 852, 2);
fs.rmSync(tmp, { recursive: true, force: true });
console.log(`디자인 캡처 ${boards.length + screens.length}장: docs/design/boards, docs/design/screens`);
