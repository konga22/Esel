import assert from 'node:assert/strict';
import { readFile, access, readdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { checkDev } from './dev-harness.mjs';

// A portable consistency check, not an aesthetic score or a browser test.
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const manifest = JSON.parse(await readFile(path.join(root, 'harness.json'), 'utf8'));
assert.equal(manifest.schemaVersion, 2);
assert.equal(manifest.project, 'Esel');
const resolveLocal = value => {
  assert.equal(typeof value, 'string');
  assert(!path.isAbsolute(value), `저장소 상대 경로가 필요합니다: ${value}`);
  const target = path.resolve(root, value);
  assert(target.startsWith(root + path.sep), `저장소 밖 경로: ${value}`);
  return target;
};

const design = manifest.activeDesign;
const rules = manifest.ruleReference;
const screenFiles = design.pages.flatMap(page => page.files.map(file => `${design.output}/${file}`));
const paintFiles = Object.keys(manifest.colors).map(color => `${design.paint}/esel-paint-${color}.png`);
const files = [...manifest.entrypoints, ...manifest.keyAssets, design.readme, design.library, ...screenFiles, ...paintFiles,
  ...Object.values(manifest.demoPeople), rules.source, rules.stateTests, rules.headerTests,
  manifest.nativeApp.routes, manifest.nativeApp.source, ...manifest.evidence,
  ...(manifest.appMockup ? [manifest.appMockup.readme, manifest.appMockup.build, ...manifest.appMockup.source] : [])];
for (const file of files) await access(resolveLocal(file));

const doc = await readFile(resolveLocal('docs/ESEL_HARNESS.md'), 'utf8');
for (const id of [...manifest.productContracts, ...manifest.manualChecks]) assert(doc.includes(`| ${id} |`), `문서에 계약 ${id} 누락`);
for (const [token, value] of Object.entries(manifest.designTokens)) assert(doc.includes(value), `문서에 토큰 ${token}(${value}) 누락`);

// The generator library is the source the canvas screens are built from; the manifest must agree with it.
const lib = await import(pathToFileURL(resolveLocal(design.library)).href);
for (const [token, value] of Object.entries(manifest.designTokens)) {
  if (value.startsWith('#')) assert(Object.values(lib).includes(value), `생성기 토큰 불일치: ${token}`);
}
assert.deepEqual(Object.keys(lib.PAINT).sort(), Object.keys(manifest.colors).sort(), '색 목록 불일치');
for (const [color, hex] of Object.entries(manifest.colors)) assert.equal(lib.PAINT[color].hex, hex, `색 값 불일치: ${color}`);
assert.deepEqual(Object.keys(lib.PEOPLE).sort(), Object.keys(manifest.demoPeople).sort(), '예시 인물 목록 불일치');
for (const [name, person] of Object.entries(lib.PEOPLE)) {
  assert(lib.PAINT[person.color], `${name}의 색 ${person.color}이 팔레트에 없음`);
  for (const key of ['fx', 'fy', 'fw']) assert(person[key] > 0 && person[key] < 1, `${name}의 얼굴 값 ${key} 범위 오류`);
}
assert.equal(lib.ME, manifest.signedInDemoUser, '로그인 예시 사용자 불일치');
assert.match('selin', new RegExp(manifest.foundingFlow.mastheadPattern), '제호 규칙이 예시 닉네임을 거부함');
assert(lib.mastSize('magdalena', 393, 200) < lib.mastSize('Esel', 393, 200), '제호 맞춤 크기 규칙 오류');

const pkg = JSON.parse(await readFile(path.join(root, 'package.json'), 'utf8'));
for (const [name, command] of Object.entries(manifest.commands)) assert.equal(pkg.scripts[name], command, `실행 명령 불일치: ${name}`);
assert.equal(new URL(rules.url).port, String(rules.port));
assert.equal(new URL(design.canvas).hostname, 'claude.ai');

const agents = await readFile(resolveLocal('AGENTS.md'), 'utf8');
assert(agents.includes('docs/ESEL_HARNESS.md') && agents.includes('harness.json'), 'AI 진입점 연결 누락');
for (const file of ['README.md', design.readme, 'docs/ESEL_HARNESS.md', 'AGENTS.md', 'assets/models-sources.md', 'docs/design/README.md', manifest.appMockup?.readme, manifest.development?.guide, 'docs/dev/FEATURES.md', ...manifest.archive.map((a) => a.banner)].filter(Boolean)) {
  const fullPath = resolveLocal(file);
  const markdown = await readFile(fullPath, 'utf8');
  for (const match of markdown.matchAll(/\]\(([^)]+)\)|<img src="([^"]+)"/g)) {
    const link = (match[1] ?? match[2]).split('#')[0];
    if (!link || /^[a-z]+:/i.test(link)) continue;
    await access(path.resolve(path.dirname(fullPath), link));
  }
}
// Old material stays in place but must be marked: registered in harness.json.archive, bannered at the top, and listed in README.
const readme = await readFile(resolveLocal('README.md'), 'utf8');
for (const item of manifest.archive) {
  if (item.banner) {
    const head = (await readFile(resolveLocal(item.banner), 'utf8')).split('\n')[0];
    assert(head.startsWith('> **') && head.includes('보관'), `보관 표시 누락: ${item.banner}`);
  }
  if (!/[*,:]/.test(item.path)) await access(resolveLocal(item.path));
  const folder = item.path.includes('.md') ? item.path.slice(0, item.path.lastIndexOf('/')) : item.path;
  assert(readme.includes(item.path) || readme.includes(folder) || /[,:]/.test(item.path), `README 보관 목록에 없음: ${item.path}`);
}
// Every prototype folder and loose work note must be either current or registered as archived.
const known = new Set([design.root, manifest.appMockup?.root, rules.root, ...manifest.archive.map((a) => a.path)]);
for (const entry of await readdir(resolveLocal('.codex/temp/prototype'), { withFileTypes: true })) {
  if (entry.isDirectory()) assert(known.has(`.codex/temp/prototype/${entry.name}`), `상태가 등록되지 않은 시안 폴더: ${entry.name} (harness.json.archive 또는 현재 경로에 추가)`);
}
for (const entry of await readdir(resolveLocal('.codex/temp'), { withFileTypes: true })) {
  if (entry.isFile() && entry.name.endsWith('.md')) assert(known.has(`.codex/temp/${entry.name}`), `상태가 등록되지 않은 작업 기록: ${entry.name}`);
}
const dev = await checkDev();
console.log(`하네스 정합성 통과: 경로 ${files.length}개, 색 ${Object.keys(manifest.colors).length}개, 예시 인물 ${Object.keys(manifest.demoPeople).length}명, 제품 계약 ${manifest.productContracts.length}개, 수동 검증 ${manifest.manualChecks.length}개, 보관 자료 ${manifest.archive.length}건, 개발 기능 ${dev.features}개(완료 ${dev.done})·목업 화면 ${dev.screens}장. 시각·실기기 검증은 별도입니다.`);
