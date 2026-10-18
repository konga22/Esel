import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { App } from 'supertest/types.js';
import { PrismaService } from '../../src/prisma/prisma.service.js';
import { createTestApp } from '../create-app.js';

describe('DEV-20 신고·차단·삭제', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let mastheadSequence = 0;

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
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
    };
    await prisma.profile.create({
      data: {
        userId: user.id,
        masthead: `mod${String.fromCharCode(97 + mastheadSequence++)}`,
      },
    });
    return user;
  }

  async function pastIssue(userId: string) {
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
        serviceDate: new Date('2020-01-01T00:00:00.000Z'),
        issueNumber: 1,
        colorId: 'sage',
        mediaId: media.id,
        caption: '신고 테스트',
        faceMode: 'PLAIN',
      },
    });
  }

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

  it.todo(
    'POST /api/users/:masthead/block: 사람 차단(그 사람의 표지·한 줄이 내 피드·가판대·서가에 안 나옴) → 201',
  );
  it.todo(
    'POST /api/users/:masthead/block: 로그인 없이 부르면 → 401 AUTH_REQUIRED',
  );
  it.todo('POST /api/users/:masthead/block: 없는 제호 → 404 NOT_FOUND');
  it.todo('DELETE /api/users/:masthead/block: 차단 풀기 → 200');
  it.todo(
    'DELETE /api/users/:masthead/block: 로그인 없이 부르면 → 401 AUTH_REQUIRED',
  );
  it.todo('DELETE /api/users/:masthead/block: 없는 제호 → 404 NOT_FOUND');
  it.todo(
    'GET /api/me/blocks: 내가 차단한 사람 목록(개수 없이 cursor로) → 200',
  );
  it.todo('GET /api/me/blocks: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo(
    'DELETE /api/issues/:id: 내 호 삭제(공개 응답·공유 링크·이미지 주소에서 모두 사라짐) → 204',
  );
  it.todo('DELETE /api/issues/:id: 로그인 없이 부르면 → 401 AUTH_REQUIRED');
  it.todo('DELETE /api/issues/:id: 남의 호 → 403 FORBIDDEN');
  it.todo('DELETE /api/issues/:id: 없거나 이미 지운 호 → 404 NOT_FOUND');
  it.todo(
    '합격 기준: 지운 호는 피드·팔레트·스케치북·자세히 보기·공유 링크·이미지 URL에서 모두 사라짐(404)',
  );
  it.todo(
    '합격 기준(P01): 호를 지우면 같은 색 방의 미리보기 3장과 hiddenCount를 다시 계산함',
  );
  it.todo(
    '합격 기준: 차단한 사람의 표지·독자 한 줄이 피드·팔레트·스케치북에 나오지 않음',
  );
});
