import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types.js';
import { createTestApp } from './create-app.js';

describe('HealthController (e2e)', () => {
  let app: INestApplication<App>;

  beforeEach(async () => {
    app = await createTestApp();
  });

  afterEach(async () => {
    await app.close();
  });

  it('GET /api/health: API와 DB가 살아 있으면 200 { status: ok, database: up }', async () => {
    await request(app.getHttpServer())
      .get('/api/health')
      .expect(200)
      .expect('x-content-type-options', 'nosniff') // configureApp의 Helmet 보안 헤더
      .expect(({ body }) => {
        expect(body).toMatchObject({ status: 'ok', database: 'up' });
      });
  });
});
