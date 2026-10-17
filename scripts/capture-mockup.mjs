// Captures every screen state of the app mockup into docs/dev/screens (JPEG, 393×852 at 2×), so developers and other AIs
// can compare their screens without opening the private mockup link. Needs Google Chrome (set CHROME if it is not at the macOS path).
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const manifest = JSON.parse(fs.readFileSync(path.join(root, 'harness.json'), 'utf8'));
const dev = JSON.parse(fs.readFileSync(path.join(root, 'docs/dev/features.json'), 'utf8'));
const mockup = path.join(root, manifest.appMockup.root);
const chrome = process.env.CHROME || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';

execFileSync(process.execPath, [path.join(mockup, 'build.mjs'), '--local'], { stdio: 'ignore' });
const page = fs.readFileSync(path.join(mockup, 'dist/_local.html'), 'utf8');

// Setup code runs after the mockup script, with its globals (S, stack, render, openLogin, openShare, shareApps, ME).
const IN = "S.auth='in';";
const PUB = `${IN}S.published=true;S.me.issues=12;`;
const at = (...names) => `stack=[${['feed', ...names].map((n) => { const [name, arg] = n.split(':'); return arg ? `{name:'${name}',arg:'${arg}'}` : `{name:'${name}'}`; }).join(',')}];render();`;
const scroll = (from, to, step) => `(()=>{const sc=document.querySelector('#scroller');const go=(y)=>{sc.scrollTop=y;sc.dispatchEvent(new Event('scroll'));};const st=${step}*Math.sign(${to}-${from});for(let y=${from};${step}>0&&(st>0?y<=${to}:y>=${to});y+=st)go(y);})();`;
const twin = (step) => `${IN}S.twin.step='${step}';`;
const SETUP = {
  CH1: IN + at('challenges'),
  J1: '',
  J1b: scroll(0, 1300, 20),
  J2: 'openLogin();',
  J3: "stack=[{name:'intro'},{name:'join-color'}];render();",
  J4: "stack=[{name:'intro'},{name:'join-shoot'}];render();",
  J5: "stack=[{name:'intro'},{name:'join-name'}];render();",
  J6: "stack=[{name:'intro'},{name:'join-face'}];render();",
  J7: "stack=[{name:'intro'},{name:'join-done'}];render();",
  C1: IN + at(),
  C2: `${IN}S.feedTab='subs';` + at(),
  C3: IN + at('spread:dana'),
  C4: IN + at('stand'),
  C5: IN + at('shelf:dana'),
  C5b: `${IN}S.shelfView.dana='spines';` + at('shelf:dana'),
  C6: IN + at('make'),
  C7: IN + at() + scroll(0, 1500, 20) + scroll(1490, 1100, 10),
  C8: IN + at('same'),
  C8b: PUB + at('same'),
  M1: PUB + at('me'),
  A4: PUB + at('me', 'reactions'),
  R1: PUB + at('me', 'record'),
  R2: PUB + at('me', 'record', 'day:6'),
  R3: PUB + at('me', 'record', 'restore:3'),
  R4: `${PUB}S.record[3]={c:'lilac',k:'restored'};S.credits=1;` + at('me', 'record', 'restored:3'),
  R5: `${PUB}S.record[3]={c:'lilac',k:'restored'};S.credits=1;` + at('me', 'record'),
  F1: IN + at('me', 'friends'),
  F2: IN + at('me', 'friends', 'friend:zuri'),
  F3: `${IN}S.requests=[];S.friends.push('zuri');` + at('me', 'friends', 'friend-added:zuri'),
  T1: IN + at('me', 'twin'),
  T2: twin('invited') + at('me', 'twin', 'twin-invite'),
  T3: twin('paired') + at('me', 'twin', 'twin-color'),
  T4: twin('ready') + at('me', 'twin', 'twin-ready'),
  T5: twin('posted') + at('me', 'twin', 'twin-wait'),
  T6: twin('both') + at('me', 'twin', 'twin-reveal'),
  T7: twin('both') + at('me', 'twin', 'twin-vis'),
  T8: twin('consent') + at('me', 'twin', 'twin-consent'),
  T9: twin('joint') + at('me', 'twin', 'twin-joint'),
  T10: twin('published') + at('me', 'twin', 'twin-done'),
  T8private: twin('private') + at('me', 'twin', 'twin-done'),
  T8solo: twin('solo') + at('me', 'twin', 'twin-done'),
  S1: IN + at('me', 'settings'),
  S2: IN + at('me', 'settings', 'profile'),
  S3: IN + at('me', 'settings', 'notifications'),
  S3off: `${IN}S.notif.on=false;` + at('me', 'settings', 'notifications'),
  S4: IN + at('me', 'settings', 'account'),
  S5: IN + at('me', 'settings', 'account', 'logout'),
  S5done: "stack=[{name:'goodbye',arg:'out'}];render();",
  S6: IN + at('me', 'settings', 'account', 'delete'),
  S6confirm: IN + at('me', 'settings', 'account', 'delete', 'delete-final'),
  S6done: "stack=[{name:'goodbye',arg:'deleted'}];render();",
  A1: PUB + at('me') + 'openShare(ME);',
  A3: PUB + at('me') + 'openShare(ME);shareApps();',
  A5: IN + at('spread:dana') + "openShare('dana');",
  A7: twin('published') + at('me', 'twin', 'twin-done') + "openShare('twin');",
};
// Simulate a phone's safe areas so the captures match a real device rather than a bare browser window.
// Headless Chrome keeps a wider layout viewport than the 393px window, so the device size is pinned here.
const SAFE = '<style>:root{padding-top:47px!important;padding-bottom:34px!important}#stage{justify-content:flex-start!important}#device{zoom:1!important;width:393px!important;height:771px!important}</style>';
const out = path.join(root, 'docs/dev/screens');
fs.mkdirSync(out, { recursive: true });
const missing = dev.screens.filter((s) => !(s.id in SETUP)).map((s) => s.id);
if (missing.length) throw new Error(`캡처 방법이 없는 화면: ${missing.join(', ')}`);
const selected = process.env.ESEL_CAPTURE_SCREENS?.split(',');
const screens = selected ? dev.screens.filter((s) => selected.includes(s.id)) : dev.screens;
for (const s of screens) {
  const file = path.join(mockup, 'dist', `_cap-${s.id}.html`);
  fs.writeFileSync(file, page.replace('</head>', `${SAFE}</head>`).replace('</body></html>', `<script>${SETUP[s.id]}</script></body></html>`));
  execFileSync(chrome, ['--headless=new', '--disable-gpu', '--allow-file-access-from-files', '--hide-scrollbars', '--force-device-scale-factor=2',
    '--window-size=393,852', '--virtual-time-budget=5000', `--screenshot=${path.join(root, s.image)}`, pathToFileURL(file).href], { stdio: 'ignore' });
  fs.rmSync(file);
}
console.log(`목업 화면 캡처 ${screens.length}장: docs/dev/screens`);
