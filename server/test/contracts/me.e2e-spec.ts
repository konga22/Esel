import { INestApplication } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { App } from 'supertest/types.js';
import { serviceDate } from '../../src/common/service-date.js';
import { PrismaService } from '../../src/prisma/prisma.service.js';
import { dailyCandidateIds } from '../../src/today/today.rules.js';
import { createTestApp } from '../create-app.js';

describe('DEV-14 내 잡지와 반응', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let timeZone: string;
  let sequence = 0;

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
    timeZone = app.get(ConfigService).getOrThrow<string>('SERVICE_TIME_ZONE');
    await cleanup();
  });
  afterEach(cleanup);
  afterAll(async () => app.close());

  async function cleanup() {
    await prisma.issue.deleteMany({
      where: { author: { email: { endsWith: '@me.e2e.test' } } },
    });
    await prisma.user.deleteMany({
      where: { email: { endsWith: '@me.e2e.test' } },
    });
  }

  async function signup(label: string) {
    const response = await request(app.getHttpServer())
      .post('/api/auth/email/signup')
      .send({
        email: `${label}-${randomUUID()}@me.e2e.test`,
        password: 'correct horse battery staple',
      })
      .expect(201);
    const user = {
      userId: response.body.userId as string,
      token: response.body.accessToken as string,
      masthead: `mine${String.fromCharCode(97 + sequence++)}`,
    };
    await prisma.profile.create({
      data: { userId: user.userId, masthead: user.masthead },
    });
    return user;
  }

  function dateAt(offset: number) {
    const key = serviceDate(new Date(), timeZone);
    const date = new Date(`${key}T00:00:00.000Z`);
    date.setUTCDate(date.getUTCDate() + offset);
    return date;
  }

  async function createIssue(
    owner: { userId: string },
    offset = -1,
    colorId = 'sage',
    issueNumber = offset === 0 ? 2 : offset > 0 ? 3 : 1,
  ) {
    const media = await prisma.mediaAsset.create({
      data: {
        ownerId: owner.userId,
        storageKey: `me-e2e/${randomUUID()}`,
        status: 'READY',
        mimeType: 'image/png',
        sizeBytes: 24,
      },
    });
    return prisma.issue.create({
      data: {
        authorId: owner.userId,
        serviceDate: dateAt(offset),
        issueNumber,
        colorId,
        mediaId: media.id,
        caption: '내 잡지',
        faceCrop: 'ORIGINAL',
        paintStroke: false,
      },
    });
  }

  const auth = (token: string) => ({ Authorization: `Bearer ${token}` });

  it('GET /api/me/magazine: 내 잡지(오늘 호, 지난 호, 나만 보는 숫자) → 200', async () => {
    const owner = await signup('magazine');
    const reader = await signup('reader');
    const past = await createIssue(owner);
    const today = await createIssue(owner, 0);
    await prisma.profile.update({
      where: { userId: owner.userId },
      data: { issueCount: 2 },
    });
    await prisma.like.create({
      data: { userId: reader.userId, issueId: past.id },
    });
    await prisma.readerLine.create({
      data: { authorId: reader.userId, issueId: past.id, text: '좋아요' },
    });

    const response = await request(app.getHttpServer())
      .get('/api/me/magazine')
      .set(auth(owner.token))
      .expect(200);
    expect(response.body).toMatchObject({
      masthead: owner.masthead,
      issueCount: 2,
      todayIssue: { id: today.id, likeCount: 0, scrapCount: 0, lineCount: 0 },
      pastIssues: [{ id: past.id, likeCount: 1, scrapCount: 0, lineCount: 1 }],
      nextCursor: null,
    });
  });

  it('GET /api/me/magazine: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/me/magazine')
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('GET /api/me/issues/:id/reactions: 내 표지의 반응 수와 목록 → 200', async () => {
    const owner = await signup('reactions-owner');
    const reader = await signup('reactions-reader');
    const issue = await createIssue(owner);
    await prisma.like.create({
      data: { userId: reader.userId, issueId: issue.id },
    });
    await prisma.scrap.create({
      data: { userId: reader.userId, issueId: issue.id },
    });
    const line = await prisma.readerLine.create({
      data: { authorId: reader.userId, issueId: issue.id, text: '한 줄' },
    });

    const response = await request(app.getHttpServer())
      .get(`/api/me/issues/${issue.id}/reactions`)
      .set(auth(owner.token))
      .expect(200);
    expect(response.body).toMatchObject({
      issueId: issue.id,
      likeCount: 1,
      scrapCount: 1,
      lineCount: 1,
      likes: [{ masthead: reader.masthead }],
      scraps: [{ masthead: reader.masthead }],
      lines: [{ id: line.id, authorMasthead: reader.masthead, text: '한 줄' }],
    });
  });

  it('GET /api/me/issues/:id/reactions: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .get(`/api/me/issues/${randomUUID()}/reactions`)
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('GET /api/me/issues/:id/reactions: 남의 표지(나에게 보이는 것) → 403 FORBIDDEN', async () => {
    const owner = await signup('forbidden-owner');
    const reader = await signup('forbidden-reader');
    const issue = await createIssue(owner);
    const response = await request(app.getHttpServer())
      .get(`/api/me/issues/${issue.id}/reactions`)
      .set(auth(reader.token))
      .expect(403);
    expect(response.body.error.code).toBe('FORBIDDEN');
  });

  it('GET /api/me/issues/:id/reactions: 없거나 나에게 잠긴 표지(P01) → 404 NOT_FOUND', async () => {
    const owner = await signup('hidden-owner');
    const reader = await signup('hidden-reader');
    const future = await createIssue(owner, 1);
    for (const id of [future.id, randomUUID()]) {
      const response = await request(app.getHttpServer())
        .get(`/api/me/issues/${id}/reactions`)
        .set(auth(reader.token))
        .expect(404);
      expect(response.body.error.code).toBe('NOT_FOUND');
    }
  });

  it('합격 기준: 남의 표지 id로 reactions를 부르면 403, 나에게 잠긴 표지면 404', async () => {
    const owner = await signup('criteria-owner');
    const reader = await signup('criteria-reader');
    const visible = await createIssue(owner, -1);
    const hidden = await createIssue(owner, 1);
    await request(app.getHttpServer())
      .get(`/api/me/issues/${visible.id}/reactions`)
      .set(auth(reader.token))
      .expect(403);
    await request(app.getHttpServer())
      .get(`/api/me/issues/${hidden.id}/reactions`)
      .set(auth(reader.token))
      .expect(404);
  });

  it('합격 기준(P18): 반응 숫자는 소유자 응답(…OwnerDto)에만 있음', async () => {
    const owner = await signup('p18-owner');
    const reader = await signup('p18-reader');
    const issue = await createIssue(owner);
    const publicIssue = await request(app.getHttpServer())
      .get(`/api/issues/${issue.id}`)
      .set(auth(reader.token))
      .expect(200);
    expect(publicIssue.body).not.toHaveProperty('likeCount');
    expect(publicIssue.body).not.toHaveProperty('lineCount');
    const ownerIssue = await request(app.getHttpServer())
      .get(`/api/issues/${issue.id}`)
      .set(auth(owner.token))
      .expect(200);
    expect(ownerIssue.body).toMatchObject({
      likeCount: 0,
      scrapCount: 0,
      lineCount: 0,
    });
  });
  it('GET /api/me/scraps: 저장함: 내가 저장한 캔버스 목록(cursor, 나에게만) → 200', async () => {
    const reader = await signup('scraps-page-reader');
    const issues = [
      await createIssue(reader, 1, 'sage', 1),
      await createIssue(reader, 2, 'sage', 2),
    ];
    const base = Date.now() - 60_000;
    const scraps = await Promise.all(
      issues.map((issue, index) =>
        prisma.scrap.create({
          data: {
            userId: reader.userId,
            issueId: issue.id,
            createdAt: new Date(base + index * 1_000),
          },
        }),
      ),
    );

    const first = await request(app.getHttpServer())
      .get('/api/me/scraps')
      .set(auth(reader.token))
      .expect(200);
    expect(first.body).toMatchObject({
      items: [
        { id: issues[1].id, scrapped: true },
        { id: issues[0].id, scrapped: true },
      ],
      nextCursor: null,
    });
    const cursor = Buffer.from(
      JSON.stringify({
        createdAt: scraps[1].createdAt.toISOString(),
        issueId: scraps[1].issueId,
      }),
    ).toString('base64url');

    const second = await request(app.getHttpServer())
      .get('/api/me/scraps')
      .query({ cursor })
      .set(auth(reader.token))
      .expect(200);
    expect(second.body).toMatchObject({
      items: [{ id: issues[0].id, scrapped: true }],
      nextCursor: null,
    });
  });

  it('GET /api/me/scraps: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/me/scraps')
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('GET /api/me/scraps: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION', async () => {
    const reader = await signup('scraps-invalid-cursor');
    const response = await request(app.getHttpServer())
      .get('/api/me/scraps')
      .query({ cursor: 'not-a-cursor' })
      .set(auth(reader.token))
      .expect(400);
    expect(response.body.error).toMatchObject({
      code: 'VALIDATION',
      details: { cursor: expect.any(Array) },
    });
  });

  it('합격 기준(P01): 저장함에는 지금 볼 수 있는 캔버스만 옴(올리기 전 내 후보 색 캔버스·삭제·차단은 빠짐)', async () => {
    const reader = await signup('scraps-visible-reader');
    const visibleOwner = await signup('scraps-visible-owner');
    const deletedOwner = await signup('scraps-deleted-owner');
    const blockedOwner = await signup('scraps-blocked-owner');
    const todayOwners = await Promise.all(
      Array.from({ length: 4 }, (_, index) =>
        signup(`scraps-today-owner-${index}`),
      ),
    );
    const palette = await prisma.dailyPalette.findUnique({
      where: { serviceDate: dateAt(0) },
      select: { colors: { orderBy: { position: 'asc' } } },
    });
    const candidateColorId =
      palette?.colors[0]?.colorId ??
      dailyCandidateIds(
        serviceDate(new Date(), timeZone),
        (
          await prisma.color.findMany({
            orderBy: { sortOrder: 'asc' },
            select: { id: true },
          })
        ).map(({ id }) => id),
      )[0];
    if (!candidateColorId) throw new Error('후보 색이 필요합니다.');
    const visible = await createIssue(visibleOwner);
    const deleted = await createIssue(deletedOwner);
    const blocked = await createIssue(blockedOwner);
    const todayIssues = [];
    for (let index = 0; index < todayOwners.length; index += 1) {
      const issue = await createIssue(todayOwners[index], 0, candidateColorId);
      todayIssues.push(issue);
      await prisma.issue.update({
        where: { id: issue.id },
        data: { publishedAt: new Date(Date.now() - index * 1_000) },
      });
    }
    await prisma.issue.update({
      where: { id: deleted.id },
      data: { deletedAt: new Date() },
    });
    await prisma.block.create({
      data: { blockerId: reader.userId, blockedId: blockedOwner.userId },
    });
    await prisma.scrap.createMany({
      data: [visible.id, deleted.id, blocked.id, todayIssues[3].id].map(
        (issueId, index) => ({
          userId: reader.userId,
          issueId,
          createdAt: new Date(Date.now() + index * 1_000),
        }),
      ),
    });

    const response = await request(app.getHttpServer())
      .get('/api/me/scraps')
      .set(auth(reader.token))
      .expect(200);
    expect(response.body).toMatchObject({
      items: [{ id: visible.id }],
      nextCursor: null,
    });
  });

  it('합격 기준(P18): 저장함 응답에 반응 숫자가 없음', async () => {
    const reader = await signup('scraps-p18-reader');
    const owner = await signup('scraps-p18-owner');
    const issue = await createIssue(owner);
    await prisma.scrap.create({
      data: { userId: reader.userId, issueId: issue.id },
    });
    await prisma.like.create({
      data: { userId: reader.userId, issueId: issue.id },
    });

    const response = await request(app.getHttpServer())
      .get('/api/me/scraps')
      .set(auth(reader.token))
      .expect(200);
    expect(response.body.items[0]).not.toHaveProperty('likeCount');
    expect(response.body.items[0]).not.toHaveProperty('scrapCount');
    expect(response.body.items[0]).not.toHaveProperty('lineCount');
  });
});
