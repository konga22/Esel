// Server harness: checks the server against api-contract.json, the repository root harness (harness.json, docs/dev/features.json)
// and the team rules, and explains every failure in plain Korean. Plain Node, no install: `npm run check:server`.
// `--lock-migrations` records new migrations after review (add-only). Self-tests: `npm run test:harness`.
import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  callsEndpoint,
  controllerRoutes,
  countTodos,
  dtoClasses,
  dtoNames,
  endpointTitles,
  mergeMigrationLock,
  migrationHash,
  publicDtoProblems,
  seededColors,
  swaggerInProduction,
  testBlocks,
  usesPrismaDirectly,
} from './check-server-lib.mjs';

const server = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const repo = path.resolve(server, '..');
const serverDir = path.relative(repo, server).split(path.sep).join('/');
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

// 0. --lock-migrations: record new migrations after review. Shared ones are never re-approved.
const lockFile = 'harness/migrations.lock.json';
const migrations = walk('prisma/migrations', (n) => n === 'migration.sql').sort();
const currentHashes = Object.fromEntries(migrations.map((f) => [f, migrationHash(read(f))]));
const lock = existsSync(path.join(server, lockFile)) ? JSON.parse(read(lockFile)) : {};
const lockState = mergeMigrationLock(lock, currentHashes);
if (process.argv.includes('--lock-migrations')) {
  const broken = [...lockState.changed.map((f) => `바뀜: ${f}`), ...lockState.missing.map((f) => `사라짐: ${f}`)];
  if (broken.length) {
    console.log(`이미 공유된 migration이 바뀌었거나 사라져서 기록하지 않았어요.\n${broken.map((b) => `  ${b}`).join('\n')}`);
    console.log('공유된 migration은 고치지 말고 새로 만드세요. git checkout -- <파일>로 되돌린 뒤, 바꿀 내용은 npm run prisma:migrate -- --name 변경이름 으로 새 migration을 만드세요.');
    process.exit(1);
  }
  if (!lockState.added.length) {
    console.log('새로 기록할 migration이 없어요.');
    process.exit(0);
  }
  writeFileSync(path.join(server, lockFile), `${JSON.stringify(lockState.lock, null, 2)}\n`);
  console.log(`새 migration ${lockState.added.length}개를 ${lockFile}에 더했어요:\n${lockState.added.map((f) => `  ${f}`).join('\n')}`);
  process.exit(0);
}

// 1. The contract file itself.
const contract = JSON.parse(read('api-contract.json'));
const base = contract.base ?? '/api';
const success = (e) => (e.response === 'void' ? contract.successStatus?.void : contract.successStatus?.[e.method]);
const ids = new Set();
const routes = new Map();
for (const e of contract.endpoints) {
  const where = `api-contract.json의 ${e.id ?? '(id 없음)'}`;
  if (!e.id || ids.has(e.id)) fail(`${where}: id가 없거나 중복이에요`, 'API마다 고유한 이름이 있어야 문서·테스트·리뷰에서 같은 것을 가리킬 수 있어요.', 'id를 "모듈.동작" 형식으로 하나만 쓰세요. 예: issues.like');
  ids.add(e.id);
  const key = `${e.method} ${e.path}`;
  if (routes.has(key)) fail(`${where}: ${key}가 두 번 있어요`, '같은 주소와 방법은 한 API만 가질 수 있어요.', '하나를 지우거나 주소를 바꾸세요.');
  routes.set(key, e);
  if (!contract.access[e.access]) fail(`${where}: access "${e.access}"는 없는 값이에요`, '누가 부를 수 있는지가 분명해야 권한 실수가 없어요.', 'public, user, owner, member 중 하나를 쓰세요.');
  if (!contract.statuses.includes(e.status)) fail(`${where}: status "${e.status}"는 없는 값이에요`, '진행 상태로 남은 일을 셉니다.', 'todo, doing, done 중 하나를 쓰세요.');
  if (!/^(base|DEV-\d{2})$/.test(e.feature)) fail(`${where}: feature는 DEV-xx 형식이어야 해요`, '어느 기능의 API인지 알아야 합격 기준을 찾을 수 있어요.', '저장소 루트 docs/dev/features.json의 기능 ID를 쓰세요.');
  for (const p of e.contracts) if (!/^P\d{2}$/.test(p)) fail(`${where}: 계약 "${p}"는 P01 같은 형식이 아니에요`, '제품 계약은 루트 하네스의 P01~P18 ID로 가리켜요.', 'P와 두 자리 숫자로 쓰세요.');
  for (const code of e.errors) if (!contract.errors[code]) fail(`${where}: 오류 코드 ${code}가 목록에 없어요`, '오류 모양을 한곳에서 정해야 앱이 똑같이 처리할 수 있어요.', 'api-contract.json의 errors에 먼저 추가하세요.');
  if (!/^(\/([a-z0-9-]+|:[a-z][a-zA-Z0-9]*))+$/.test(e.path)) fail(`${where}: 주소 ${e.path}가 규칙과 달라요`, '주소는 소문자와 하이픈만 써요. 경로 변수만 :lineId처럼 쓸 수 있어요(API_RULES 2장).', '예: /share-links, /me/records/:date/restore');
  if (e.request && !e.errors.includes('VALIDATION')) fail(`${where}: 요청 본문(${e.request})이 있는데 errors에 VALIDATION이 없어요`, '보낸 값의 형식이 틀리면 전역 검사(ValidationPipe)가 400 VALIDATION을 돌려줘요. 약속에 없으면 앱이 그 오류를 처리할 준비를 못 해요.', `${e.id}의 errors에 "VALIDATION"을 더하세요.`);
  if (e.access === 'member' && !e.errors.includes('NOT_FOUND')) fail(`${where}: member API인데 errors에 NOT_FOUND가 없어요`, '참여자가 아닌 사람에게는 404로 답해 그 트윈이 있다는 사실도 숨겨요(API_RULES 4장).', `${e.id}의 errors에 "NOT_FOUND"를 더하세요.`);
  if (e.access === 'owner' && !(e.errors.includes('NOT_FOUND') && e.errors.includes('FORBIDDEN'))) fail(`${where}: owner API인데 errors에 NOT_FOUND와 FORBIDDEN이 함께 있지 않아요`, '보이지 않는 것은 404, 보이지만 남의 것이면 403이에요(API_RULES 4장).', `${e.id}의 errors에 "NOT_FOUND"와 "FORBIDDEN"을 모두 적으세요.`);
  if (e.access !== 'public' && e.errors.includes('AUTH_REQUIRED')) fail(`${where}: errors에 AUTH_REQUIRED를 따로 적었어요`, 'public이 아닌 API의 401은 인증 가드가 돌려주므로 access로 정해져요. 한쪽에만 적으면 문서끼리 어긋나요.', `${e.id}의 errors에서 "AUTH_REQUIRED"를 빼세요.`);
  if (e.feature !== 'base' && e.test !== `test/contracts/${e.module}.e2e-spec.ts`) fail(`${where}: test는 test/contracts/${e.module}.e2e-spec.ts여야 해요`, '모듈마다 계약 테스트 파일이 하나예요. 루트 features.json의 tests도 이 경로를 가리켜요.', `test를 "test/contracts/${e.module}.e2e-spec.ts"로 고치세요.`);
  if (!existsSync(path.join(server, e.test))) fail(`${where}: 테스트 파일 ${e.test}가 없어요`, 'API마다 합격 기준을 확인할 테스트 자리가 있어야 해요.', '파일을 만들고 it.todo로 할 일을 적어 두세요.');
}

// 2. The repository root harness: product contracts, owner-only numbers, the 12 colors and the feature list.
const harnessFile = path.join(repo, 'harness.json');
const harness = existsSync(harnessFile) ? JSON.parse(readFileSync(harnessFile, 'utf8')) : null;
if (!harness) {
  fail('저장소 루트 harness.json을 찾을 수 없어요', '서버 약속은 루트 하네스(제품 계약 P01~P18, 숫자 공개 범위, 12색)를 따라야 해요. 루트를 못 읽으면 어긋나도 알 수 없어요.', 'server/는 저장소 안에서 실행하세요. 루트 파일을 옮겼다면 이 검사도 같이 고치세요.');
} else {
  const productIds = new Set(harness.productContracts ?? []);
  for (const e of contract.endpoints) {
    for (const p of e.contracts) if (!productIds.has(p)) fail(`api-contract.json의 ${e.id}: 계약 ${p}가 루트 harness.json의 productContracts에 없어요`, '계약 ID는 루트 하네스(docs/ESEL_HARNESS.md)에 있는 것만 써요. 없는 ID는 리뷰어가 근거를 찾을 수 없어요.', `있는 ID로 고치세요: ${[...productIds].join(', ')}`);
  }
  for (const key of harness.publicCounts?.ownerOnly ?? []) {
    const field = contract.publicCountFields?.[key];
    if (!field) fail(`루트 harness.json의 숫자 "${key}"(본인만 보는 숫자)에 맞는 서버 필드 이름이 없어요`, '좋아요·구독자·독자 한 줄 수·스크랩 수는 본인만 봐요(P18). 루트가 정한 숫자마다 서버의 필드 이름을 정해야 공개 응답 검사가 그 이름을 막을 수 있어요.', `api-contract.json의 publicCountFields에 "${key}": "…Count"를 더하고, 그 이름을 publicForbiddenFields에도 넣으세요.`);
    else if (!contract.publicForbiddenFields.includes(field)) fail(`api-contract.json: ${field}("${key}")가 publicForbiddenFields에 없어요`, '본인만 보는 숫자는 공개 응답에 들어가면 안 돼요(P18).', `publicForbiddenFields에 "${field}"를 더하세요.`);
  }
  const colors = Object.entries(harness.colors ?? {}).map(([id, hex], k) => ({ id, hex, order: k + 1 }));
  const seeded = seededColors(migrations.map(read));
  const show = (list) => list.map((c) => `${c.order}.${c.id}${c.hex}`).join(' ');
  if (show(colors) !== show(seeded)) fail('migration의 12색이 루트 harness.json의 colors와 달라요', '오늘의 색은 12색이고(P17), 앱·디자인·서버가 같은 key·hex·순서를 써야 같은 색을 가리켜요.', `루트: ${show(colors)}\n  migration: ${show(seeded) || '(없음)'}\n  바꿀 내용을 새 migration으로 만드세요(기존 migration은 고치지 않아요).`);

  const featuresPath = harness.development?.features;
  if (!featuresPath) note('루트 harness.json에 development.features가 없어 기능 목록(features.json) 대조를 건너뛰었어요. 루트가 오래된 브랜치예요. main을 합친 뒤 다시 확인하세요.');
  else if (!existsSync(path.join(repo, featuresPath))) fail(`루트 ${featuresPath}이 없어요`, 'harness.json이 가리키는 기능 목록이 있어야 서버 API가 어느 기능의 합격 기준을 따르는지 확인할 수 있어요.', '루트 harness.json의 development.features 경로를 확인하세요.');
  else {
    const features = JSON.parse(readFileSync(path.join(repo, featuresPath), 'utf8')).features ?? [];
    const byId = new Map(features.map((f) => [f.id, f]));
    const unlinked = new Map();
    for (const e of contract.endpoints) {
      if (e.feature === 'base') continue;
      const f = byId.get(e.feature);
      const testPath = `${serverDir}/${e.test}`;
      if (!f) fail(`api-contract.json의 ${e.id}: 기능 ${e.feature}가 루트 ${featuresPath}에 없어요`, 'API는 루트 기능 목록(DEV-01~)의 한 기능에 속해야 합격 기준을 찾을 수 있어요.', `있는 기능 ID로 고치거나, 새 기능이면 루트 ${featuresPath}에 먼저 더하세요.`);
      else if (!(f.tests ?? []).includes(testPath)) unlinked.set(`${f.id} ${testPath}`, [...(unlinked.get(`${f.id} ${testPath}`) ?? []), e.id]);
    }
    for (const [key, apis] of unlinked) {
      const [id, testPath] = key.split(' ');
      fail(`루트 ${featuresPath}의 ${id} tests에 ${testPath}가 없어요(${apis.join(', ')})`, '루트 하네스는 기능이 done일 때 tests의 파일이 있는지 봐요. 두 곳이 다른 파일을 가리키면 서버 테스트가 합격 기준으로 연결되지 않아요.', `루트 ${featuresPath}의 ${id} tests에 "${testPath}"를 더하세요(루트는 npm run dev:docs로 FEATURES.md도 다시 만들어요).`);
    }
    for (const f of features) {
      const waiting = contract.endpoints.filter((e) => e.feature === f.id && e.status !== 'done');
      if (f.status === 'done' && waiting.length) fail(`루트 ${featuresPath}의 ${f.id}는 done인데 서버 API가 아직 끝나지 않았어요: ${waiting.map((e) => e.id).join(', ')}`, '기능은 그 기능의 서버 API가 모두 끝나야 완료예요.', `API를 끝내고 status를 done으로 바꾸거나, ${f.id}의 status를 되돌리세요.`);
      for (const t of f.tests ?? []) {
        if (t.startsWith(`${serverDir}/`) && !existsSync(path.join(repo, t))) fail(`루트 ${featuresPath}의 ${f.id} tests에 있는 ${t}가 없어요`, '기능 목록이 가리키는 서버 테스트 파일이 있어야 합격 기준을 확인할 수 있어요.', `${t}를 만들거나 루트 tests의 경로를 고치세요.`);
      }
    }
  }
}

// 3. Tests: every API has a todo or test, done needs a real request, and titles agree with the contract.
const testFiles = new Map();
const loadTest = (f) => {
  if (!testFiles.has(f)) {
    const src = read(f);
    testFiles.set(f, { titles: endpointTitles(src, base), blocks: testBlocks(src) });
  }
  return testFiles.get(f);
};
for (const e of contract.endpoints) {
  if (!existsSync(path.join(server, e.test))) continue;
  const t = loadTest(e.test);
  const label = `${e.method} ${base}${e.path}`;
  const called = t.blocks.some((b) => callsEndpoint(b, e.method, e.path, base));
  const named = t.titles.filter((x) => x.method === e.method && x.path === e.path);
  if (!called && !named.length) fail(`${e.id}: ${e.test}에 ${label}의 todo나 테스트가 없어요`, 'todo는 손으로 관리해요. 할 일이 테스트 파일에 없으면 빠뜨린 API를 아무도 모르게 돼요.', `${e.test}에 it.todo('${label}: ${e.summary} → ${success(e)}')를 더하세요.`);
  if (e.status === 'done' && !called) fail(`${e.id}는 done인데 ${e.test}에 ${label}를 부르는 실제 테스트가 없어요`, '합격 기준을 테스트로 증명해야 완료예요. it.todo 문구나 주석은 테스트가 아니에요.', `it('${label}: …', async () => { await request(app.getHttpServer()).${e.method.toLowerCase()}(\`${base}${e.path.replace(/:(\w+)/g, '${$1}')}\`)… })처럼 it 블록 안에서 request(...)로 부르는 테스트를 쓰세요.`);
  for (const x of named) {
    if (x.status === null) continue;
    if (x.code) {
      const known = e.errors.includes(x.code) || (e.access !== 'public' && ['AUTH_REQUIRED', 'TOKEN_EXPIRED'].includes(x.code));
      if (!known) fail(`${e.test}: "${x.text}"의 ${x.code}가 ${e.id}의 errors에 없어요`, '테스트가 약속에 없는 오류를 기대하면 앱과 서버가 서로 다른 오류를 처리하게 돼요.', `api-contract.json의 ${e.id} errors에 ${x.code}를 더하거나 테스트를 고치세요.`);
      else if (contract.errors[x.code]?.status !== x.status) fail(`${e.test}: "${x.text}"의 상태(${x.status})가 ${x.code}의 상태(${contract.errors[x.code].status})와 달라요`, '오류 코드마다 상태 코드는 하나예요(api-contract.json의 errors).', `→ ${contract.errors[x.code].status} ${x.code}로 고치세요.`);
    } else if (x.status >= 200 && x.status < 300 && x.status !== success(e)) {
      fail(`${e.test}: "${x.text}"의 성공 상태(${x.status})가 약속(${success(e)})과 달라요`, '성공 상태는 api-contract.json의 successStatus 하나로 정해요(GET·PUT·PATCH·DELETE 200, POST 201, 돌려줄 것이 없으면 204).', `→ ${success(e)}로 고치세요.`);
    }
  }
}
const e2eFiles = walk('test', (n) => n.endsWith('.e2e-spec.ts'));
for (const f of e2eFiles) {
  for (const x of loadTest(f).titles) {
    if (!routes.has(`${x.method} ${x.path}`)) fail(`${f}: "${x.text}"는 api-contract.json에 없는 API예요`, '약속에 없는 API의 할 일이 남아 있으면 무엇을 만들어야 하는지 헷갈려요.', '주소를 약속과 같게 고치거나, 필요한 API면 api-contract.json에 먼저 더하세요.');
  }
}

// 4. What the code actually exposes (static scan of controllers).
const implemented = new Map();
for (const file of walk('src', (n) => n.endsWith('.controller.ts'))) {
  const src = read(file);
  const { routes: found, unreadable } = controllerRoutes(src);
  for (const r of found) implemented.set(r, file);
  for (const u of unreadable) fail(`${file}: 검사가 ${u}의 주소를 읽을 수 없어요`, '주소를 변수로 쓰면 약속(api-contract.json)과 같은지 자동으로 확인할 수 없어요.', "@Controller('issues'), @Get(':id/like')처럼 주소를 문자열로 바로 쓰세요.");
  if (usesPrismaDirectly(src)) fail(`${file}: 컨트롤러가 DB(PrismaService·PrismaClient)를 직접 다뤄요`, '컨트롤러는 요청을 받고 응답을 돌려주는 일만 해요. DB와 규칙은 서비스가 맡아야 테스트하기 쉽고 권한 확인을 빠뜨리지 않아요.', '서비스(…service.ts)를 만들어 그 안에서 PrismaService를 쓰고, 컨트롤러는 서비스만 부르세요.');
}
for (const [key, file] of implemented) {
  if (!routes.has(key)) fail(`약속에 없는 API: ${key} (${file})`, '앱과 서버가 같은 약속을 봐야 해요. 약속에 없는 API는 앱이 모르거나, 리뷰 없이 생긴 기능이 돼요.', '필요하면 api-contract.json에 먼저 추가하고 PR에서 리뷰를 받으세요. 아니면 지우세요.');
}
for (const e of contract.endpoints) {
  const key = `${e.method} ${e.path}`;
  if (e.status === 'done' && !implemented.has(key)) fail(`${e.id}는 done인데 코드에 ${key}가 없어요`, '완료 표시는 실제로 동작할 때만 해요.', '구현하거나 status를 todo/doing으로 되돌리세요.');
  else if (e.status !== 'done' && implemented.has(key)) note(`${e.id}는 코드에 있지만 status가 ${e.status}예요. 테스트까지 끝나면 done으로 바꾸세요.`);
}

// 5. Owner-only numbers never appear in responses other people receive (contract P18).
const sourceFiles = walk('src', (n) => n.endsWith('.ts') && !n.endsWith('.spec.ts'));
const classes = new Map();
for (const file of sourceFiles) for (const [name, cls] of dtoClasses(read(file))) classes.set(name, { ...cls, file });
const publicRoots = contract.endpoints.filter((e) => e.access === 'public' || e.access === 'user').flatMap((e) => dtoNames(e.response));
for (const p of publicDtoProblems(classes, publicRoots, contract.publicForbiddenFields)) {
  const where = `${classes.get(p.dto)?.file ?? 'src'}: ${p.dto}.${p.field}${p.from && p.from !== p.dto ? `(${p.from}에서 물려받음)` : ''}`;
  if (p.owner) fail(`${where}가 ${p.owner}를 품고 있어요`, '다른 사람이 받는 응답 안에 주인용 DTO가 들어가면 본인만 볼 숫자가 함께 나가요(P18).', '공개용 DTO(…PublicDto)를 따로 만들어 쓰세요.');
  else fail(`${where}는 ${p.forbidden}와 같은 숫자예요`, '좋아요·구독자·독자 한 줄·스크랩 수와 순위는 발행한 본인만 봐요(계약 P18). 다른 사람이 받는 응답(public·user API와 그 안의 DTO)에 넣으면 모두에게 보여요.', '이 숫자는 …OwnerDto에만 두고, /api/me/…처럼 주인만 부르는 API에서만 돌려주세요.');
}

// 6. Swagger shows every endpoint; keep it out of production.
const sources = new Map(sourceFiles.map((f) => [f, read(f)]));
for (const s of swaggerInProduction(sources)) {
  if (s.result === 'on') fail(`${s.file}:${s.line}: Swagger(/api/docs)가 운영 환경(NODE_ENV=production)에서도 켜져요`, 'Swagger는 모든 API 주소와 모양을 보여 주는 문서예요. 운영 서버에서 켜 두면 누구나 우리 API 구조를 볼 수 있어요.', "운영이 아닐 때만 SwaggerModule.setup을 실행하세요. 예: if (config.getOrThrow<string>('NODE_ENV') !== 'production') { … }");
  if (s.result === 'unknown') note(`${s.file}:${s.line}: Swagger를 켜는 조건이 NODE_ENV 말고 다른 값(플래그 등)에 달려 있어 검사가 확정하지 못했어요. 운영에서 꺼지는지 직접 확인하세요.`);
}

// 7. No BaaS or paid deploy services: the team runs its own server.
const pkg = JSON.parse(read('package.json'));
const deps = { ...pkg.dependencies, ...pkg.devDependencies };
const banned = { '@nestjs/mau': 'NestJS의 유료 클라우드 배포 서비스', firebase: 'BaaS', 'firebase-admin': 'BaaS', '@supabase/supabase-js': 'BaaS', 'aws-amplify': 'BaaS' };
for (const [name, what] of Object.entries(banned)) {
  if (deps[name]) fail(`package.json: ${name} (${what})가 들어 있어요`, '팀은 서버를 직접 운영하기로 했어요(ARCHITECTURE.md). 외부 서비스는 비용·데이터 위치·보안 책임이 생기므로 팀 승인 없이 넣지 않아요.', `npm uninstall ${name} 으로 지우세요. 꼭 필요하면 먼저 팀에 제안하세요.`);
}
for (const [name, cmd] of Object.entries(pkg.scripts || {})) {
  if (/\bnest deploy\b/.test(cmd)) fail(`package.json: "${name}": "${cmd}" 명령이 있어요`, 'nest deploy는 외부 유료 배포 서비스(Mau)로 서버를 올리는 명령이에요.', `package.json의 scripts에서 "${name}"를 지우세요.`);
}

// 8. Secrets never go into git.
let tracked = [];
try {
  tracked = execFileSync('git', ['ls-files', '.'], { cwd: server, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).split('\n').filter(Boolean);
} catch {
  note('git 정보를 읽지 못해 비밀값 검사를 건너뛰었어요.');
}
for (const f of tracked) {
  const name = path.basename(f);
  if (/^\.env(\..+)?$/.test(name) && name !== '.env.example') fail(`${f}가 git에 올라가 있어요`, '.env에는 비밀번호와 키가 들어가요. 한 번 올리면 기록에 남아요.', 'git rm --cached 로 빼고, 노출된 비밀값은 바꾸세요.');
  if (/\.(ts|js|mjs|json|ya?ml|md|env|example)$/.test(name) && existsSync(path.join(server, f)) && statSync(path.join(server, f)).size < 512_000) {
    if (/-----BEGIN [A-Z ]*PRIVATE KEY-----|AKIA[0-9A-Z]{16}/.test(read(f))) fail(`${f}에 비밀 키처럼 보이는 값이 있어요`, '키를 코드에 넣으면 저장소를 본 누구나 쓸 수 있어요.', '환경 변수로 옮기고 .env.example에는 이름만 적으세요.');
  }
}

// 9. Shared migrations are history: never edit them, add a new one instead.
for (const f of lockState.missing) fail(`공유된 migration이 사라졌어요: ${f}`, '다른 사람 DB에는 이미 적용된 기록이라 지우면 DB 구조가 서로 달라져요.', '파일을 되살리고, 되돌릴 내용은 새 migration으로 만드세요.');
for (const f of lockState.changed) fail(`공유된 migration을 고쳤어요: ${f}`, 'migration은 DB 구조의 변경 기록이에요. 이미 다른 사람 DB에 적용된 기록을 고치면 서로의 DB가 어긋나요. (줄바꿈 CRLF·LF 차이는 같은 것으로 봐요.)', `git checkout -- ${f} 로 되돌리고, 바꿀 내용은 npm run prisma:migrate -- --name 변경이름 으로 새로 만드세요.`);
for (const f of lockState.added) note(`아직 기록하지 않은 새 migration이 있어요: ${f}. 리뷰가 끝나 공유할 때 npm run migrations:lock 으로 기록하세요.`);

// Report.
const count = (s) => contract.endpoints.filter((e) => e.status === s).length;
const allTests = [...e2eFiles, ...walk('src', (n) => n.endsWith('.spec.ts'))].map(read);
const todos = allTests.reduce((n, src) => n + countTodos(src), 0);
const realTests = allTests.reduce((n, src) => n + testBlocks(src).length, 0);
console.log(`\nEsel 서버 하네스 · API ${contract.endpoints.length}개(완료 ${count('done')} · 진행 ${count('doing')} · 할 일 ${count('todo')}) · 테스트 ${realTests}개 · todo ${todos}개 · 코드의 API ${implemented.size}개 · migration ${migrations.length}개\n`);
for (const n of notes) console.log(`알림  ${n}`);
if (!failures.length) {
  console.log('\n통과했어요.');
  process.exit(0);
}
failures.forEach((f, i) => console.log(`\n실패 ${i + 1}. ${f.title}\n  왜 문제인가: ${f.why}\n  고치는 법: ${f.fix}`));
console.log(`\n실패 ${failures.length}건. 위의 "고치는 법"대로 고친 뒤 다시 실행하세요.`);
process.exit(1);
