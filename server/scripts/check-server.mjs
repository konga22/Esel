// Server harness: checks the server against api-contract.json and the team rules, and explains every failure in plain Korean.
// Runs with plain Node (no install needed): `npm run check:server`. `--lock-migrations` records reviewed migrations.
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const server = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const rel = (p) => path.relative(server, p).split(path.sep).join('/');
const read = (p) => readFileSync(path.join(server, p), 'utf8');
const failures = [];
const notes = [];
const fail = (title, why, fix) => failures.push({ title, why, fix });
const note = (text) => notes.push(text);

function walk(dir, test) {
  const full = path.join(server, dir);
  if (!existsSync(full)) return [];
  return readdirSync(full).flatMap((name) => {
    const p = path.join(full, name);
    if (statSync(p).isDirectory()) return name === 'generated' || name === 'node_modules' ? [] : walk(rel(p), test);
    return test(name) ? [rel(p)] : [];
  });
}

// 1. The contract file itself.
const contract = JSON.parse(read('api-contract.json'));
const ids = new Set();
const routes = new Map();
for (const e of contract.endpoints) {
  const where = `api-contract.json의 ${e.id ?? '(id 없음)'}`;
  if (!e.id || ids.has(e.id)) fail(`${where}: id가 없거나 중복이에요`, 'API마다 고유한 이름이 있어야 문서·테스트·리뷰에서 같은 것을 가리킬 수 있어요.', 'id를 "모듈.동작" 형식으로 하나만 쓰세요. 예: issues.like');
  ids.add(e.id);
  const key = `${e.method} ${e.path}`;
  if (routes.has(key)) fail(`${where}: ${key}가 두 번 있어요`, '같은 주소와 방법은 한 API만 가질 수 있어요.', '하나를 지우거나 주소를 바꾸세요.');
  routes.set(key, e);
  if (!contract.access[e.access]) fail(`${where}: access "${e.access}"는 없는 값이에요`, '누가 부를 수 있는지가 분명해야 권한 실수가 없어요.', `public, user, owner, member 중 하나를 쓰세요.`);
  if (!contract.statuses.includes(e.status)) fail(`${where}: status "${e.status}"는 없는 값이에요`, '진행 상태로 남은 일을 셉니다.', 'todo, doing, done 중 하나를 쓰세요.');
  if (!/^(base|DEV-\d{2})$/.test(e.feature)) fail(`${where}: feature는 DEV-xx 형식이어야 해요`, '어느 기능의 API인지 알아야 합격 기준을 찾을 수 있어요.', '저장소 루트 docs/dev/FEATURES.md의 기능 ID를 쓰세요.');
  for (const code of e.errors) if (!contract.errors[code]) fail(`${where}: 오류 코드 ${code}가 목록에 없어요`, '오류 모양을 한곳에서 정해야 앱이 똑같이 처리할 수 있어요.', 'api-contract.json의 errors에 먼저 추가하세요.');
  if (!/^\/[a-z0-9\-/:]*$/.test(e.path) || /[A-Z_]/.test(e.path.replace(/:[a-zA-Z]+/g, ''))) fail(`${where}: 주소 ${e.path}가 규칙과 달라요`, '주소는 소문자와 하이픈만 써요(API_RULES 2장).', '예: /share-links, /me/records/:date/restore');
  if (!existsSync(path.join(server, e.test))) fail(`${where}: 테스트 파일 ${e.test}가 없어요`, 'API마다 합격 기준을 확인할 테스트 자리가 있어야 해요.', '파일을 만들고 it.todo로 할 일을 적어 두세요.');
}

// 2. What the code actually exposes (static scan of controllers).
const verbs = { Get: 'GET', Post: 'POST', Put: 'PUT', Patch: 'PATCH', Delete: 'DELETE' };
const join = (...parts) => `/${parts.map((p) => p.replace(/^\/|\/$/g, '')).filter(Boolean).join('/')}`;
const implemented = new Map();
for (const file of walk('src', (n) => n.endsWith('.controller.ts'))) {
  const src = read(file);
  const prefix = (src.match(/@Controller\(\s*(?:['"`]([^'"`]*)['"`])?\s*\)/) || [])[1] || '';
  for (const m of src.matchAll(/@(Get|Post|Put|Patch|Delete)\(\s*(?:['"`]([^'"`]*)['"`])?\s*\)/g)) {
    implemented.set(`${verbs[m[1]]} ${join(prefix, m[2] || '')}`, file);
  }
  if (/prisma\.service/.test(src)) fail(`${file}: 컨트롤러가 PrismaService를 직접 불러요`, '컨트롤러는 요청을 받고 응답을 돌려주는 일만 해요. DB와 규칙은 서비스가 맡아야 테스트하기 쉽고 실수가 줄어요.', '서비스(…service.ts)를 만들어 그 안에서 PrismaService를 쓰고, 컨트롤러는 서비스만 부르세요.');
}
for (const [key, file] of implemented) {
  if (!routes.has(key)) fail(`약속에 없는 API: ${key} (${file})`, '앱과 서버가 같은 약속을 봐야 해요. 약속에 없는 API는 앱이 모르거나, 리뷰 없이 생긴 기능이 돼요.', '필요하면 api-contract.json에 먼저 추가하고 PR에서 리뷰를 받으세요. 아니면 지우세요.');
}
for (const e of contract.endpoints) {
  const key = `${e.method} ${e.path}`;
  if (e.status === 'done') {
    if (!implemented.has(key)) fail(`${e.id}는 done인데 코드에 ${key}가 없어요`, '완료 표시는 실제로 동작할 때만 해요.', '구현하거나 status를 todo/doing으로 되돌리세요.');
    const pattern = new RegExp(`/api${e.path.replace(/:[a-zA-Z]+/g, "[^/'\"`\\s]+").replace(/\//g, '\\/')}(?![a-z0-9-])`);
    if (existsSync(path.join(server, e.test)) && !pattern.test(read(e.test))) fail(`${e.id}는 done인데 ${e.test}에 /api${e.path}를 부르는 테스트가 없어요`, '합격 기준을 테스트로 증명해야 완료예요.', 'it.todo를 실제 요청을 보내는 테스트로 바꾸세요.');
  } else if (implemented.has(key)) {
    note(`${e.id}는 코드에 있지만 status가 ${e.status}예요. 테스트까지 끝나면 done으로 바꾸세요.`);
  }
}

// 3. Owner-only numbers must never appear in public response shapes (contract P18).
for (const file of walk('src', (n) => n.endsWith('.ts'))) {
  const src = read(file);
  for (const m of src.matchAll(/class\s+(\w*PublicDto)\b[^{]*\{([\s\S]*?)\n\}/g)) {
    for (const field of contract.publicForbiddenFields) {
      if (new RegExp(`\\b${field}\\b`).test(m[2])) fail(`${file}: ${m[1]}에 ${field}가 있어요`, '좋아요·구독자·독자 한 줄·스크랩 수는 발행한 본인만 봐요(계약 P18). 공개용 응답에 넣으면 모든 사람에게 보여요.', `${field}는 …OwnerDto에만 두고, /api/me/… 처럼 주인만 부르는 API에서만 돌려주세요.`);
    }
  }
}

// 4. Swagger shows every endpoint; keep it out of production.
const main = existsSync(path.join(server, 'src/main.ts')) ? read('src/main.ts') : '';
const setupAt = main.indexOf('SwaggerModule.setup');
if (setupAt >= 0) {
  const before = main.slice(Math.max(0, setupAt - 600), setupAt);
  if (!/if\s*\([^)]*production/.test(before)) fail('src/main.ts: Swagger(/api/docs)가 운영 환경에서도 켜져 있어요', 'Swagger는 모든 API 주소와 모양을 보여 주는 문서예요. 운영 서버에서 켜 두면 누구나 우리 API 구조를 볼 수 있어요.', "NODE_ENV가 'production'이 아닐 때만 SwaggerModule.setup을 실행하세요. 예: if (config.get('NODE_ENV') !== 'production') { … }");
}

// 5. No BaaS or paid deploy services: the team runs its own server.
const pkg = JSON.parse(read('package.json'));
const deps = { ...pkg.dependencies, ...pkg.devDependencies };
const banned = { '@nestjs/mau': 'NestJS의 유료 클라우드 배포 서비스', firebase: 'BaaS', 'firebase-admin': 'BaaS', '@supabase/supabase-js': 'BaaS', 'aws-amplify': 'BaaS' };
for (const [name, what] of Object.entries(banned)) {
  if (deps[name]) fail(`package.json: ${name} (${what})가 들어 있어요`, '팀은 서버를 직접 운영하기로 했어요(ARCHITECTURE.md). 외부 서비스는 비용·데이터 위치·보안 책임이 생기므로 팀 승인 없이 넣지 않아요.', `npm uninstall ${name} 으로 지우세요. 꼭 필요하면 먼저 팀에 제안하세요.`);
}
for (const [name, cmd] of Object.entries(pkg.scripts || {})) {
  if (/\bnest deploy\b/.test(cmd)) fail(`package.json: "${name}": "${cmd}" 명령이 있어요`, 'nest deploy는 외부 유료 배포 서비스(Mau)로 서버를 올리는 명령이에요.', `package.json의 scripts에서 "${name}"를 지우세요.`);
}

// 6. Secrets never go into git.
let tracked = [];
try { tracked = execFileSync('git', ['ls-files', '.'], { cwd: server, encoding: 'utf8' }).split('\n').filter(Boolean); } catch { note('git 정보를 읽지 못해 비밀값 검사를 건너뛰었어요.'); }
for (const f of tracked) {
  const base = path.basename(f);
  if (/^\.env(\..+)?$/.test(base) && base !== '.env.example') fail(`${f}가 git에 올라가 있어요`, '.env에는 비밀번호와 키가 들어가요. 한 번 올리면 기록에 남아요.', 'git rm --cached 로 빼고, 노출된 비밀값은 바꾸세요.');
  if (/\.(ts|js|json|ya?ml|md|env|example)$/.test(base) && statSync(path.join(server, f)).size < 512_000) {
    const text = read(f);
    if (/-----BEGIN [A-Z ]*PRIVATE KEY-----|AKIA[0-9A-Z]{16}/.test(text)) fail(`${f}에 비밀 키처럼 보이는 값이 있어요`, '키를 코드에 넣으면 저장소를 본 누구나 쓸 수 있어요.', '환경 변수로 옮기고 .env.example에는 이름만 적으세요.');
  }
}

// 7. Shared migrations are history: never edit them, add a new one instead.
const lockFile = 'harness/migrations.lock.json';
const migrations = walk('prisma/migrations', (n) => n === 'migration.sql').sort();
const hash = (f) => createHash('sha256').update(readFileSync(path.join(server, f))).digest('hex');
if (process.argv.includes('--lock-migrations')) {
  writeFileSync(path.join(server, lockFile), `${JSON.stringify(Object.fromEntries(migrations.map((f) => [f, hash(f)])), null, 2)}\n`);
  console.log(`migration ${migrations.length}개를 ${lockFile}에 기록했어요.`);
  process.exit(0);
}
const lock = existsSync(path.join(server, lockFile)) ? JSON.parse(read(lockFile)) : {};
for (const [f, h] of Object.entries(lock)) {
  if (!existsSync(path.join(server, f))) fail(`공유된 migration이 사라졌어요: ${f}`, '다른 사람 DB에는 이미 적용된 기록이라 지우면 DB 구조가 서로 달라져요.', '파일을 되살리고, 되돌릴 내용은 새 migration으로 만드세요.');
  else if (hash(f) !== h) fail(`공유된 migration을 고쳤어요: ${f}`, 'migration은 DB 구조의 변경 기록이에요. 이미 다른 사람 DB에 적용된 기록을 고치면 서로의 DB가 어긋나요.', `git checkout -- ${f} 로 되돌리고, 바꿀 내용은 npm run prisma:migrate -- --name 변경이름 으로 새로 만드세요.`);
}
for (const f of migrations) if (!lock[f]) note(`새 migration ${f}가 있어요. 리뷰가 끝나 공유할 때 npm run migrations:lock 으로 기록하세요.`);

// Report.
const done = contract.endpoints.filter((e) => e.status === 'done').length;
console.log(`\nEsel 서버 하네스 · API ${contract.endpoints.length}개(완료 ${done}) · 코드의 API ${implemented.size}개 · migration ${migrations.length}개\n`);
for (const n of notes) console.log(`알림  ${n}`);
if (!failures.length) { console.log('\n통과했어요.'); process.exit(0); }
failures.forEach((f, i) => console.log(`\n실패 ${i + 1}. ${f.title}\n  왜 문제인가: ${f.why}\n  고치는 법: ${f.fix}`));
console.log(`\n실패 ${failures.length}건. 위의 "고치는 법"대로 고친 뒤 다시 실행하세요.`);
process.exit(1);
