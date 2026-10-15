import { describe, expect, it } from 'vitest';
import { validateEnvironment } from './environment.js';

const base = { DATABASE_URL: 'postgresql://esel:esel_dev@localhost:5432/esel' };

describe('validateEnvironment', () => {
  it('개발에서는 기본값으로 시작한다', () => {
    expect(validateEnvironment(base)).toMatchObject({
      NODE_ENV: 'development',
      PORT: 3000,
      CORS_ORIGINS: ['http://localhost:8081'],
      SERVICE_TIME_ZONE: 'Asia/Seoul',
    });
  });

  it('운영에서 CORS_ORIGINS를 빼먹으면 시작하지 않는다', () => {
    expect(() =>
      validateEnvironment({ ...base, NODE_ENV: 'production' }),
    ).toThrow(/CORS_ORIGINS/);
  });

  it('운영에서 정한 CORS_ORIGINS는 쉼표로 나눠 쓴다', () => {
    const env = validateEnvironment({
      ...base,
      NODE_ENV: 'production',
      CORS_ORIGINS: 'https://esel.app, https://www.esel.app',
    });
    expect(env.CORS_ORIGINS).toEqual([
      'https://esel.app',
      'https://www.esel.app',
    ]);
  });

  it('"*"나 경로가 붙은 주소는 CORS_ORIGINS로 받지 않는다', () => {
    expect(() => validateEnvironment({ ...base, CORS_ORIGINS: '*' })).toThrow(
      /CORS_ORIGINS/,
    );
    expect(() =>
      validateEnvironment({ ...base, CORS_ORIGINS: 'https://esel.app/api' }),
    ).toThrow(/CORS_ORIGINS/);
  });

  it('없는 시간대 이름은 시작 단계에서 막는다', () => {
    expect(() =>
      validateEnvironment({ ...base, SERVICE_TIME_ZONE: 'Seoul' }),
    ).toThrow(/SERVICE_TIME_ZONE/);
  });
});
