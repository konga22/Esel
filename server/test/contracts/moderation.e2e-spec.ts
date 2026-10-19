import { INestApplication } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { App } from 'supertest/types.js';
import { PrismaService } from '../../src/prisma/prisma.service.js';
import { serviceDate } from '../../src/common/service-date.js';
import { createTestApp } from '../create-app.js';

describe('DEV-20 신고·차단·삭제', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let mastheadSequence = 0;
  let timeZone: string;

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
    timeZone = app.get(ConfigService).getOrThrow<string>('SERVICE_TIME_ZONE');
    await cleanup();
  });
  afterEach(cleanup);
  afterAll(async () => app.close());

  async function cleanup() {
    await prisma.report.deleteMany({
      where: { reporter: { email: { endsWith: '@moderation.e2e.test' } } },
    });
    await prisma.issue.deleteMany({
      where: { author: { email: { endsWith: '@moderation.e2e.test' } } },
    });
    await prisma.user.deleteMany({
      where: { email: { endsWith: '@moderation.e2e.test' } },
    });
  }

  async function signup(label: string) {
    const response = await request(app.getHttpServer())
      .post('/api/auth/email/signup')
      .send({
        email: `${label}-${randomUUID()}@moderation.e2e.test`,
        password: 'correct horse battery staple',
      })
      .expect(201);
    const user = {
      id: response.body.userId as string,
      token: response.body.accessToken as string,
      masthead: nextMasthead(),
    };
    await prisma.profile.create({
      data: {
        userId: user.id,
        masthead: user.masthead,
      },
    });
    return user;
  }

  function nextMasthead(): string {
    let value = mastheadSequence++;
    let suffix = '';
    do {
      suffix = String.fromCharCode(97 + (value % 26)) + suffix;
      value = Math.floor(value / 26) - 1;
    } while (value >= 0);
    return `mod${suffix}`;
  }

  async function createIssue(
    userId: string,
    options: {
      date: Date;
      colorId?: string;
      publishedAt?: Date;
      issueNumber?: number;
    },
  ) {
    const media = await prisma.mediaAsset.create({
      data: {
        ownerId: userId,
        storageKey: `moderation/${randomUUID()}`,
        status: 'READY',
        mimeType: 'image/jpeg',
        sizeBytes: 24,
      },
    });
    return prisma.issue.create({
      data: {
        authorId: userId,
        serviceDate: options.date,
        issueNumber: options.issueNumber ?? 1,
        colorId: options.colorId ?? 'sage',
        mediaId: media.id,
        caption: '신고 테스트',
        faceCrop: 'ORIGINAL',
        paintStroke: false,
        publishedAt: options.publishedAt,
      },
    });
  }

  const pastIssue = (userId: string) =>
    createIssue(userId, { date: new Date('2020-01-01T00:00:00.000Z') });

  const auth = (token: string) => ({ Authorization: `Bearer ${token}` });
  const reportBody = { reason: 'spam', details: '반복 게시' };

  it('POST /api/issues/:id/reports: 표지 신고 → 201', async () => {
    const owner = await signup('issue-owner');
    const reporter = await signup('issue-reporter');
    const issue = await pastIssue(owner.id);
    const response = await request(app.getHttpServer())
      .post(`/api/issues/${issue.id}/reports`)
      .set(auth(reporter.token))
      .send(reportBody)
      .expect(201);
    expect(response.body).toEqual({
      id: expect.any(String),
      status: 'RECEIVED',
      createdAt: expect.any(String),
    });
    expect(await prisma.report.count({ where: { issueId: issue.id } })).toBe(1);
  });

  it('POST /api/issues/:id/reports: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .post(`/api/issues/${randomUUID()}/reports`)
      .send(reportBody)
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('POST /api/issues/:id/reports: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION', async () => {
    const reporter = await signup('issue-invalid');
    const response = await request(app.getHttpServer())
      .post(`/api/issues/${randomUUID()}/reports`)
      .set(auth(reporter.token))
      .send({ reason: 'unknown' })
      .expect(400);
    expect(response.body.error.code).toBe('VALIDATION');
  });

  it('POST /api/issues/:id/reports: 없거나 나에게 잠긴 표지(P01) → 404 NOT_FOUND', async () => {
    const reporter = await signup('issue-missing');
    const response = await request(app.getHttpServer())
      .post(`/api/issues/${randomUUID()}/reports`)
      .set(auth(reporter.token))
      .send(reportBody)
      .expect(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
  });

  it('POST /api/issues/:id/reports: 요청이 너무 많아요 → 429 RATE_LIMITED', async () => {
    const owner = await signup('rate-owner');
    const reporter = await signup('rate-reporter');
    const issue = await pastIssue(owner.id);
    for (let index = 0; index < 5; index += 1) {
      await request(app.getHttpServer())
        .post(`/api/issues/${issue.id}/reports`)
        .set(auth(reporter.token))
        .send(reportBody)
        .expect(201);
    }
    const response = await request(app.getHttpServer())
      .post(`/api/issues/${issue.id}/reports`)
      .set(auth(reporter.token))
      .send(reportBody)
      .expect(429);
    expect(response.body.error.code).toBe('RATE_LIMITED');
  });

  it('POST /api/issues/:id/lines/:lineId/reports: 독자 한 줄 신고 → 201', async () => {
    const owner = await signup('line-owner');
    const author = await signup('line-author');
    const reporter = await signup('line-reporter');
    const issue = await pastIssue(owner.id);
    const line = await prisma.readerLine.create({
      data: { authorId: author.id, issueId: issue.id, text: '신고 대상 한 줄' },
    });
    const response = await request(app.getHttpServer())
      .post(`/api/issues/${issue.id}/lines/${line.id}/reports`)
      .set(auth(reporter.token))
      .send({ reason: 'harassment' })
      .expect(201);
    expect(response.body).toMatchObject({ status: 'RECEIVED' });
    expect(await prisma.report.count({ where: { lineId: line.id } })).toBe(1);
  });

  it('POST /api/issues/:id/lines/:lineId/reports: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .post(`/api/issues/${randomUUID()}/lines/${randomUUID()}/reports`)
      .send(reportBody)
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('POST /api/issues/:id/lines/:lineId/reports: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION', async () => {
    const reporter = await signup('line-invalid');
    const response = await request(app.getHttpServer())
      .post(`/api/issues/${randomUUID()}/lines/${randomUUID()}/reports`)
      .set(auth(reporter.token))
      .send({})
      .expect(400);
    expect(response.body.error.code).toBe('VALIDATION');
  });

  it('POST /api/issues/:id/lines/:lineId/reports: 없는 한 줄이거나 나에게 잠긴 표지(P01) → 404 NOT_FOUND', async () => {
    const owner = await signup('line-missing-owner');
    const reporter = await signup('line-missing-reporter');
    const issue = await pastIssue(owner.id);
    const response = await request(app.getHttpServer())
      .post(`/api/issues/${issue.id}/lines/${randomUUID()}/reports`)
      .set(auth(reporter.token))
      .send(reportBody)
      .expect(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
  });

  // 신고 두 API는 같은 사용자 기준 분당 5회 제한을 공유한다.
  it('POST /api/issues/:id/lines/:lineId/reports: 요청이 너무 많아요 → 429 RATE_LIMITED', async () => {
    const owner = await signup('line-rate-owner');
    const reporter = await signup('line-rate-reporter');
    const issue = await pastIssue(owner.id);
    const line = await prisma.readerLine.create({
      data: { authorId: owner.id, issueId: issue.id, text: '도배 한 줄' },
    });
    for (let index = 0; index < 5; index += 1) {
      await request(app.getHttpServer())
        .post(`/api/issues/${issue.id}/lines/${line.id}/reports`)
        .set(auth(reporter.token))
        .send(reportBody)
        .expect(201);
    }
    const response = await request(app.getHttpServer())
      .post(`/api/issues/${issue.id}/lines/${line.id}/reports`)
      .set(auth(reporter.token))
      .send(reportBody)
      .expect(429);
    expect(response.body.error.code).toBe('RATE_LIMITED');
  });

  it('POST /api/users/:masthead/block: 사람 차단(그 사람의 표지·한 줄이 내 피드·가판대·서가에 안 나옴) → 201', async () => {
    const viewer = await signup('block-viewer');
    const target = await signup('block-target');
    const response = await request(app.getHttpServer())
      .post(`/api/users/${target.masthead}/block`)
      .set(auth(viewer.token))
      .expect(201);
    expect(response.body).toEqual({ masthead: target.masthead, blocked: true });
  });

  it('POST /api/users/:masthead/block: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/users/missing/block')
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('POST /api/users/:masthead/block: 없는 제호 → 404 NOT_FOUND', async () => {
    const viewer = await signup('block-missing');
    const response = await request(app.getHttpServer())
      .post('/api/users/noonehere/block')
      .set(auth(viewer.token))
      .expect(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
  });

  it('DELETE /api/users/:masthead/block: 차단 풀기 → 200', async () => {
    const viewer = await signup('unblock-viewer');
    const target = await signup('unblock-target');
    await request(app.getHttpServer())
      .post(`/api/users/${target.masthead}/block`)
      .set(auth(viewer.token))
      .expect(201);
    const response = await request(app.getHttpServer())
      .delete(`/api/users/${target.masthead}/block`)
      .set(auth(viewer.token))
      .expect(200);
    expect(response.body).toEqual({
      masthead: target.masthead,
      blocked: false,
    });
  });

  it('DELETE /api/users/:masthead/block: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .delete('/api/users/missing/block')
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('DELETE /api/users/:masthead/block: 없는 제호 → 404 NOT_FOUND', async () => {
    const viewer = await signup('unblock-missing');
    const response = await request(app.getHttpServer())
      .delete('/api/users/noonehere/block')
      .set(auth(viewer.token))
      .expect(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
  });

  it('GET /api/me/blocks: 내가 차단한 사람 목록(개수 없이 cursor로) → 200', async () => {
    const viewer = await signup('blocks-viewer');
    const target = await signup('blocks-target');
    await request(app.getHttpServer())
      .post(`/api/users/${target.masthead}/block`)
      .set(auth(viewer.token))
      .expect(201);
    const response = await request(app.getHttpServer())
      .get('/api/me/blocks')
      .set(auth(viewer.token))
      .expect(200);
    expect(response.body).toEqual({
      items: [{ masthead: target.masthead, blockedAt: expect.any(String) }],
      nextCursor: null,
    });
    expect(JSON.stringify(response.body)).not.toMatch(/count|userId/i);
  });

  it('GET /api/me/blocks: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/me/blocks')
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('DELETE /api/issues/:id: 내 호 삭제(공개 응답·공유 링크·이미지 주소에서 모두 사라짐) → 204', async () => {
    const owner = await signup('delete-owner');
    const target = await pastIssue(owner.id);
    const link = await request(app.getHttpServer())
      .post('/api/share-links')
      .set(auth(owner.token))
      .send({ issueId: target.id })
      .expect(201);
    await request(app.getHttpServer())
      .delete(`/api/issues/${target.id}`)
      .set(auth(owner.token))
      .expect(204);
    expect(
      await prisma.issue.findUnique({ where: { id: target.id } }),
    ).toMatchObject({ deletedAt: expect.any(Date) });
    await request(app.getHttpServer())
      .get(`/api/issues/${target.id}`)
      .set(auth(owner.token))
      .expect(404);
    await request(app.getHttpServer())
      .get(`/api/share-links/${link.body.token}`)
      .expect(404);
    await request(app.getHttpServer())
      .get(`/api/media/${target.mediaId}`)
      .set(auth(owner.token))
      .expect(404);
    const feed = await request(app.getHttpServer())
      .get('/api/feed')
      .set(auth(owner.token))
      .expect(200);
    expect(feed.body.items.map(({ id }: { id: string }) => id)).not.toContain(
      target.id,
    );
    const stand = await request(app.getHttpServer())
      .get('/api/stand')
      .query({ colorId: 'sage', date: '2020-01-01' })
      .set(auth(owner.token))
      .expect(200);
    expect(stand.body.items.map(({ id }: { id: string }) => id)).not.toContain(
      target.id,
    );
    const magazine = await request(app.getHttpServer())
      .get('/api/me/magazine')
      .set(auth(owner.token))
      .expect(200);
    expect(
      magazine.body.pastIssues.map(({ id }: { id: string }) => id),
    ).not.toContain(target.id);
  });

  it('DELETE /api/issues/:id: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .delete(`/api/issues/${randomUUID()}`)
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('DELETE /api/issues/:id: 남의 호 → 403 FORBIDDEN', async () => {
    const owner = await signup('delete-other-owner');
    const other = await signup('delete-other-user');
    const target = await pastIssue(owner.id);
    const response = await request(app.getHttpServer())
      .delete(`/api/issues/${target.id}`)
      .set(auth(other.token))
      .expect(403);
    expect(response.body.error.code).toBe('FORBIDDEN');
  });

  it('DELETE /api/issues/:id: 없거나 이미 지운 호 → 404 NOT_FOUND', async () => {
    const owner = await signup('delete-missing');
    const target = await pastIssue(owner.id);
    await request(app.getHttpServer())
      .delete(`/api/issues/${target.id}`)
      .set(auth(owner.token))
      .expect(204);
    for (const id of [target.id, randomUUID()]) {
      const response = await request(app.getHttpServer())
        .delete(`/api/issues/${id}`)
        .set(auth(owner.token))
        .expect(404);
      expect(response.body.error.code).toBe('NOT_FOUND');
    }
  });

  it('합격 기준(P01): 호를 지우면 같은 색 방의 미리보기 3장과 hiddenCount를 다시 계산함', async () => {
    const viewer = await signup('recalculate-viewer');
    const today = await request(app.getHttpServer())
      .get('/api/today')
      .set(auth(viewer.token))
      .expect(200);
    const colorId = today.body.candidates[0].id as string;
    const date = new Date(`${serviceDate(new Date(), timeZone)}T00:00:00.000Z`);
    const authors = [];
    const issues = [];
    for (let index = 0; index < 4; index += 1) {
      const author = await signup(`recalculate-author-${index}`);
      authors.push(author);
      issues.push(
        await createIssue(author.id, {
          date,
          colorId,
          publishedAt: new Date(10_000 + index),
        }),
      );
    }
    const before = await request(app.getHttpServer())
      .get('/api/stand')
      .query({ colorId })
      .set(auth(viewer.token))
      .expect(200);
    expect(before.body.hiddenCount).toBe(1);
    await request(app.getHttpServer())
      .delete(`/api/issues/${issues[3]!.id}`)
      .set(auth(authors[3]!.token))
      .expect(204);
    const after = await request(app.getHttpServer())
      .get('/api/stand')
      .query({ colorId })
      .set(auth(viewer.token))
      .expect(200);
    expect(after.body.hiddenCount).toBe(0);
    expect(after.body.items.map(({ id }: { id: string }) => id)).toContain(
      issues[0]!.id,
    );
  });

  it('합격 기준: 차단한 사람의 표지·독자 한 줄이 피드·팔레트·스케치북에 나오지 않음', async () => {
    const viewer = await signup('visibility-viewer');
    const target = await signup('visibility-target');
    const owner = await signup('visibility-owner');
    const targetIssue = await pastIssue(target.id);
    const ownerIssue = await pastIssue(owner.id);
    const line = await prisma.readerLine.create({
      data: {
        authorId: target.id,
        issueId: ownerIssue.id,
        text: '차단하면 숨겨질 한 줄',
      },
    });
    await request(app.getHttpServer())
      .post(`/api/users/${target.masthead}/block`)
      .set(auth(viewer.token))
      .expect(201);
    const feed = await request(app.getHttpServer())
      .get('/api/feed')
      .set(auth(viewer.token))
      .expect(200);
    expect(feed.body.items.map(({ id }: { id: string }) => id)).not.toContain(
      targetIssue.id,
    );
    const stand = await request(app.getHttpServer())
      .get('/api/stand')
      .query({ colorId: 'sage', date: '2020-01-01' })
      .set(auth(viewer.token))
      .expect(200);
    expect(stand.body.items.map(({ id }: { id: string }) => id)).not.toContain(
      targetIssue.id,
    );
    const magazine = await request(app.getHttpServer())
      .get(`/api/magazines/${target.masthead}`)
      .set(auth(viewer.token))
      .expect(200);
    expect(magazine.body.issues).toEqual([]);
    const lines = await request(app.getHttpServer())
      .get(`/api/issues/${ownerIssue.id}/lines`)
      .set(auth(viewer.token))
      .expect(200);
    expect(lines.body.items.map(({ id }: { id: string }) => id)).not.toContain(
      line.id,
    );
  });
});
