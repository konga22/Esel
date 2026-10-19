import { INestApplication } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { readFile, rm, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { Readable } from 'node:stream';
import request from 'supertest';
import sharp from 'sharp';
import { App } from 'supertest/types.js';
import { AppException } from '../../src/common/app-exception.js';
import { serviceDate } from '../../src/common/service-date.js';
import { MAX_MEDIA_SIZE_BYTES } from '../../src/media/media.rules.js';
import { MediaService } from '../../src/media/media.service.js';
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
  let config: ConfigService;
  let mediaService: MediaService;

  beforeAll(async () => {
    app = await createTestApp({ MEDIA_STORAGE_ROOT: mediaRoot });
    prisma = app.get(PrismaService);
    config = app.get(ConfigService);
    mediaService = app.get(MediaService);
    await cleanupFixtures();
  });

  afterEach(cleanupFixtures);

  afterAll(async () => {
    await app.close();
    await rm(mediaRoot, { recursive: true, force: true });
  });

  async function cleanupFixtures() {
    const users = await prisma.user.findMany({
      where: { email: { endsWith: '@media.e2e.test' } },
      select: { id: true },
    });
    const userIds = users.map(({ id }) => id);
    const twins = await prisma.twin.findMany({
      where: { participations: { some: { userId: { in: userIds } } } },
      select: { id: true },
    });
    await prisma.twinPost.deleteMany({ where: { userId: { in: userIds } } });
    await prisma.twin.deleteMany({
      where: { id: { in: twins.map(({ id }) => id) } },
    });
    await prisma.issue.deleteMany({ where: { authorId: { in: userIds } } });
    await prisma.user.deleteMany({ where: { id: { in: userIds } } });
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

  async function png(width = 1080, height = 1440): Promise<Buffer> {
    return sharp({
      create: {
        width,
        height,
        channels: 3,
        background: { r: 168, g: 181, b: 160 },
      },
    })
      .png()
      .toBuffer();
  }

  async function uploadPath(id: string): Promise<string> {
    const media = await prisma.mediaAsset.findUniqueOrThrow({ where: { id } });
    return path.join(mediaRoot, media.storageKey);
  }

  function upload(
    token: string,
    id: string,
    bytes: Buffer,
    mimeType = 'image/png',
  ) {
    return request(app.getHttpServer())
      .put(`/api/media/${id}/file`)
      .set('Authorization', `Bearer ${token}`)
      .set('Content-Type', mimeType)
      .send(bytes);
  }

  async function readyMedia(token: string) {
    const bytes = await png();
    const prepared = await prepare(token, 'image/png', bytes.length);
    await upload(token, prepared.body.id, bytes).expect(204);
    await request(app.getHttpServer())
      .post(`/api/media/${prepared.body.id}/complete`)
      .set('Authorization', `Bearer ${token}`)
      .expect(201);
    return prepared.body.id as string;
  }

  // media.prepare · 접근: user · 응답: MediaUploadDto · 계약: P11
  it('POST /api/media: 사진 올리기 준비(저장 위치 받기) → 201', async () => {
    const user = await signup('prepare');
    const response = await prepare(user.token);

    expect(response.body).toMatchObject({
      id: expect.any(String),
      uploadUrl: expect.stringMatching(/^\/api\/media\/.+\/file$/),
      maxSizeBytes: MAX_MEDIA_SIZE_BYTES,
      allowedMimeTypes: ['image/jpeg', 'image/png', 'image/heic'],
    });
    expect(response.body).not.toHaveProperty('uploadPath');
    expect(response.body).not.toHaveProperty('storageKey');
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

  // media.upload · 접근: owner · 응답: void · 계약: P11
  it('PUT /api/media/:id/file: 서버 영구 디스크에 사진 파일 올리기 → 204', async () => {
    const user = await signup('upload');
    const bytes = await png();
    const prepared = await prepare(user.token, 'image/png', bytes.length);
    await upload(user.token, prepared.body.id, bytes).expect(204);

    expect(await readFile(await uploadPath(prepared.body.id))).toEqual(bytes);
  });

  it('PUT /api/media/:id/file: 로그인 없이 부르면 → 401 AUTH_REQUIRED', async () => {
    const response = await request(app.getHttpServer())
      .put('/api/media/550e8400-e29b-41d4-a716-446655440000/file')
      .set('Content-Type', 'image/png')
      .send(await png())
      .expect(401);
    expect(response.body.error.code).toBe('AUTH_REQUIRED');
  });

  it('PUT /api/media/:id/file: 남의 사진 → 403 FORBIDDEN', async () => {
    const owner = await signup('upload-owner');
    const stranger = await signup('upload-stranger');
    const prepared = await prepare(owner.token);
    const response = await upload(
      stranger.token,
      prepared.body.id,
      await png(),
    ).expect(403);
    expect(response.body.error.code).toBe('FORBIDDEN');
  });

  it('PUT /api/media/:id/file: 없는 사진 → 404 NOT_FOUND', async () => {
    const user = await signup('upload-missing');
    const response = await upload(
      user.token,
      '550e8400-e29b-41d4-a716-446655440000',
      await png(),
    ).expect(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
  });

  it('PUT /api/media/:id/file: PENDING이 아닌 사진 → 409 MEDIA_NOT_PENDING', async () => {
    const user = await signup('upload-state');
    const id = await readyMedia(user.token);
    const response = await upload(user.token, id, await png()).expect(409);
    expect(response.body.error.code).toBe('MEDIA_NOT_PENDING');
  });

  it('PUT /api/media/:id/file: 늦게 끝난 업로드가 완료된 원본을 덮어쓰지 않음', async () => {
    const user = await signup('upload-race');
    const slowBytes = await png(640, 640);
    const fastBytes = await png(320, 480);
    const prepared = await prepare(user.token, 'image/png', slowBytes.length);
    let startedResolve!: () => void;
    const started = new Promise<void>((resolve) => {
      startedResolve = resolve;
    });
    let firstRead = true;
    const split = Math.floor(slowBytes.length / 2);
    const slowStream = new Readable({
      read() {
        if (!firstRead) return;
        firstRead = false;
        this.push(slowBytes.subarray(0, split));
        startedResolve();
      },
    });
    const slowResult = mediaService
      .upload(
        user.userId,
        prepared.body.id,
        slowStream,
        'image/png',
        slowBytes.length,
      )
      .then(
        () => null,
        (error: unknown) => error,
      );
    await started;

    await upload(user.token, prepared.body.id, fastBytes).expect(204);
    await request(app.getHttpServer())
      .post(`/api/media/${prepared.body.id}/complete`)
      .set('Authorization', `Bearer ${user.token}`)
      .expect(201);
    slowStream.push(slowBytes.subarray(split));
    slowStream.push(null);

    const error = await slowResult;
    expect(error).toBeInstanceOf(AppException);
    expect((error as AppException).code).toBe('MEDIA_NOT_PENDING');
    expect(await readFile(await uploadPath(prepared.body.id))).toEqual(
      fastBytes,
    );
  });

  it('PUT /api/media/:id/file: 사진이 너무 커요 → 413 MEDIA_TOO_LARGE', async () => {
    const user = await signup('upload-large');
    const prepared = await prepare(user.token);
    const response = await upload(
      user.token,
      prepared.body.id,
      Buffer.alloc(MAX_MEDIA_SIZE_BYTES + 1),
    ).expect(413);
    expect(response.body.error.code).toBe('MEDIA_TOO_LARGE');
  });

  it('PUT /api/media/:id/file: 선언한 형식과 다른 Content-Type → 415 MEDIA_TYPE', async () => {
    const user = await signup('upload-type');
    const prepared = await prepare(user.token, 'image/png');
    const response = await upload(
      user.token,
      prepared.body.id,
      await png(),
      'image/jpeg',
    ).expect(415);
    expect(response.body.error.code).toBe('MEDIA_TYPE');
  });

  // media.complete · 접근: owner · 응답: MediaOwnerDto · 계약: P11
  it('POST /api/media/:id/complete: 사진 올리기 완료 확인과 검증 → 201', async () => {
    const user = await signup('complete');
    const bytes = await png();
    const prepared = await prepare(user.token, 'image/png', bytes.length);
    await upload(user.token, prepared.body.id, bytes).expect(204);

    const response = await request(app.getHttpServer())
      .post(`/api/media/${prepared.body.id}/complete`)
      .set('Authorization', `Bearer ${user.token}`)
      .expect(201);

    expect(response.body).toMatchObject({
      id: prepared.body.id,
      status: 'READY',
      mimeType: 'image/png',
      sizeBytes: bytes.length,
      width: 1080,
      height: 1440,
    });
    expect(response.body).not.toHaveProperty('storageKey');
  });

  it('POST /api/media/:id/complete: PENDING이 아닌 사진은 다시 완료할 수 없음 → 409 MEDIA_NOT_PENDING', async () => {
    const user = await signup('complete-twice');
    const bytes = await png();
    const prepared = await prepare(user.token, 'image/png', bytes.length);
    await upload(user.token, prepared.body.id, bytes).expect(204);
    await request(app.getHttpServer())
      .post(`/api/media/${prepared.body.id}/complete`)
      .set('Authorization', `Bearer ${user.token}`)
      .expect(201);

    const response = await request(app.getHttpServer())
      .post(`/api/media/${prepared.body.id}/complete`)
      .set('Authorization', `Bearer ${user.token}`)
      .expect(409);
    expect(response.body.error.code).toBe('MEDIA_NOT_PENDING');
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
      await uploadPath(prepared.body.id),
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
    await writeFile(await uploadPath(prepared.body.id), 'not an image');
    const response = await request(app.getHttpServer())
      .post(`/api/media/${prepared.body.id}/complete`)
      .set('Authorization', `Bearer ${user.token}`)
      .expect(415);
    expect(response.body.error.code).toBe('MEDIA_TYPE');
  });

  // media.get · 접근: public · 응답: MediaBinary · 계약: P01, P02, P10, P11
  it('GET /api/media/:id: 소유자가 원본 또는 썸네일 사진 보기 → 200', async () => {
    const user = await signup('get-owner');
    const id = await readyMedia(user.token);

    const original = await request(app.getHttpServer())
      .get(`/api/media/${id}`)
      .set('Authorization', `Bearer ${user.token}`)
      .expect(200);
    expect(original.headers['content-type']).toMatch(/^image\/png/);
    expect(original.headers['cache-control']).toBe('private, no-store');

    const thumbnail = await request(app.getHttpServer())
      .get(`/api/media/${id}?size=thumb`)
      .set('Authorization', `Bearer ${user.token}`)
      .expect(200);
    expect(thumbnail.headers['content-type']).toMatch(/^image\/jpeg/);
  });

  it('GET /api/media/:id: 로그인 없이도 숨은 사진은 → 404 NOT_FOUND', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/media/550e8400-e29b-41d4-a716-446655440000')
      .expect(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
  });

  it('GET /api/media/:id: size 형식이 맞지 않아요 → 400 VALIDATION', async () => {
    const user = await signup('get-size');
    const response = await request(app.getHttpServer())
      .get('/api/media/550e8400-e29b-41d4-a716-446655440000?size=large')
      .set('Authorization', `Bearer ${user.token}`)
      .expect(400);
    expect(response.body.error.code).toBe('VALIDATION');
  });

  it('GET /api/media/:id: 없거나 READY가 아니거나 볼 권한이 없으면 → 404 NOT_FOUND', async () => {
    const owner = await signup('get-hidden-owner');
    const stranger = await signup('get-hidden-stranger');
    const prepared = await prepare(owner.token);

    for (const id of [
      prepared.body.id,
      '550e8400-e29b-41d4-a716-446655440000',
    ]) {
      const response = await request(app.getHttpServer())
        .get(`/api/media/${id}`)
        .set('Authorization', `Bearer ${stranger.token}`)
        .expect(404);
      expect(response.body.error.code).toBe('NOT_FOUND');
    }
  });

  it('GET /api/media/:id: 공개 가능한 개인 호의 사진은 다른 사용자도 볼 수 있음 → 200', async () => {
    const owner = await signup('get-issue-owner');
    const mediaId = await readyMedia(owner.token);
    await prisma.issue.create({
      data: {
        authorId: owner.userId,
        serviceDate: new Date('2000-01-01T00:00:00.000Z'),
        issueNumber: 1,
        colorId: 'sage',
        mediaId,
        caption: '',
        faceCrop: 'ORIGINAL',
        paintStroke: false,
      },
    });

    await request(app.getHttpServer())
      .get(`/api/media/${mediaId}?size=thumb`)
      .expect(200)
      .expect('Content-Type', /^image\/jpeg/);
  });

  it('GET /api/media/:id: 비로그인 오늘 표지의 사진을 바로 볼 수 있음 → 200', async () => {
    const owner = await signup('get-cover-owner');
    await prisma.profile.create({
      data: { userId: owner.userId, masthead: 'coverpic' },
    });
    const mediaId = await readyMedia(owner.token);
    const key = serviceDate(
      new Date(),
      config.getOrThrow<string>('SERVICE_TIME_ZONE'),
    );
    await prisma.issue.create({
      data: {
        authorId: owner.userId,
        serviceDate: new Date(`${key}T00:00:00.000Z`),
        issueNumber: 1,
        colorId: 'sage',
        mediaId,
        caption: '',
        faceCrop: 'ORIGINAL',
        paintStroke: false,
        publishedAt: new Date(Date.now() + 86_400_000),
      },
    });
    const cover = await request(app.getHttpServer())
      .get('/api/today/cover')
      .expect(200);
    expect([
      cover.body.cover?.media?.id,
      ...(cover.body.pages ?? []).map(
        (page: { media: { id: string } }) => page.media.id,
      ),
    ]).toContain(mediaId);

    await request(app.getHttpServer())
      .get(`/api/media/${mediaId}?size=thumb`)
      .expect(200)
      .expect('Content-Type', /^image\/jpeg/);
  });

  it('GET /api/media/:id: 트윈은 두 게시 전 상대에게 숨기고 solo 이후에만 외부 공개 → 200·404', async () => {
    const owner = await signup('get-twin-owner');
    const partner = await signup('get-twin-partner');
    const outsider = await signup('get-twin-outsider');
    const ownerMediaId = await readyMedia(owner.token);
    const partnerMediaId = await readyMedia(partner.token);
    const twin = await prisma.twin.create({
      data: {
        serviceDate: new Date('2001-01-01T00:00:00.000Z'),
        status: 'ACCEPTED',
        participations: {
          create: [
            {
              userId: owner.userId,
              serviceDate: new Date('2001-01-01T00:00:00.000Z'),
              role: 'INVITER',
            },
            {
              userId: partner.userId,
              serviceDate: new Date('2001-01-01T00:00:00.000Z'),
              role: 'INVITEE',
            },
          ],
        },
      },
    });
    await prisma.twinPost.create({
      data: {
        twinId: twin.id,
        userId: owner.userId,
        mediaId: ownerMediaId,
        colorId: 'sage',
      },
    });

    await request(app.getHttpServer())
      .get(`/api/media/${ownerMediaId}`)
      .set('Authorization', `Bearer ${partner.token}`)
      .expect(404);

    await prisma.twinPost.create({
      data: {
        twinId: twin.id,
        userId: partner.userId,
        mediaId: partnerMediaId,
        colorId: 'butter',
      },
    });
    await request(app.getHttpServer())
      .get(`/api/media/${ownerMediaId}`)
      .set('Authorization', `Bearer ${partner.token}`)
      .expect(200);
    await request(app.getHttpServer())
      .get(`/api/media/${ownerMediaId}`)
      .set('Authorization', `Bearer ${outsider.token}`)
      .expect(404);

    await prisma.twinParticipation.update({
      where: {
        twinId_userId: { twinId: twin.id, userId: owner.userId },
      },
      data: { visibility: 'SOLO' },
    });
    await request(app.getHttpServer())
      .get(`/api/media/${ownerMediaId}`)
      .expect(200);
  });

  it('합격 기준: 이미지 파일은 PostgreSQL에 넣지 않고 저장 위치(storage_key)만 저장', async () => {
    const user = await signup('storage-key');
    const prepared = await prepare(user.token);
    const stored = await prisma.mediaAsset.findUniqueOrThrow({
      where: { id: prepared.body.id },
    });

    expect(stored.storageKey).toMatch(/^pending\/.+\.upload$/);
    expect(Object.keys(stored)).not.toContain('bytes');
    expect(Object.keys(stored)).not.toContain('file');
  });
});
