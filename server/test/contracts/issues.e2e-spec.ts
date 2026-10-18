import { INestApplication } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { App } from 'supertest/types.js';
import { serviceDate } from '../../src/common/service-date.js';
import { PrismaService } from '../../src/prisma/prisma.service.js';
import { createTestApp } from '../create-app.js';

// 계약 테스트: issues 모듈. api-contract.json의 API와 루트 docs/dev/features.json의 서버 합격 기준을 할 일(it.todo)로 적어 두었다.
// 이 파일은 손으로 관리한다. API마다 'METHOD /api/경로: … → 상태' 형식의 todo나 테스트가 있어야 하고, 상태 코드는 api-contract.json과 같아야 한다(npm run check:server가 확인).
// 하나를 구현하면 그 todo를 it(…) 안에서 request(app.getHttpServer()).<method>('/api/…')로 부르는 실제 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-09 오늘 호 발행', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let publishMastheadSequence = 0;

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
    await cleanup();
  });
  afterEach(cleanup);
  afterAll(async () => app.close());

  async function cleanup() {
    await prisma.issue.deleteMany({
      where: { author: { email: { endsWith: '@publish.e2e.test' } } },
    });
    await prisma.user.deleteMany({
      where: { email: { endsWith: '@publish.e2e.test' } },
    });
  }

  async function publishingUser(label: string) {
    const signup = await request(app.getHttpServer())
      .post('/api/auth/email/signup')
      .send({
        email: `${label}-${randomUUID()}@publish.e2e.test`,
        password: 'correct horse battery staple',
      })
      .expect(201);
    const user = {
      userId: signup.body.userId as string,
      token: signup.body.accessToken as string,
    };
    await prisma.profile.create({
      data: {
        userId: user.userId,
        masthead: nextPublishMasthead(),
      },
    });
    const today = await request(app.getHttpServer())
      .get('/api/today')
      .set('Authorization', `Bearer ${user.token}`)
      .expect(200);
    await request(app.getHttpServer())
      .put('/api/today/choice')
      .set('Authorization', `Bearer ${user.token}`)
      .send({ colorId: today.body.candidates[0].id })
      .expect(200);
    return user;
  }

  function nextPublishMasthead(): string {
    let value = publishMastheadSequence++;
    let suffix = '';
    do {
      suffix = String.fromCharCode(97 + (value % 26)) + suffix;
      value = Math.floor(value / 26) - 1;
    } while (value >= 0);
    return `pub${suffix}`;
  }

  async function media(userId: string, status: 'PENDING' | 'READY' = 'READY') {
    return prisma.mediaAsset.create({
      data: {
        ownerId: userId,
        storageKey: `publish-e2e/${randomUUID()}`,
        status,
        mimeType: 'image/png',
        sizeBytes: 24,
        width: 1080,
        height: 1440,
      },
    });
  }

  const payload = (mediaId: string) => ({
    mediaId,
    caption: '  오늘의 기록  ',
    faceMode: 'PLAIN',
  });

  // issues.publish · 접근: user · 응답: IssueOwnerDto · 계약: P04, P01
  it('POST /api/issues: 오늘 호 발행(하루 한 번, 호수 +1) → 201', async () => {
    const user = await publishingUser('success');
    const ready = await media(user.userId);
    const response = await request(app.getHttpServer())
      .post('/api/issues')
      .set('Authorization', `Bearer ${user.token}`)
      .send(payload(ready.id))
      .expect(201);
    expect(response.body).toMatchObject({
      issueNumber: 1,
      caption: '오늘의 기록',
      faceMode: 'PLAIN',
      garments: [],
      likeCount: 0,
      scrapCount: 0,
      lineCount: 0,
    });
    expect(
      await prisma.profile.findUnique({ where: { userId: user.userId } }),
    ).toMatchObject({ issueCount: 1 });
    expect(
      await prisma.userDailyChoice.findFirst({
        where: { userId: user.userId },
      }),
    ).toMatchObject({ lockedAt: expect.any(Date) });
  });

  it('POST /api/issues: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/issues')
      .send(payload(randomUUID()))
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('POST /api/issues: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION', async () => {
    const user = await publishingUser('invalid');
    const ready = await media(user.userId);
    const response = await request(app.getHttpServer())
      .post('/api/issues')
      .set('Authorization', `Bearer ${user.token}`)
      .send({ ...payload(ready.id), faceMode: 'UNKNOWN' })
      .expect(400);
    expect(response.body.error.code).toBe('VALIDATION');
  });

  it('POST /api/issues: 오늘 호는 이미 발행했어요 → 409 ISSUE_ALREADY_PUBLISHED', async () => {
    const user = await publishingUser('duplicate');
    const first = await media(user.userId);
    const second = await media(user.userId);
    await request(app.getHttpServer())
      .post('/api/issues')
      .set('Authorization', `Bearer ${user.token}`)
      .send(payload(first.id))
      .expect(201);
    const response = await request(app.getHttpServer())
      .post('/api/issues')
      .set('Authorization', `Bearer ${user.token}`)
      .send(payload(second.id))
      .expect(409);
    expect(response.body.error.code).toBe('ISSUE_ALREADY_PUBLISHED');
  });

  it('POST /api/issues: 사진 올리기가 아직 끝나지 않았어요 → 409 MEDIA_NOT_READY', async () => {
    const user = await publishingUser('pending');
    const pending = await media(user.userId, 'PENDING');
    const response = await request(app.getHttpServer())
      .post('/api/issues')
      .set('Authorization', `Bearer ${user.token}`)
      .send(payload(pending.id))
      .expect(409);
    expect(response.body.error.code).toBe('MEDIA_NOT_READY');
    expect(
      await prisma.profile.findUnique({ where: { userId: user.userId } }),
    ).toMatchObject({ issueCount: 0 });
  });

  it('합격 기준(P04): 동시에 두 번 보내도 호가 하나만 생김(DB unique)', async () => {
    const user = await publishingUser('concurrent');
    const first = await media(user.userId);
    const second = await media(user.userId);
    const responses = await Promise.all([
      request(app.getHttpServer())
        .post('/api/issues')
        .set('Authorization', `Bearer ${user.token}`)
        .send(payload(first.id)),
      request(app.getHttpServer())
        .post('/api/issues')
        .set('Authorization', `Bearer ${user.token}`)
        .send(payload(second.id)),
    ]);
    expect(responses.map(({ status }) => status).sort((left, right) => left - right)).toEqual([201, 409]);
    expect(await prisma.issue.count({ where: { authorId: user.userId } })).toBe(
      1,
    );
    expect(
      await prisma.profile.findUnique({ where: { userId: user.userId } }),
    ).toMatchObject({ issueCount: 1 });
  });

  it.todo(
    '합격 기준(P01): 발행하면 오늘 후보 3색 방이 모두 열림(GET /api/stand)',
  );
  // 10-18 착용 정보(DEV-24, P19): garments[]는 선택 필드
  it('합격 기준(P19): garments 없이 보내도 발행됨. 보내면 최대 8개까지 저장하고 응답에 그대로 돌려줌', async () => {
    const user = await publishingUser('garments');
    const ready = await media(user.userId);
    const response = await request(app.getHttpServer())
      .post('/api/issues')
      .set('Authorization', `Bearer ${user.token}`)
      .send({
        ...payload(ready.id),
        garments: [
          {
            kind: '셔츠',
            name: '파란 셔츠',
            note: '오래 입음',
            todayColor: true,
            x: 0.25,
            y: 0.5,
          },
        ],
      })
      .expect(201);
    expect(response.body.garments).toEqual([
      expect.objectContaining({
        garmentId: expect.any(String),
        kind: '셔츠',
        name: '파란 셔츠',
        note: '오래 입음',
        todayColor: true,
        x: 0.25,
        y: 0.5,
      }),
    ]);
  });

  it('합격 기준(P19): garments가 9개 이상이거나 kind가 목록에 없으면 400 VALIDATION, 호는 만들어지지 않음', async () => {
    const user = await publishingUser('garment-invalid');
    const ready = await media(user.userId);
    for (const garments of [
      Array.from({ length: 9 }, () => ({ kind: '셔츠' })),
      [{ kind: '자동차' }],
    ]) {
      await request(app.getHttpServer())
        .post('/api/issues')
        .set('Authorization', `Bearer ${user.token}`)
        .send({ ...payload(ready.id), garments })
        .expect(400);
    }
    expect(await prisma.issue.count({ where: { authorId: user.userId } })).toBe(
      0,
    );
  });

  it('합격 기준(P19): garments 항목의 URL·가격 같은 모르는 필드는 거절(whitelist)하고 저장하지 않음', async () => {
    const user = await publishingUser('garment-forbidden');
    const ready = await media(user.userId);
    for (const forbidden of [
      { price: 1000 },
      { shopUrl: 'https://example.com' },
    ]) {
      const response = await request(app.getHttpServer())
        .post('/api/issues')
        .set('Authorization', `Bearer ${user.token}`)
        .send({
          ...payload(ready.id),
          garments: [{ kind: '셔츠', ...forbidden }],
        })
        .expect(400);
      expect(response.body.error.code).toBe('VALIDATION');
    }
  });

  it('합격 기준(P19): garmentId로 남의 옷을 고르면 400 VALIDATION(내 옷만 다시 고를 수 있음)', async () => {
    const user = await publishingUser('garment-owner');
    const other = await publishingUser('garment-other');
    const otherGarment = await prisma.garment.create({
      data: { ownerId: other.userId, kind: '코트' },
    });
    const ready = await media(user.userId);
    const response = await request(app.getHttpServer())
      .post('/api/issues')
      .set('Authorization', `Bearer ${user.token}`)
      .send({
        ...payload(ready.id),
        garments: [{ garmentId: otherGarment.id, kind: '코트' }],
      })
      .expect(400);
    expect(response.body.error.code).toBe('VALIDATION');
  });
});

describe('DEV-11 펼침면과 독자 한 줄', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let timeZone: string;
  let mastheadSequence = 0;

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
    timeZone = app.get(ConfigService).getOrThrow<string>('SERVICE_TIME_ZONE');
    await cleanupFixtures();
  });

  afterEach(cleanupFixtures);
  afterAll(async () => app.close());

  async function cleanupFixtures() {
    await prisma.issue.deleteMany({
      where: { author: { email: { endsWith: '@issues.e2e.test' } } },
    });
    await prisma.user.deleteMany({
      where: { email: { endsWith: '@issues.e2e.test' } },
    });
  }

  function nextMasthead(): string {
    let number = mastheadSequence++;
    let suffix = '';
    do {
      suffix = String.fromCharCode(97 + (number % 26)) + suffix;
      number = Math.floor(number / 26) - 1;
    } while (number >= 0);
    return `mag${suffix}`;
  }

  async function signup(name: string) {
    const response = await request(app.getHttpServer())
      .post('/api/auth/email/signup')
      .send({
        email: `${name}-${randomUUID()}@issues.e2e.test`,
        password: 'correct horse battery staple',
      })
      .expect(201);
    const user = {
      userId: response.body.userId as string,
      token: response.body.accessToken as string,
      masthead: nextMasthead(),
    };
    await prisma.profile.create({
      data: { userId: user.userId, masthead: user.masthead },
    });
    return user;
  }

  function dateAt(offsetDays: number): Date {
    const key = serviceDate(new Date(), timeZone);
    const date = new Date(`${key}T00:00:00.000Z`);
    date.setUTCDate(date.getUTCDate() + offsetDays);
    return date;
  }

  async function createIssue(
    author: { userId: string },
    options: {
      serviceDate?: Date;
      colorId?: string;
      publishedAt?: Date;
    } = {},
  ) {
    const media = await prisma.mediaAsset.create({
      data: {
        ownerId: author.userId,
        storageKey: `issues-e2e/${randomUUID()}`,
        status: 'READY',
        mimeType: 'image/png',
        sizeBytes: 24,
        width: 1080,
        height: 1440,
      },
    });
    return prisma.issue.create({
      data: {
        authorId: author.userId,
        serviceDate: options.serviceDate ?? dateAt(-1),
        issueNumber: 1,
        colorId: options.colorId ?? 'sage',
        mediaId: media.id,
        caption: '어제의 기록',
        faceMode: 'PLAIN',
        publishedAt: options.publishedAt,
      },
    });
  }

  const auth = (token: string) => ({ Authorization: `Bearer ${token}` });

  // issues.get · 접근: user · 응답: IssuePublicDto | IssueOwnerDto · 계약: P01, P02, P18
  it('GET /api/issues/:id: 표지 펼쳐 보기(주인이면 숫자 포함) → 200', async () => {
    const owner = await signup('get-owner');
    const reader = await signup('get-reader');
    const issue = await createIssue(owner);
    await prisma.like.create({
      data: { userId: reader.userId, issueId: issue.id },
    });
    await prisma.scrap.create({
      data: { userId: reader.userId, issueId: issue.id },
    });

    const shown = await request(app.getHttpServer())
      .get(`/api/issues/${issue.id}`)
      .set(auth(reader.token))
      .expect(200);
    expect(shown.body).toMatchObject({
      id: issue.id,
      masthead: owner.masthead,
      issueNumber: 1,
      serviceDate: dateAt(-1).toISOString().slice(0, 10),
      caption: '어제의 기록',
      faceMode: 'PLAIN',
      liked: true,
      scrapped: true,
      media: { mimeType: 'image/png', width: 1080, height: 1440 },
    });
    expect(shown.body).not.toHaveProperty('likeCount');
    expect(shown.body).not.toHaveProperty('scrapCount');

    const owned = await request(app.getHttpServer())
      .get(`/api/issues/${issue.id}`)
      .set(auth(owner.token))
      .expect(200);
    expect(owned.body).toMatchObject({ likeCount: 1, scrapCount: 1 });
  });

  it('GET /api/issues/:id: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .get(`/api/issues/${randomUUID()}`)
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('GET /api/issues/:id: 없거나 나에게 잠긴 표지(P01) → 404 NOT_FOUND', async () => {
    const reader = await signup('locked-reader');
    const today = await request(app.getHttpServer())
      .get('/api/today')
      .set(auth(reader.token))
      .expect(200);
    const colorId = today.body.candidates[0].id as string;
    const oldestAuthor = await signup('locked-oldest');
    const oldest = await createIssue(oldestAuthor, {
      serviceDate: dateAt(0),
      colorId,
      publishedAt: new Date('2000-01-01T00:00:00.000Z'),
    });
    let newestId = '';
    for (let index = 0; index < 3; index += 1) {
      const author = await signup(`preview-${index}`);
      newestId = (
        await createIssue(author, {
          serviceDate: dateAt(0),
          colorId,
          publishedAt: new Date(`2099-01-0${index + 1}T00:00:00.000Z`),
        })
      ).id;
    }

    const locked = await request(app.getHttpServer())
      .get(`/api/issues/${oldest.id}`)
      .set(auth(reader.token))
      .expect(404);
    expect(locked.body.error.code).toBe('NOT_FOUND');
    await request(app.getHttpServer())
      .get(`/api/issues/${newestId}`)
      .set(auth(reader.token))
      .expect(200);

    await createIssue(reader, { serviceDate: dateAt(0), colorId });
    await request(app.getHttpServer())
      .get(`/api/issues/${oldest.id}`)
      .set(auth(reader.token))
      .expect(200);

    const missing = await request(app.getHttpServer())
      .get(`/api/issues/${randomUUID()}`)
      .set(auth(reader.token))
      .expect(404);
    expect(missing.body.error.code).toBe('NOT_FOUND');
  });

  it('합격 기준(P02): 오늘 비후보 색과 지난 날짜는 공개하고 미래 날짜는 숨김', async () => {
    const reader = await signup('p02-reader');
    const today = await request(app.getHttpServer())
      .get('/api/today')
      .set(auth(reader.token))
      .expect(200);
    const candidateIds = (today.body.candidates as { id: string }[]).map(
      ({ id }) => id,
    );
    const nonCandidate = await prisma.color.findFirstOrThrow({
      where: { id: { notIn: candidateIds } },
      select: { id: true },
    });
    const openAuthor = await signup('p02-open');
    const open = await createIssue(openAuthor, {
      serviceDate: dateAt(0),
      colorId: nonCandidate.id,
    });
    await request(app.getHttpServer())
      .get(`/api/issues/${open.id}`)
      .set(auth(reader.token))
      .expect(200);

    const futureAuthor = await signup('p02-future');
    const future = await createIssue(futureAuthor, {
      serviceDate: dateAt(1),
      colorId: nonCandidate.id,
    });
    const hidden = await request(app.getHttpServer())
      .get(`/api/issues/${future.id}`)
      .set(auth(reader.token))
      .expect(404);
    expect(hidden.body.error.code).toBe('NOT_FOUND');
  });

  // issues.like · 접근: user · 응답: ReactionStateDto · 계약: P01, P12, P18
  it('POST /api/issues/:id/like: 좋아요(두 번 보내도 한 번) → 201', async () => {
    const owner = await signup('like-owner');
    const reader = await signup('like-reader');
    const issue = await createIssue(owner);
    for (let attempt = 0; attempt < 2; attempt += 1) {
      const response = await request(app.getHttpServer())
        .post(`/api/issues/${issue.id}/like`)
        .set(auth(reader.token))
        .expect(201);
      expect(response.body).toEqual({ liked: true, scrapped: false });
    }
    expect(await prisma.like.count({ where: { issueId: issue.id } })).toBe(1);
  });

  it('POST /api/issues/:id/like: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .post(`/api/issues/${randomUUID()}/like`)
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('POST /api/issues/:id/like: 없거나 나에게 잠긴 표지(P01) → 404 NOT_FOUND', async () => {
    const reader = await signup('like-missing');
    const response = await request(app.getHttpServer())
      .post(`/api/issues/${randomUUID()}/like`)
      .set(auth(reader.token))
      .expect(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
  });

  // issues.unlike · 접근: user · 응답: ReactionStateDto · 계약: P01, P12
  it('DELETE /api/issues/:id/like: 좋아요 취소 → 200', async () => {
    const owner = await signup('unlike-owner');
    const reader = await signup('unlike-reader');
    const issue = await createIssue(owner);
    await prisma.like.create({
      data: { userId: reader.userId, issueId: issue.id },
    });
    for (let attempt = 0; attempt < 2; attempt += 1) {
      const response = await request(app.getHttpServer())
        .delete(`/api/issues/${issue.id}/like`)
        .set(auth(reader.token))
        .expect(200);
      expect(response.body).toEqual({ liked: false, scrapped: false });
    }
    expect(await prisma.like.count({ where: { issueId: issue.id } })).toBe(0);
  });

  it('DELETE /api/issues/:id/like: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .delete(`/api/issues/${randomUUID()}/like`)
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('DELETE /api/issues/:id/like: 없거나 나에게 잠긴 표지(P01) → 404 NOT_FOUND', async () => {
    const reader = await signup('unlike-missing');
    const response = await request(app.getHttpServer())
      .delete(`/api/issues/${randomUUID()}/like`)
      .set(auth(reader.token))
      .expect(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
  });

  // issues.scrap · 접근: user · 응답: ReactionStateDto · 계약: P01, P12, P18
  it('POST /api/issues/:id/scrap: 스크랩 → 201', async () => {
    const owner = await signup('scrap-owner');
    const reader = await signup('scrap-reader');
    const issue = await createIssue(owner);
    for (let attempt = 0; attempt < 2; attempt += 1) {
      const response = await request(app.getHttpServer())
        .post(`/api/issues/${issue.id}/scrap`)
        .set(auth(reader.token))
        .expect(201);
      expect(response.body).toEqual({ liked: false, scrapped: true });
    }
    expect(await prisma.scrap.count({ where: { issueId: issue.id } })).toBe(1);
  });

  it('POST /api/issues/:id/scrap: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .post(`/api/issues/${randomUUID()}/scrap`)
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('POST /api/issues/:id/scrap: 없거나 나에게 잠긴 표지(P01) → 404 NOT_FOUND', async () => {
    const reader = await signup('scrap-missing');
    const response = await request(app.getHttpServer())
      .post(`/api/issues/${randomUUID()}/scrap`)
      .set(auth(reader.token))
      .expect(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
  });

  // issues.unscrap · 접근: user · 응답: ReactionStateDto · 계약: P01, P12
  it('DELETE /api/issues/:id/scrap: 스크랩 취소 → 200', async () => {
    const owner = await signup('unscrap-owner');
    const reader = await signup('unscrap-reader');
    const issue = await createIssue(owner);
    await prisma.scrap.create({
      data: { userId: reader.userId, issueId: issue.id },
    });
    for (let attempt = 0; attempt < 2; attempt += 1) {
      const response = await request(app.getHttpServer())
        .delete(`/api/issues/${issue.id}/scrap`)
        .set(auth(reader.token))
        .expect(200);
      expect(response.body).toEqual({ liked: false, scrapped: false });
    }
    expect(await prisma.scrap.count({ where: { issueId: issue.id } })).toBe(0);
  });

  it('DELETE /api/issues/:id/scrap: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .delete(`/api/issues/${randomUUID()}/scrap`)
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('DELETE /api/issues/:id/scrap: 없거나 나에게 잠긴 표지(P01) → 404 NOT_FOUND', async () => {
    const reader = await signup('unscrap-missing');
    const response = await request(app.getHttpServer())
      .delete(`/api/issues/${randomUUID()}/scrap`)
      .set(auth(reader.token))
      .expect(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
  });

  // issues.lines · 접근: user · 응답: Page<ReaderLinePublicDto> · 계약: P01, P18
  it('GET /api/issues/:id/lines: 독자 한 줄 목록(개수 없이 cursor로) → 200', async () => {
    const owner = await signup('lines-owner');
    const reader = await signup('lines-reader');
    const issue = await createIssue(owner);
    await prisma.readerLine.createMany({
      data: Array.from({ length: 21 }, (_, index) => ({
        authorId: reader.userId,
        issueId: issue.id,
        text: `한 줄 ${index + 1}`,
        createdAt: new Date(2_000 + index),
      })),
    });

    const first = await request(app.getHttpServer())
      .get(`/api/issues/${issue.id}/lines`)
      .set(auth(reader.token))
      .expect(200);
    expect(first.body.items).toHaveLength(20);
    expect(first.body.nextCursor).toEqual(expect.any(String));
    expect(first.body).not.toHaveProperty('total');
    expect(first.body.items[0]).toMatchObject({
      authorMasthead: reader.masthead,
      text: '한 줄 21',
    });

    const second = await request(app.getHttpServer())
      .get(`/api/issues/${issue.id}/lines`)
      .query({ cursor: first.body.nextCursor })
      .set(auth(reader.token))
      .expect(200);
    expect(second.body.items).toHaveLength(1);
    expect(second.body.nextCursor).toBeNull();
    expect(second.body.items[0].text).toBe('한 줄 1');
  });

  it('GET /api/issues/:id/lines: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .get(`/api/issues/${randomUUID()}/lines`)
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('GET /api/issues/:id/lines: 없거나 나에게 잠긴 표지(P01) → 404 NOT_FOUND', async () => {
    const reader = await signup('lines-missing');
    const response = await request(app.getHttpServer())
      .get(`/api/issues/${randomUUID()}/lines`)
      .set(auth(reader.token))
      .expect(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
  });
  // issues.addLine · 접근: user · 응답: ReaderLinePublicDto · 계약: P01, P12
  it('POST /api/issues/:id/lines: 독자 한 줄 남기기(60자 이내) → 201', async () => {
    const owner = await signup('add-line-owner');
    const reader = await signup('add-line-reader');
    const issue = await createIssue(owner);
    const response = await request(app.getHttpServer())
      .post(`/api/issues/${issue.id}/lines`)
      .set(auth(reader.token))
      .send({ text: '  잘 읽었어요  ' })
      .expect(201);

    expect(response.body).toMatchObject({
      id: expect.any(String),
      authorMasthead: reader.masthead,
      text: '잘 읽었어요',
      createdAt: expect.any(String),
    });
  });

  it('POST /api/issues/:id/lines: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .post(`/api/issues/${randomUUID()}/lines`)
      .send({ text: '읽었어요' })
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('POST /api/issues/:id/lines: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION', async () => {
    const owner = await signup('invalid-line-owner');
    const reader = await signup('invalid-line-reader');
    const issue = await createIssue(owner);
    for (const text of ['', '   ', '가'.repeat(61)]) {
      const response = await request(app.getHttpServer())
        .post(`/api/issues/${issue.id}/lines`)
        .set(auth(reader.token))
        .send({ text })
        .expect(400);
      expect(response.body.error.code).toBe('VALIDATION');
    }
  });

  it('POST /api/issues/:id/lines: 없거나 나에게 잠긴 표지(P01) → 404 NOT_FOUND', async () => {
    const reader = await signup('add-line-missing');
    const response = await request(app.getHttpServer())
      .post(`/api/issues/${randomUUID()}/lines`)
      .set(auth(reader.token))
      .send({ text: '읽었어요' })
      .expect(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
  });

  it('POST /api/issues/:id/lines: 요청이 너무 많아요 → 429 RATE_LIMITED', async () => {
    const owner = await signup('limited-line-owner');
    const reader = await signup('limited-line-reader');
    const issue = await createIssue(owner);
    for (let index = 0; index < 5; index += 1) {
      await request(app.getHttpServer())
        .post(`/api/issues/${issue.id}/lines`)
        .set(auth(reader.token))
        .send({ text: `읽었어요 ${index}` })
        .expect(201);
    }
    const response = await request(app.getHttpServer())
      .post(`/api/issues/${issue.id}/lines`)
      .set(auth(reader.token))
      .send({ text: '여섯 번째' })
      .expect(429);
    expect(response.body.error.code).toBe('RATE_LIMITED');
  });
  it('합격 기준(P18): 남의 표지 응답에 반응 숫자 필드가 없음(주인이 부를 때만 IssueOwnerDto)', async () => {
    const owner = await signup('p18-owner');
    const reader = await signup('p18-reader');
    const issue = await createIssue(owner);
    const response = await request(app.getHttpServer())
      .get(`/api/issues/${issue.id}`)
      .set(auth(reader.token))
      .expect(200);
    expect(response.body).not.toHaveProperty('likeCount');
    expect(response.body).not.toHaveProperty('scrapCount');
  });

  it('합격 기준(P01): 잠긴 표지의 id로 펼침면·좋아요·스크랩·한 줄을 부르면 403이 아니라 404', async () => {
    const reader = await signup('p01-reader');
    const today = await request(app.getHttpServer())
      .get('/api/today')
      .set(auth(reader.token))
      .expect(200);
    const colorId = today.body.candidates[0].id as string;
    const owner = await signup('p01-owner');
    const locked = await createIssue(owner, {
      serviceDate: dateAt(0),
      colorId,
      publishedAt: new Date('2000-01-01T00:00:00.000Z'),
    });
    for (let index = 0; index < 3; index += 1) {
      const previewOwner = await signup(`p01-preview-${index}`);
      await createIssue(previewOwner, {
        serviceDate: dateAt(0),
        colorId,
        publishedAt: new Date(`2099-02-0${index + 1}T00:00:00.000Z`),
      });
    }
    const calls = [
      () => request(app.getHttpServer()).get(`/api/issues/${locked.id}`),
      () => request(app.getHttpServer()).post(`/api/issues/${locked.id}/like`),
      () =>
        request(app.getHttpServer()).delete(`/api/issues/${locked.id}/like`),
      () => request(app.getHttpServer()).post(`/api/issues/${locked.id}/scrap`),
      () =>
        request(app.getHttpServer()).delete(`/api/issues/${locked.id}/scrap`),
      () => request(app.getHttpServer()).get(`/api/issues/${locked.id}/lines`),
      () =>
        request(app.getHttpServer())
          .post(`/api/issues/${locked.id}/lines`)
          .send({ text: '숨겨진 호' }),
    ];
    for (const makeCall of calls) {
      const response = await makeCall().set(auth(reader.token)).expect(404);
      expect(response.body.error.code).toBe('NOT_FOUND');
    }
  });
  it('합격 기준: 한 줄은 60자 이내, 빈 줄 거절', async () => {
    const owner = await signup('line-rule-owner');
    const reader = await signup('line-rule-reader');
    const issue = await createIssue(owner);
    await request(app.getHttpServer())
      .post(`/api/issues/${issue.id}/lines`)
      .set(auth(reader.token))
      .send({ text: '가'.repeat(60) })
      .expect(201);
    await request(app.getHttpServer())
      .post(`/api/issues/${issue.id}/lines`)
      .set(auth(reader.token))
      .send({ text: ' ' })
      .expect(400);
  });
});
