// Self-tests for the server harness: what check-server.mjs must accept and reject. Run: npm run test:harness
import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  callsEndpoint,
  controllerRoutes,
  countTodos,
  dtoClasses,
  endpointTitles,
  forbiddenFieldMatch,
  mergeMigrationLock,
  migrationHash,
  publicDtoProblems,
  scan,
  seededColors,
  swaggerInProduction,
  testBlocks,
  usesPrismaDirectly,
} from './check-server-lib.mjs';

const calls = (src, method, path) => testBlocks(src).some((b) => callsEndpoint(b, method, path));

describe('done 판정: 실제 테스트만 인정', () => {
  it('it.todo 문구에 경로가 있어도 테스트가 아니다', () => {
    const src = "describe('x', () => {\n  it.todo('POST /api/issues/:id/like: 좋아요 → 201');\n});";
    assert.equal(calls(src, 'POST', '/issues/:id/like'), false);
    assert.equal(countTodos(src), 1);
  });

  it('주석으로 막아 둔 테스트는 세지 않는다', () => {
    const src = "// it('like', async () => { await request(app.getHttpServer()).post(`/api/issues/${id}/like`); });\n/* it('x', () => request(s).post('/api/issues/1/like')) */";
    assert.equal(calls(src, 'POST', '/issues/:id/like'), false);
  });

  it('it 블록 안에서 request(...)로 그 경로를 부르면 인정한다', () => {
    const src = "it('POST /api/issues/:id/like: 두 번 보내도 한 번', async () => {\n  await request(app.getHttpServer()).post(`/api/issues/${issue.id}/like`).expect(201);\n});";
    assert.equal(calls(src, 'POST', '/issues/:id/like'), true);
  });

  it('방법(method)이 다르거나 request가 없으면 인정하지 않는다', () => {
    const del = "it('x', async () => { await request(app.getHttpServer()).delete(`/api/issues/${id}/like`); });";
    assert.equal(calls(del, 'POST', '/issues/:id/like'), false);
    const noRequest = "it('x', () => { const url = '/api/issues/1/like'; http.post('/api/issues/1/like'); });";
    assert.equal(calls(noRequest, 'POST', '/issues/:id/like'), false);
  });

  it('it.skip은 테스트로 세지 않고, 비슷한 다른 경로와 헷갈리지 않는다', () => {
    const skip = "it.skip('x', () => request(s).get('/api/feed'));";
    assert.equal(calls(skip, 'GET', '/feed'), false);
    const longer = "it('x', () => request(s).get('/api/feeds'));";
    assert.equal(calls(longer, 'GET', '/feed'), false);
    const query = "test('x', () => request(s).get('/api/feed?tab=subs'));";
    assert.equal(calls(query, 'GET', '/feed'), true);
  });

  it('todo·테스트 제목에서 방법·경로·상태·오류 코드를 읽는다', () => {
    const titles = endpointTitles("it.todo('GET /api/twins/:id: 참여자가 아니거나 없는 트윈 → 404 NOT_FOUND');\nit.todo('POST /api/twins: 초대 → 201');");
    assert.deepEqual(
      titles.map(({ method, path, status, code }) => ({ method, path, status, code })),
      [
        { method: 'GET', path: '/twins/:id', status: 404, code: 'NOT_FOUND' },
        { method: 'POST', path: '/twins', status: 201, code: null },
      ],
    );
  });
});

describe('컨트롤러 주소 읽기', () => {
  it('문자열·객체·빈 @Controller와 배열 경로를 읽는다', () => {
    const src = `
@Controller({ path: 'issues', version: '1' })
export class IssuesController {
  @Get(':id') get() {}
  @Post([':id/like', ':id/likes']) like() {}
}
@Controller()
export class RootController {
  @Get('health') health() {}
}
@Controller('me')
export class MeController {
  @Delete() remove() {}
}`;
    assert.deepEqual(controllerRoutes(src).routes.sort(), ['DELETE /me', 'GET /health', 'GET /issues/:id', 'POST /issues/:id/like', 'POST /issues/:id/likes'].sort());
  });

  it('변수로 쓴 경로는 읽을 수 없다고 알려 준다', () => {
    const { unreadable } = controllerRoutes("@Controller(ISSUES_PATH)\nclass A { @Get(ROUTE) x() {} }");
    assert.equal(unreadable.length, 2);
  });

  it('주석 속 데코레이터는 주소로 세지 않는다', () => {
    assert.deepEqual(controllerRoutes("// @Controller('old')\n@Controller('new')\nclass A { /* @Get('x') */ @Get('y') y() {} }").routes, ['GET /new/y']);
  });
});

describe('컨트롤러가 DB를 직접 부르는지', () => {
  it('PrismaService·PrismaClient를 들여오거나 만들면 잡는다', () => {
    assert.equal(usesPrismaDirectly("import { PrismaService } from '../prisma/prisma.service.js';"), true);
    assert.equal(usesPrismaDirectly('constructor(private readonly db: PrismaClient) {}'), true);
    assert.equal(usesPrismaDirectly("const db = new PrismaClient();"), true);
    assert.equal(usesPrismaDirectly("import { PrismaClient } from '../generated/prisma/client.js';"), true);
  });

  it('주석으로 언급만 한 것은 괜찮다', () => {
    assert.equal(usesPrismaDirectly('// 컨트롤러는 PrismaService를 쓰지 않는다\nconstructor(private readonly issues: IssuesService) {}'), false);
  });
});

describe('공개 응답의 반응 숫자(P18)', () => {
  const forbidden = ['likeCount', 'lineCount', 'scrapCount', 'subscriberCount', 'readerCount', 'viewCount', 'rank', 'score', 'popularity'];

  it('이름을 바꿔 써도 잡는다', () => {
    for (const name of ['likeCount', 'likesCount', 'like_count', 'totalLikes', 'numLikes', 'subscribersCount', 'ranking', 'popularityScore']) {
      assert.ok(forbiddenFieldMatch(name, 'number', forbidden), name);
    }
    assert.ok(forbiddenFieldMatch('likes', 'number', forbidden));
  });

  it('내가 눌렀는지, 한 줄 글 목록은 공개해도 된다', () => {
    for (const [name, type] of [['liked', 'boolean'], ['subscribed', 'boolean'], ['lines', 'ReaderLinePublicDto[]'], ['issueNumber', 'number']]) {
      assert.equal(forbiddenFieldMatch(name, type, forbidden), null, name);
    }
  });

  it('…PublicDto 말고도 공개 API 응답과 그 안에 든 DTO를 모두 본다', () => {
    const classes = dtoClasses(`
export class FeedPageDto {
  @ApiProperty({ type: [FeedItemDto] })
  items: FeedItemDto[];
  nextCursor: string | null;
}
export class FeedItemDto {
  @ApiProperty() id: string;
  @ApiProperty({ description: '좋아요 수' })
  likesCount: number;
}`);
    const problems = publicDtoProblems(classes, ['FeedPageDto'], forbidden);
    assert.deepEqual(problems.map((p) => `${p.dto}.${p.field}`), ['FeedItemDto.likesCount']);
  });

  it('OwnerDto를 품거나 숫자를 골라 물려받으면 잡고, 숫자를 뺀 상속은 통과한다', () => {
    const classes = dtoClasses(`
export class IssueOwnerDto { id: string; likeCount: number; caption: string; }
export class IssuePublicDto extends OmitType(IssueOwnerDto, ['likeCount'] as const) {}
export class LeakPublicDto extends PickType(IssueOwnerDto, ['likeCount'] as const) {}
export class WrapDto { issue: IssueOwnerDto; }
export class StatsDto { get likeCount(): number { return 1; } stats: { scrapCount: number }; }`);
    const problems = publicDtoProblems(classes, ['WrapDto', 'StatsDto', 'IssueOwnerDto'], forbidden);
    const found = problems.map((p) => `${p.dto}.${p.field}:${p.forbidden ?? p.owner}`).sort();
    assert.deepEqual(found, ['LeakPublicDto.likeCount:likeCount', 'StatsDto.likeCount:likeCount', 'StatsDto.scrapCount:scrapCount', 'WrapDto.issue:IssueOwnerDto']);
  });
});

describe('Swagger는 운영에서 꺼야 한다', () => {
  const check = (src, extra = {}) => swaggerInProduction(new Map([['src/main.ts', src], ...Object.entries(extra)])).map((r) => r.result);

  it('조건 없이 켜면 실패', () => {
    assert.deepEqual(check("const document = SwaggerModule.createDocument(app, cfg);\nSwaggerModule.setup('api/docs', app, document);"), ['on']);
  });

  it('운영에서만 켜는 조건은 실패', () => {
    assert.deepEqual(check("if (process.env.NODE_ENV === 'production') {\n  SwaggerModule.setup('api/docs', app, doc);\n}"), ['on']);
    assert.deepEqual(check("if (config.get('NODE_ENV') !== 'development') SwaggerModule.setup('api/docs', app, doc);"), ['on']);
  });

  it('운영이 아닐 때만 켜는 여러 올바른 모양은 통과', () => {
    const ok = [
      "if (config.getOrThrow<string>('NODE_ENV') !== 'production') {\n  SwaggerModule.setup('api/docs', app, doc);\n}",
      "const swaggerEnabled = config.get('NODE_ENV', { infer: true }) !== 'production';\nif (swaggerEnabled) {\n  SwaggerModule.setup('api/docs', app, doc);\n}",
      "const isProduction = process.env.NODE_ENV === 'production';\nif (!isProduction) SwaggerModule.setup('api/docs', app, doc);",
      "function setup(app) {\n  if (process.env.NODE_ENV === 'production') return;\n  SwaggerModule.setup('api/docs', app, doc);\n}",
      "if (process.env.NODE_ENV === 'production') {\n  logger.log('docs off');\n} else {\n  SwaggerModule.setup('api/docs', app, doc);\n}",
      "if (isSwaggerEnabled(config.get('NODE_ENV'))) {\n  SwaggerModule.setup('api/docs', app, doc);\n}\nfunction isSwaggerEnabled(env: string): boolean { return env !== 'production'; }",
      "if (env === 'development') {\n  SwaggerModule.setup('api/docs', app, doc);\n}",
    ];
    for (const src of ok) assert.deepEqual(check(src), ['off'], src);
  });

  it('도우미 함수 안에서 켜면 그 함수를 부르는 곳의 조건을 본다', () => {
    const helper = "export function setupSwagger(app: INestApplication): void {\n  SwaggerModule.setup('api/docs', app, doc);\n}";
    assert.deepEqual(check("if (config.get('NODE_ENV') !== 'production') setupSwagger(app);", { 'src/swagger.ts': helper }), ['off']);
    assert.deepEqual(check('setupSwagger(app);', { 'src/swagger.ts': helper }), ['on']);
  });

  it('운영 여부 말고 다른 값(플래그)에 달린 조건은 "확인 필요"로 알린다', () => {
    assert.deepEqual(check("if (process.env.SWAGGER === 'true') SwaggerModule.setup('api/docs', app, doc);"), ['unknown']);
  });
});

describe('migration 잠금', () => {
  it('줄바꿈(CRLF·LF)이 달라도 같은 해시', () => {
    assert.equal(migrationHash('CREATE TABLE a ();\r\nSELECT 1;\r\n'), migrationHash('CREATE TABLE a ();\nSELECT 1;\n'));
  });

  it('새 migration은 더하고, 바뀌거나 사라진 공유 migration은 승인하지 않는다', () => {
    const lock = { 'a/migration.sql': 'h1', 'b/migration.sql': 'h2' };
    const result = mergeMigrationLock(lock, { 'a/migration.sql': 'h1', 'b/migration.sql': 'CHANGED', 'c/migration.sql': 'h3' });
    assert.deepEqual(result.added, ['c/migration.sql']);
    assert.deepEqual(result.changed, ['b/migration.sql']);
    assert.equal(result.lock['b/migration.sql'], 'h2');
    assert.deepEqual(mergeMigrationLock(lock, { 'a/migration.sql': 'h1' }).missing, ['b/migration.sql']);
  });

  it('migration의 12색 INSERT를 순서대로 읽는다', () => {
    const sql = `INSERT INTO "colors" ("id", "name_ko", "name_en", "hex", "sort_order") VALUES
  ('butter', '버터', 'Butter', '#E3C878', 2),
  ('sage', '세이지', 'Sage', '#A8B5A0', 1)
ON CONFLICT ("id") DO NOTHING;`;
    assert.deepEqual(seededColors([sql]), [
      { id: 'sage', hex: '#A8B5A0', order: 1 },
      { id: 'butter', hex: '#E3C878', order: 2 },
    ]);
  });
});

describe('소스 읽기', () => {
  it('문자열·정규식 속 따옴표와 괄호에 속지 않는다', () => {
    const { code, mask } = scan("const a = '/* not a comment */'; // real comment\nconst re = /it\\('x'/; it('y', () => {});");
    assert.ok(code.includes('/* not a comment */'));
    assert.ok(!code.includes('real comment'));
    assert.equal([...mask.matchAll(/\bit\s*\(/g)].length, 1);
  });
});
