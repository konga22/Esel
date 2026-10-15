// Builds the tappable app mockup into dist/: one index.html (shell + data + app script) and the photos and paint it uses.
// People, face boxes and the twelve colours come from the canvas generator so the mockup never drifts from the boards.
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '../../../..');
const manifest = JSON.parse(fs.readFileSync(path.join(root, 'harness.json'), 'utf8'));
const design = manifest.activeDesign;
const { PAINT, PEOPLE, COLOR_ORDER, ME } = await import(pathToFileURL(path.join(root, design.library)).href);
const dist = path.join(here, 'dist');

const people = Object.fromEntries(Object.entries(PEOPLE).map(([k, p]) => [k, { r: p.r, fx: p.fx, fy: p.fy, fw: p.fw, color: p.color, time: p.time, cap: p.cap, alt: p.alt }]));
const paint = Object.fromEntries(Object.entries(PAINT).map(([k, c]) => [k, { name: c.name, en: c.en, hex: c.hex }]));
const data = { people, paint, order: COLOR_ORDER, me: ME };

const shell = fs.readFileSync(path.join(here, 'src/shell.html'), 'utf8');
const app = fs.readFileSync(path.join(here, 'src/app.js'), 'utf8');
if (!shell.includes('/*APP*/')) throw new Error('shell.html에 /*APP*/ 자리가 없어요');
fs.rmSync(dist, { recursive: true, force: true });
fs.mkdirSync(path.join(dist, 'img/people'), { recursive: true });
fs.mkdirSync(path.join(dist, 'img/paint'), { recursive: true });
fs.writeFileSync(path.join(dist, 'index.html'), shell.replace('/*APP*/', () => `window.ESEL_DATA = ${JSON.stringify(data)};\n${app}`));

// Photos are copied as they are (800px JPEG). Paint is shown at most ~120px wide, so it is shrunk to 480px when macOS sips is available.
const hasSips = (() => { try { execFileSync('sips', ['--help'], { stdio: 'ignore' }); return true; } catch { return false; } })();
for (const key of Object.keys(PEOPLE)) fs.copyFileSync(path.join(root, manifest.demoPeople[key]), path.join(dist, 'img/people', `${key}.jpg`));
for (const key of Object.keys(PAINT)) {
  const from = path.join(root, design.paint, `esel-paint-${key}.png`);
  const to = path.join(dist, 'img/paint', `${key}.png`);
  if (hasSips) execFileSync('sips', ['-Z', '480', from, '--out', to], { stdio: 'ignore' });
  else fs.copyFileSync(from, to);
}
// --local also writes dist/_local.html, wrapped like the artifact host wraps the page, for checking in a browser.
if (process.argv.includes('--local')) {
  const head = '<!doctype html><html lang="ko"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover"><style>:root{color-scheme:light;padding-top:env(safe-area-inset-top,0px);padding-bottom:env(safe-area-inset-bottom,0px)}body{margin:0;font:14px system-ui}img{max-width:100%}[hidden]{display:none!important}</style></head><body>';
  fs.writeFileSync(path.join(dist, '_local.html'), `${head}${fs.readFileSync(path.join(dist, 'index.html'), 'utf8')}</body></html>`);
}
const size = (dir) => fs.readdirSync(dir, { recursive: true }).reduce((sum, f) => { const p = path.join(dir, f); return sum + (fs.statSync(p).isFile() ? fs.statSync(p).size : 0); }, 0);
console.log(`앱 목업 빌드: dist/index.html, 사진 ${Object.keys(PEOPLE).length}장, 물감 ${Object.keys(PAINT).length}개, 합계 ${(size(dist) / 1024 / 1024).toFixed(1)}MB${hasSips ? '' : ' (sips 없음: 물감 원본 크기)'}`);
