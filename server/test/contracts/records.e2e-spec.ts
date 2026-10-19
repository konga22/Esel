import { INestApplication } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { App } from 'supertest/types.js';
import { vi } from 'vitest';
import { serviceDate } from '../../src/common/service-date.js';
import { PrismaService } from '../../src/prisma/prisma.service.js';
import { dailyCandidateIds } from '../../src/today/today.rules.js';
import { createTestApp } from '../create-app.js';
import { createLockedIssuePerCandidate } from '../p01-fixtures.js';

describe('DEV-15 월간 색 기록과 복원', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let timeZone: string;
  let sequence = 0;

  beforeAll(async () => {
    vi.setSystemTime(new Date('2026-10-18T12:00:00.000Z'));
    app = await createTestApp();
    prisma = app.get(PrismaService);
    timeZone = app.get(ConfigService).getOrThrow<string>('SERVICE_TIME_ZONE');
    await cleanup();
  });
  afterEach(cleanup);
  afterAll(async () => {
    await app.close();
    vi.useRealTimers();
  });

  async function cleanup() {
    await prisma.issue.deleteMany({
      where: { author: { email: { endsWith: '@records.e2e.test' } } },
    });
    await prisma.user.deleteMany({
      where: { email: { endsWith: '@records.e2e.test' } },
    });
  }

  async function signup(label: string) {
    const response = await request(app.getHttpServer())
      .post('/api/auth/email/signup')
      .send({
        email: `${label}-${randomUUID()}@records.e2e.test`,
        password: 'correct horse battery staple',
      })
      .expect(201);
    const user = {
      userId: response.body.userId as string,
      token: response.body.accessToken as string,
      masthead: `record${String.fromCharCode(97 + sequence++)}`,
    };
    await prisma.profile.create({
      data: { userId: user.userId, masthead: user.masthead },
    });
    return user;
  }

  function keyAt(offset: number): string {
    const today = new Date(
      `${serviceDate(new Date(), timeZone)}T00:00:00.000Z`,
    );
    today.setUTCDate(today.getUTCDate() + offset);
    return today.toISOString().slice(0, 10);
  }

  async function candidate(dateKey: string): Promise<string> {
    const colors = await prisma.color.findMany({
      orderBy: { sortOrder: 'asc' },
      select: { id: true },
    });
    return dailyCandidateIds(
      dateKey,
      colors.map(({ id }) => id),
    )[0]!;
  }

  async function createIssue(userId: string, dateKey: string) {
    const media = await prisma.mediaAsset.create({
      data: {
        ownerId: userId,
        storageKey: `records-e2e/${randomUUID()}`,
        status: 'READY',
        mimeType: 'image/png',
        sizeBytes: 24,
      },
    });
    return prisma.issue.create({
      data: {
        authorId: userId,
        serviceDate: new Date(`${dateKey}T00:00:00.000Z`),
        issueNumber: 1,
        colorId: await candidate(dateKey),
        mediaId: media.id,
        caption: '사진 기록',
        faceCrop: 'ORIGINAL',
        paintStroke: false,
      },
    });
  }

  const auth = (token: string) => ({ Authorization: `Bearer ${token}` });

  async function restore(token: string, dateKey: string, status = 201) {
    return request(app.getHttpServer())
      .post(`/api/me/records/${dateKey}/restore`)
      .set(auth(token))
      .send({ colorId: await candidate(dateKey) })
      .expect(status);
  }

  it('GET /api/me/records: 한 달 색 기록(사진 기록과 색 복원 구분) → 200', async () => {
    const user = await signup('month');
    const issueDate = keyAt(-1);
    const restoredDate = keyAt(-2);
    const issue = await createIssue(user.userId, issueDate);
    await restore(user.token, restoredDate);
    const month = issueDate.slice(0, 7);

    const response = await request(app.getHttpServer())
      .get('/api/me/records')
      .query({ month })
      .set(auth(user.token))
      .expect(200);
    expect(response.body).toMatchObject({ month, remainingRestores: 1 });
    expect(response.body.days).toEqual([
      expect.objectContaining({
        serviceDate: restoredDate,
        kind: 'RESTORED',
        media: null,
      }),
      expect.objectContaining({
        serviceDate: issueDate,
        kind: 'ISSUE',
        issueId: issue.id,
      }),
    ]);
  });

  it('GET /api/me/records: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/me/records')
      .query({ month: keyAt(-1).slice(0, 7) })
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('GET /api/me/records: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION', async () => {
    const user = await signup('invalid-month');
    const response = await request(app.getHttpServer())
      .get('/api/me/records')
      .query({ month: '2026-99' })
      .set(auth(user.token))
      .expect(400);
    expect(response.body.error.code).toBe('VALIDATION');
  });

  it('POST /api/me/records/:date/restore: 지난 빈 날의 색 복원(월 2회) → 201', async () => {
    const user = await signup('restore');
    const dateKey = keyAt(-1);
    const response = await restore(user.token, dateKey);
    expect(response.body).toMatchObject({
      serviceDate: dateKey,
      kind: 'RESTORED',
      issueId: null,
      media: null,
    });
  });

  it('동시에 5개 날짜를 복원해도 201 또는 409만 응답하고 두 번만 저장', async () => {
    const user = await signup('concurrent');
    const dateKeys = [-1, -2, -3, -4, -5].map(keyAt);
    const colorIds = await Promise.all(dateKeys.map(candidate));
    const responses = await Promise.all(
      dateKeys.map((dateKey, index) =>
        request(app.getHttpServer())
          .post(`/api/me/records/${dateKey}/restore`)
          .set(auth(user.token))
          .send({ colorId: colorIds[index] }),
      ),
    );

    expect(
      responses.every(({ status }) => status === 201 || status === 409),
    ).toBe(true);
    expect(responses.filter(({ status }) => status === 201)).toHaveLength(2);
    for (const response of responses.filter(({ status }) => status === 409)) {
      expect(response.body.error.code).toBe('RESTORE_LIMIT');
    }
    expect(
      await prisma.restoredColor.count({ where: { userId: user.userId } }),
    ).toBe(2);
  });

  it('POST /api/me/records/:date/restore: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const dateKey = keyAt(-1);
    const response = await request(app.getHttpServer())
      .post(`/api/me/records/${dateKey}/restore`)
      .send({ colorId: await candidate(dateKey) })
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('POST /api/me/records/:date/restore: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION', async () => {
    const user = await signup('invalid-restore');
    const response = await request(app.getHttpServer())
      .post(`/api/me/records/${keyAt(-1)}/restore`)
      .set(auth(user.token))
      .send({ colorId: 'INVALID!' })
      .expect(400);
    expect(response.body.error.code).toBe('VALIDATION');
  });

  it('POST /api/me/records/:date/restore: 이번 달 복원 기회를 모두 썼어요 → 409 RESTORE_LIMIT', async () => {
    const user = await signup('limit');
    await restore(user.token, keyAt(-1));
    await restore(user.token, keyAt(-2));
    const response = await restore(user.token, keyAt(-3), 409);
    expect(response.body.error.code).toBe('RESTORE_LIMIT');
  });

  it('POST /api/me/records/:date/restore: 오늘 후보에 없는 색이에요 → 422 COLOR_NOT_CANDIDATE', async () => {
    const user = await signup('candidate');
    const dateKey = keyAt(-1);
    const candidates = dailyCandidateIds(
      dateKey,
      (await prisma.color.findMany({ orderBy: { sortOrder: 'asc' } })).map(
        ({ id }) => id,
      ),
    );
    const other = await prisma.color.findFirstOrThrow({
      where: { id: { notIn: candidates } },
    });
    const response = await request(app.getHttpServer())
      .post(`/api/me/records/${dateKey}/restore`)
      .set(auth(user.token))
      .send({ colorId: other.id })
      .expect(422);
    expect(response.body.error.code).toBe('COLOR_NOT_CANDIDATE');
  });

  it('POST /api/me/records/:date/restore: 이 날짜는 복원할 수 없어요 → 422 RESTORE_NOT_ALLOWED', async () => {
    const user = await signup('not-allowed');
    const dateKey = keyAt(0);
    const response = await restore(user.token, dateKey, 422);
    expect(response.body.error.code).toBe('RESTORE_NOT_ALLOWED');
  });

  it('합격 기준(P06): 오늘·미래·다른 달·이미 기록된 날 복원은 거절', async () => {
    const user = await signup('p06');
    const occupied = keyAt(-1);
    await createIssue(user.userId, occupied);
    const previousMonth = new Date(`${keyAt(0)}T00:00:00.000Z`);
    previousMonth.setUTCMonth(previousMonth.getUTCMonth() - 1, 15);
    const blockedDates = [
      keyAt(0),
      keyAt(1),
      previousMonth.toISOString().slice(0, 10),
      occupied,
    ];
    for (const dateKey of blockedDates) {
      const response = await restore(user.token, dateKey, 422);
      expect(response.body.error.code).toBe('RESTORE_NOT_ALLOWED');
    }
  });

  it('합격 기준: 세 번째 복원은 거절', async () => {
    const user = await signup('third');
    await restore(user.token, keyAt(-1));
    await restore(user.token, keyAt(-2));
    await restore(user.token, keyAt(-3), 409);
    expect(
      await prisma.restoredColor.count({ where: { userId: user.userId } }),
    ).toBe(2);
  });

  it('합격 기준(P07): 복원으로 issue_count가 바뀌지 않음', async () => {
    const user = await signup('p07');
    await restore(user.token, keyAt(-1));
    const profile = await prisma.profile.findUniqueOrThrow({
      where: { userId: user.userId },
    });
    expect(profile.issueCount).toBe(0);
    expect(await prisma.issue.count({ where: { authorId: user.userId } })).toBe(
      0,
    );
  });

  it('합격 기준(P01·P03): 복원해도 같은 색 방이 열리지 않음', async () => {
    const user = await signup('p01-p03');
    const todayKey = keyAt(0);
    const colors = await prisma.color.findMany({
      orderBy: { sortOrder: 'asc' },
      select: { id: true },
    });
    const candidateIds = dailyCandidateIds(
      todayKey,
      colors.map(({ id }) => id),
    );
    const lockedIssueIds = await createLockedIssuePerCandidate(
      prisma,
      candidateIds,
      todayKey,
      'records.e2e.test',
      'records-p01',
    );

    await restore(user.token, keyAt(-1));
    for (const issueId of lockedIssueIds) {
      const response = await request(app.getHttpServer())
        .get(`/api/issues/${issueId}`)
        .set(auth(user.token))
        .expect(404);
      expect(response.body.error.code).toBe('NOT_FOUND');
    }
  });
});
