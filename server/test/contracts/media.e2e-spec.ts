import { INestApplication } from '@nestjs/common';
import { mkdir, rm, writeFile } from 'node:fs/promises';
import path from 'node:path';
import request from 'supertest';
import { App } from 'supertest/types.js';
import { MAX_MEDIA_SIZE_BYTES } from '../../src/media/media.rules.js';
import { PrismaService } from '../../src/prisma/prisma.service.js';
import { createTestApp } from '../create-app.js';

// 계약 테스트: media 모듈. api-contract.json의 API와 루트 docs/dev/features.json의 서버 합격 기준을 할 일(it.todo)로 적어 두었다.
// 이 파일은 손으로 관리한다. API마다 'METHOD /api/경로: … → 상태' 형식의 todo나 테스트가 있어야 하고, 상태 코드는 api-contract.json과 같아야 한다(npm run check:server가 확인).
// 하나를 구현하면 그 todo를 it(…) 안에서 request(app.getHttpServer()).<method>('/api/…')로 부르는 실제 테스트로 바꾸고, api-contract.json의 status를 done으로 바꾼다.
// 실행: npm run test:e2e (todo는 실패가 아니라 '남은 일'로 표시된다)

describe('DEV-08 사진과 얼굴 연출', () => {
  const mediaRoot = path.resolve('.test-media');
  let app: INestApplication<App>;
  let prisma: PrismaService;

  beforeAll(async () => {
    app = await createTestApp({ MEDIA_STORAGE_ROOT: mediaRoot });
    prisma = app.get(PrismaService);
    await cleanupFixtures();
  });

  afterEach(cleanupFixtures);

  afterAll(async () => {
    await app.close();
    await rm(mediaRoot, { recursive: true, force: true });
  });

  async function cleanupFixtures() {
    await prisma.user.deleteMany({
      where: { email: { endsWith: '@media.e2e.test' } },
    });
    await rm(mediaRoot, { recursive: true, force: true });
  }

  async function signup(name: string) {
    const response = await request(app.getHttpServer())
      .post('/api/auth/email/signup')
      .send({
        email: `${name}@media.e2e.test`,
        password: 'correct horse battery staple',
      })
      .expect(201);
    return {
      userId: response.body.userId as string,
      token: response.body.accessToken as string,
    };
  }

  async function prepare(
    token: string,
    mimeType = 'image/png',
    sizeBytes = 24,
  ) {
    return request(app.getHttpServer())
      .post('/api/media')
      .set('Authorization', `Bearer ${token}`)
      .send({ mimeType, sizeBytes })
      .expect(201);
  }

  function png(width = 1080, height = 1440): Buffer {
    const bytes = Buffer.alloc(24);
    Buffer.from('89504e470d0a1a0a', 'hex').copy(bytes);
    bytes.writeUInt32BE(width, 16);
    bytes.writeUInt32BE(height, 20);
    return bytes;
  }

  // media.prepare · 접근: user · 응답: MediaUploadDto · 계약: P11
  it('POST /api/media: 사진 올리기 준비(저장 위치 받기) → 201', async () => {
    const user = await signup('prepare');
    const response = await prepare(user.token);

    expect(response.body).toMatchObject({
      id: expect.any(String),
      storageKey: expect.stringMatching(/^pending\/.+\.upload$/),
      uploadPath: expect.any(String),
      maxSizeBytes: MAX_MEDIA_SIZE_BYTES,
      allowedMimeTypes: ['image/jpeg', 'image/png', 'image/heic'],
    });
    expect(
      await prisma.mediaAsset.findUnique({ where: { id: response.body.id } }),
    ).toMatchObject({
      ownerId: user.userId,
      status: 'PENDING',
      mimeType: 'image/png',
      sizeBytes: 24,
    });
  });

  it('POST /api/media: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/media')
      .send({ mimeType: 'image/png', sizeBytes: 24 })
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('POST /api/media: 보낸 값의 형식이 맞지 않아요 → 400 VALIDATION', async () => {
    const user = await signup('prepare-invalid');
    const response = await request(app.getHttpServer())
      .post('/api/media')
      .set('Authorization', `Bearer ${user.token}`)
      .send({ mimeType: 'image/png', sizeBytes: 0 })
      .expect(400);
    expect(response.body.error.code).toBe('VALIDATION');
  });

  it('POST /api/media: 사진이 너무 커요 → 413 MEDIA_TOO_LARGE', async () => {
    const user = await signup('prepare-large');
    const response = await request(app.getHttpServer())
      .post('/api/media')
      .set('Authorization', `Bearer ${user.token}`)
      .send({ mimeType: 'image/png', sizeBytes: MAX_MEDIA_SIZE_BYTES + 1 })
      .expect(413);
    expect(response.body.error.code).toBe('MEDIA_TOO_LARGE');
  });

  it('POST /api/media: 사진 파일만 올릴 수 있어요 → 415 MEDIA_TYPE', async () => {
    const user = await signup('prepare-type');
    const response = await request(app.getHttpServer())
      .post('/api/media')
      .set('Authorization', `Bearer ${user.token}`)
      .send({ mimeType: 'text/plain', sizeBytes: 24 })
      .expect(415);
    expect(response.body.error.code).toBe('MEDIA_TYPE');
  });

  // media.complete · 접근: owner · 응답: MediaOwnerDto · 계약: P11
  it('POST /api/media/:id/complete: 사진 올리기 완료 확인과 검증 → 201', async () => {
    const user = await signup('complete');
    const prepared = await prepare(user.token);
    await mkdir(path.dirname(prepared.body.uploadPath), { recursive: true });
    await writeFile(prepared.body.uploadPath, png());

    const response = await request(app.getHttpServer())
      .post(`/api/media/${prepared.body.id}/complete`)
      .set('Authorization', `Bearer ${user.token}`)
      .expect(201);

    expect(response.body).toMatchObject({
      id: prepared.body.id,
      status: 'READY',
      mimeType: 'image/png',
      sizeBytes: 24,
      width: 1080,
      height: 1440,
      storageKey: prepared.body.storageKey,
    });
  });

  it('POST /api/media/:id/complete: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/media/550e8400-e29b-41d4-a716-446655440000/complete')
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('POST /api/media/:id/complete: 남의 사진 → 403 FORBIDDEN', async () => {
    const owner = await signup('owner');
    const stranger = await signup('stranger');
    const prepared = await prepare(owner.token);
    const response = await request(app.getHttpServer())
      .post(`/api/media/${prepared.body.id}/complete`)
      .set('Authorization', `Bearer ${stranger.token}`)
      .expect(403);
    expect(response.body.error.code).toBe('FORBIDDEN');
  });

  it('POST /api/media/:id/complete: 없는 사진 → 404 NOT_FOUND', async () => {
    const user = await signup('missing');
    const response = await request(app.getHttpServer())
      .post('/api/media/550e8400-e29b-41d4-a716-446655440000/complete')
      .set('Authorization', `Bearer ${user.token}`)
      .expect(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
  });

  it('POST /api/media/:id/complete: 사진이 너무 커요 → 413 MEDIA_TOO_LARGE', async () => {
    const user = await signup('complete-large');
    const prepared = await prepare(user.token);
    await writeFile(
      prepared.body.uploadPath,
      Buffer.alloc(MAX_MEDIA_SIZE_BYTES + 1),
    );
    const response = await request(app.getHttpServer())
      .post(`/api/media/${prepared.body.id}/complete`)
      .set('Authorization', `Bearer ${user.token}`)
      .expect(413);
    expect(response.body.error.code).toBe('MEDIA_TOO_LARGE');
  });

  it('POST /api/media/:id/complete: 사진 파일만 올릴 수 있어요 → 415 MEDIA_TYPE', async () => {
    const user = await signup('complete-type');
    const prepared = await prepare(user.token);
    await writeFile(prepared.body.uploadPath, 'not an image');
    const response = await request(app.getHttpServer())
      .post(`/api/media/${prepared.body.id}/complete`)
      .set('Authorization', `Bearer ${user.token}`)
      .expect(415);
    expect(response.body.error.code).toBe('MEDIA_TYPE');
  });

  it('합격 기준: 이미지 파일은 PostgreSQL에 넣지 않고 저장 위치(storage_key)만 저장', async () => {
    const user = await signup('storage-key');
    const prepared = await prepare(user.token);
    const stored = await prisma.mediaAsset.findUniqueOrThrow({
      where: { id: prepared.body.id },
    });

    expect(stored.storageKey).toBe(prepared.body.storageKey);
    expect(Object.keys(stored)).not.toContain('bytes');
    expect(Object.keys(stored)).not.toContain('file');
  });
});
