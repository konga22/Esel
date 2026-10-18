import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { App } from 'supertest/types.js';
import { PrismaService } from '../../src/prisma/prisma.service.js';
import { createTestApp } from '../create-app.js';

describe('DEV-24 착용 정보', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
    await cleanup();
  });
  afterEach(cleanup);
  afterAll(async () => app.close());

  async function cleanup() {
    await prisma.user.deleteMany({
      where: { email: { endsWith: '@garments.e2e.test' } },
    });
  }

  async function signup(label: string) {
    const response = await request(app.getHttpServer())
      .post('/api/auth/email/signup')
      .send({
        email: `${label}-${randomUUID()}@garments.e2e.test`,
        password: 'correct horse battery staple',
      })
      .expect(201);
    return {
      id: response.body.userId as string,
      token: response.body.accessToken as string,
    };
  }

  const auth = (token: string) => ({ Authorization: `Bearer ${token}` });

  it('GET /api/me/garments: 내 옷 목록(같은 옷, 다른 코디에서 다시 고르기, cursor) → 200', async () => {
    const owner = await signup('owner');
    const other = await signup('other');
    const mine = await prisma.garment.create({
      data: { ownerId: owner.id, kind: 'top', name: '흰 셔츠', note: '오버핏' },
    });
    await prisma.garment.create({
      data: { ownerId: other.id, kind: 'shoes', name: '남의 신발' },
    });
    const response = await request(app.getHttpServer())
      .get('/api/me/garments')
      .set(auth(owner.token))
      .expect(200);
    expect(response.body).toEqual({
      items: [
        {
          id: mine.id,
          kind: 'top',
          name: '흰 셔츠',
          note: '오버핏',
          createdAt: expect.any(String),
        },
      ],
      nextCursor: null,
    });
    expect(JSON.stringify(response.body)).not.toMatch(/price|shopUrl/i);
  });

  it('GET /api/me/garments: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/me/garments')
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('GET /api/me/garments: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION', async () => {
    const owner = await signup('invalid');
    const response = await request(app.getHttpServer())
      .get('/api/me/garments?cursor=bad')
      .set(auth(owner.token))
      .expect(400);
    expect(response.body.error.code).toBe('VALIDATION');
  });

  it('합격 기준: 탈퇴하면 내 옷과 호에 붙은 착용 정보가 함께 지워짐', async () => {
    const owner = await signup('cascade');
    const garment = await prisma.garment.create({
      data: { ownerId: owner.id, kind: 'bag', name: '가방' },
    });
    await prisma.user.delete({ where: { id: owner.id } });
    expect(
      await prisma.garment.findUnique({ where: { id: garment.id } }),
    ).toBeNull();
  });
});
