import { INestApplication } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { App } from 'supertest/types.js';
import { AppModule } from '../src/app.module.js';
import { configureApp } from '../src/app.setup.js';
import { validateEnvironment } from '../src/config/environment.js';

/**
 * e2e 테스트용 앱. main.ts와 같은 configureApp(접두어 /api, 검사, 보안 헤더, Swagger 조건)을 거친다.
 * env를 주면 그 환경변수로 바꿔 띄운다. 예: createTestApp({ NODE_ENV: 'production', CORS_ORIGINS: 'https://esel.app' })
 */
export async function createTestApp(
  env: Record<string, string> = {},
): Promise<INestApplication<App>> {
  const builder = Test.createTestingModule({ imports: [AppModule] });
  if (Object.keys(env).length) {
    const values: Record<string, unknown> = validateEnvironment({
      ...process.env,
      ...env,
    });
    const getOrThrow = (key: string) => {
      if (values[key] === undefined)
        throw new Error(`${key} 환경변수가 없어요`);
      return values[key];
    };
    builder
      .overrideProvider(ConfigService)
      .useValue({ get: (key: string) => values[key], getOrThrow });
  }
  const moduleRef = await builder.compile();
  const app = moduleRef.createNestApplication<INestApplication<App>>();
  configureApp(app);
  await app.init();
  return app;
}
