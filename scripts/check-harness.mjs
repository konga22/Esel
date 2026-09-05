import assert from 'node:assert/strict';
import { readFile, access } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

// A portable consistency check, not an aesthetic score or a browser test.
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const manifest = JSON.parse(await readFile(path.join(root, 'harness.json'), 'utf8'));
assert.equal(manifest.schemaVersion, 1);
assert.equal(manifest.project, 'Esel');
const resolveLocal = value => {
  assert.equal(typeof value, 'string');
  assert(!path.isAbsolute(value), `저장소 상대 경로가 필요합니다: ${value}`);
  const target = path.resolve(root, value);
  assert(target.startsWith(root + path.sep), `저장소 밖 경로: ${value}`);
  return target;
};
const files = [...manifest.entrypoints, ...manifest.keyAssets, manifest.activePrototype.source,
  manifest.activePrototype.styles, manifest.activePrototype.review, manifest.activePrototype.stateTests,
  manifest.activePrototype.headerTests, manifest.nativeApp.routes, manifest.nativeApp.source, ...manifest.evidence];
for (const file of files) await access(resolveLocal(file));
const doc = await readFile(resolveLocal('docs/ESEL_HARNESS.md'), 'utf8');
for (const id of [...manifest.productContracts, ...manifest.manualChecks]) assert(doc.includes(`| ${id} |`), `문서에 계약 ${id} 누락`);
const css = await readFile(resolveLocal(manifest.activePrototype.styles), 'utf8');
for (const [token, value] of Object.entries(manifest.designTokens)) assert(css.includes(`--${token}:${value}`), `CSS 토큰 불일치: ${token}`);
const html = await readFile(resolveLocal(`${manifest.activePrototype.source}/index.html`), 'utf8');
for (const screen of manifest.activePrototype.screens) assert.equal(html.split(`data-screen="${screen}"`).length - 1, 1, `화면 ${screen} 누락 또는 중복`);
const pkg = JSON.parse(await readFile(path.join(root, 'package.json'), 'utf8'));
for (const [name, command] of Object.entries(manifest.commands)) assert.equal(pkg.scripts[name], command, `실행 명령 불일치: ${name}`);
assert.equal(new URL(manifest.activePrototype.url).port, String(manifest.activePrototype.port));
const agents = await readFile(resolveLocal('AGENTS.md'), 'utf8');
assert(agents.includes('docs/ESEL_HARNESS.md') && agents.includes('harness.json'), 'AI 진입점 연결 누락');
for (const file of [manifest.activePrototype.review, 'docs/ESEL_HARNESS.md', 'AGENTS.md']) {
  const fullPath = resolveLocal(file);
  const markdown = await readFile(fullPath, 'utf8');
  for (const match of markdown.matchAll(/\]\(([^)]+)\)/g)) {
    const link = match[1].split('#')[0];
    if (!link || /^[a-z]+:/i.test(link)) continue;
    await access(path.resolve(path.dirname(fullPath), link));
  }
}
console.log(`하네스 정합성 통과: 경로 ${files.length}개, 제품 계약 ${manifest.productContracts.length}개, 수동 검증 ${manifest.manualChecks.length}개. 시각·실기기 검증은 별도입니다.`);
