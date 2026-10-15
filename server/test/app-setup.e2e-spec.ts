import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types.js';
import { createTestApp } from './create-app.js';

// configureApp이 main.ts와 같은 규칙으로 앱을 꾸미는지 확인한다.
describe('앱 설정 (e2e)', () => {
  let app: INestApplication<App> | undefined;

  afterEach(async () => {
    await app?.close();
    app = undefined;
  });

  it('개발·테스트 환경에서는 Swagger 문서(/api/docs)가 열린다', async () => {
    app = await createTestApp();
    await request(app.getHttpServer()).get('/api/docs').expect(200);
    await request(app.getHttpServer())
      .get('/api/docs-json')
      .expect(200)
      .expect(({ body }) => {
        expect(body).toHaveProperty('openapi');
      });
  });

  it('운영(NODE_ENV=production)에서는 Swagger 문서가 없다(404)', async () => {
    app = await createTestApp({
      NODE_ENV: 'production',
      CORS_ORIGINS: 'https://esel.app',
    });
    await request(app.getHttpServer()).get('/api/docs').expect(404);
    await request(app.getHttpServer()).get('/api/docs-json').expect(404);
  });

  it('CORS는 CORS_ORIGINS에 적힌 주소에만 열린다', async () => {
    app = await createTestApp({
      NODE_ENV: 'production',
      CORS_ORIGINS: 'https://esel.app',
    });
    await request(app.getHttpServer())
      .get('/api/docs')
      .set('Origin', 'https://esel.app')
      .expect('access-control-allow-origin', 'https://esel.app');
    await request(app.getHttpServer())
      .get('/api/docs')
      .set('Origin', 'https://evil.example')
      .expect((res) => {
        expect(res.headers['access-control-allow-origin']).toBeUndefined();
      });
  });
});
