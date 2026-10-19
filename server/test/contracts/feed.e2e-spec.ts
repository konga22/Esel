import { INestApplication } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { App } from 'supertest/types.js';
import { serviceDate } from '../../src/common/service-date.js';
import { PrismaService } from '../../src/prisma/prisma.service.js';
import { createTestApp } from '../create-app.js';

describe('DEV-10 표지 피드', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let timeZone: string;
  let mastheadSequence = 0;

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
      where: { author: { email: { endsWith: '@feed.e2e.test' } } },
    });
    await prisma.user.deleteMany({
      where: { email: { endsWith: '@feed.e2e.test' } },
    });
  }

  async function signup(label: string) {
    const response = await request(app.getHttpServer())
      .post('/api/auth/email/signup')
      .send({
        email: `${label}-${randomUUID()}@feed.e2e.test`,
        password: 'correct horse battery staple',
      })
      .expect(201);
    const user = {
      id: response.body.userId as string,
      token: response.body.accessToken as string,
      masthead: nextMasthead(),
    };
    await prisma.profile.create({
      data: { userId: user.id, masthead: user.masthead },
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
    return `feed${suffix}`;
  }

  function day(offset: number) {
    const date = new Date(`${serviceDate(new Date(), timeZone)}T00:00:00.000Z`);
    date.setUTCDate(date.getUTCDate() + offset);
    return date;
  }

  async function issue(
    authorId: string,
    options: {
      date?: Date;
      colorId?: string;
      publishedAt?: Date;
      issueNumber?: number;
    } = {},
  ) {
    const media = await prisma.mediaAsset.create({
      data: {
        ownerId: authorId,
        storageKey: `feed/${randomUUID()}`,
        status: 'READY',
        mimeType: 'image/png',
        sizeBytes: 24,
      },
    });
    return prisma.issue.create({
      data: {
        authorId,
        serviceDate: options.date ?? day(-1),
        issueNumber: options.issueNumber ?? 1,
        colorId: options.colorId ?? 'sage',
        mediaId: media.id,
        caption: '피드',
        faceCrop: 'ORIGINAL',
        paintStroke: false,
        publishedAt: options.publishedAt,
      },
    });
  }

  const auth = (token: string) => ({ Authorization: `Bearer ${token}` });

  // feed.list · 접근: user · 응답: FeedPageDto · 계약: P01, P02, P16, P18
  it('GET /api/feed: 표지 피드(첫 장 표지 + 안쪽 지면, 공개 권한 먼저 거름) → 200', async () => {
    const reader = await signup('reader');
    const subscribedAuthor = await signup('subscribed');
    const recommendedAuthor = await signup('recommended');
    await prisma.subscription.create({
      data: { subscriberId: reader.id, magazineId: subscribedAuthor.id },
    });
    await issue(subscribedAuthor.id, {
      publishedAt: new Date('2026-01-01T00:00:00.000Z'),
    });
    await issue(recommendedAuthor.id, {
      publishedAt: new Date('2026-01-02T00:00:00.000Z'),
    });
    const response = await request(app.getHttpServer())
      .get('/api/feed')
      .set(auth(reader.token))
      .expect(200);
    const byMasthead = new Map(
      response.body.items.map((item: { masthead: string; source: string }) => [
        item.masthead,
        item.source,
      ]),
    );
    expect(byMasthead.get(recommendedAuthor.masthead)).toBe('RECOMMENDED');
    expect(byMasthead.get(subscribedAuthor.masthead)).toBe('SUBSCRIPTION');
  });

  it('GET /api/feed: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/feed')
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('GET /api/feed: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION', async () => {
    const reader = await signup('invalid');
    const response = await request(app.getHttpServer())
      .get('/api/feed?cursor=bad')
      .set(auth(reader.token))
      .expect(400);
    expect(response.body.error.code).toBe('VALIDATION');
  });

  it('합격 기준(P01): 오늘 발행 전에는 오늘 후보 3색의 표지가 피드에 없음(고른 색·바꾼 색과 무관). 발행하면 들어옴', async () => {
    const reader = await signup('locked-reader');
    const author = await signup('locked-author');
    const today = await request(app.getHttpServer())
      .get('/api/today')
      .set(auth(reader.token))
      .expect(200);
    const colorId = today.body.candidates[0].id as string;
    const locked = await issue(author.id, { date: day(0), colorId });
    let response = await request(app.getHttpServer())
      .get('/api/feed')
      .set(auth(reader.token))
      .expect(200);
    expect(
      response.body.items.map(({ id }: { id: string }) => id),
    ).not.toContain(locked.id);
    await issue(reader.id, { date: day(0), colorId });
    response = await request(app.getHttpServer())
      .get('/api/feed')
      .set(auth(reader.token))
      .expect(200);
    expect(response.body.items.map(({ id }: { id: string }) => id)).toContain(
      locked.id,
    );
  });

  it('합격 기준(P02): 후보가 아닌 색과 지난 날짜 표지는 발행 전에도 나오고, 미래 지면은 오지 않음', async () => {
    const reader = await signup('dates-reader');
    const author = await signup('dates-author');
    const today = await request(app.getHttpServer())
      .get('/api/today')
      .set(auth(reader.token))
      .expect(200);
    const candidates = (today.body.candidates as { id: string }[]).map(
      ({ id }) => id,
    );
    const other = await prisma.color.findFirstOrThrow({
      where: { id: { notIn: candidates } },
    });
    const past = await issue(author.id, {
      date: day(-2),
      colorId: candidates[0],
      issueNumber: 1,
    });
    const openToday = await issue(author.id, {
      date: day(0),
      colorId: other.id,
      issueNumber: 2,
    });
    const future = await issue(author.id, {
      date: day(1),
      colorId: other.id,
      issueNumber: 3,
    });
    const response = await request(app.getHttpServer())
      .get('/api/feed')
      .set(auth(reader.token))
      .expect(200);
    const ids = response.body.items.map(({ id }: { id: string }) => id);
    expect(ids).toEqual(expect.arrayContaining([past.id, openToday.id]));
    expect(ids).not.toContain(future.id);
  });

  it('합격 기준: 다음 페이지(cursor)를 불러도 이미 보낸 지면의 순서가 바뀌지 않음', async () => {
    const reader = await signup('cursor-reader');
    const author = await signup('cursor-author');
    for (let index = 0; index < 21; index += 1) {
      await issue(author.id, {
        date: day(-index - 1),
        issueNumber: index + 1,
        publishedAt: new Date(10_000 + index),
      });
    }
    const first = await request(app.getHttpServer())
      .get('/api/feed')
      .set(auth(reader.token))
      .expect(200);
    const second = await request(app.getHttpServer())
      .get('/api/feed')
      .query({ cursor: first.body.nextCursor })
      .set(auth(reader.token))
      .expect(200);
    expect(first.body.items).toHaveLength(20);
    expect(second.body.items).toHaveLength(1);
    expect(
      new Set(
        [...first.body.items, ...second.body.items].map(
          ({ id }: { id: string }) => id,
        ),
      ).size,
    ).toBe(21);
  });

  it('합격 기준(P18): 응답에 반응 숫자·순위가 없음', async () => {
    const reader = await signup('numbers-reader');
    const author = await signup('numbers-author');
    await issue(author.id);
    const response = await request(app.getHttpServer())
      .get('/api/feed')
      .set(auth(reader.token))
      .expect(200);
    expect(JSON.stringify(response.body)).not.toMatch(
      /likeCount|scrapCount|lineCount|rank/,
    );
  });
});
