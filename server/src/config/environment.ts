import { z } from 'zod';
import { isValidTimeZone } from '../common/service-date.js';

// 개발할 때만 쓰는 CORS 기본값(앱 개발 서버 주소). 운영에서는 기본값 없이 CORS_ORIGINS를 꼭 정한다.
const DEVELOPMENT_CORS_ORIGINS = 'http://localhost:8081';

const environmentSchema = z
  .object({
    NODE_ENV: z
      .enum(['development', 'test', 'production'])
      .default('development'),
    PORT: z.coerce.number().int().min(1).max(65_535).default(3000),
    DATABASE_URL: z.string().min(1),
    CORS_ORIGINS: z.string().trim().optional(),
    SERVICE_TIME_ZONE: z
      .string()
      .default('Asia/Seoul')
      .refine(isValidTimeZone, {
        message: 'IANA 시간대 이름이어야 해요. 예: Asia/Seoul',
      }),
  })
  .transform((env, ctx) => {
    if (!env.CORS_ORIGINS && env.NODE_ENV === 'production') {
      ctx.addIssue({
        code: 'custom',
        path: ['CORS_ORIGINS'],
        message:
          '운영(NODE_ENV=production)에서는 CORS_ORIGINS를 꼭 정해야 해요. 개발용 localhost 기본값은 쓰지 않아요.',
      });
      return z.NEVER;
    }
    const origins = (env.CORS_ORIGINS || DEVELOPMENT_CORS_ORIGINS)
      .split(',')
      .map((origin) => origin.trim())
      .filter(Boolean);
    const invalid = origins.filter((origin) => !isOrigin(origin));
    if (!origins.length || invalid.length) {
      ctx.addIssue({
        code: 'custom',
        path: ['CORS_ORIGINS'],
        message: `쉼표로 나눈 http(s) 주소(경로 없이)여야 해요. 맞지 않는 값: ${invalid.join(', ') || '(빈 값)'}`,
      });
      return z.NEVER;
    }
    return { ...env, CORS_ORIGINS: origins };
  });

export type Environment = z.output<typeof environmentSchema>;

/** "https://esel.app"처럼 프로토콜·호스트(·포트)만 있는 주소인지. "*"나 경로가 붙은 주소는 거절한다. */
function isOrigin(value: string): boolean {
  try {
    const url = new URL(value);
    return (
      (url.protocol === 'http:' || url.protocol === 'https:') &&
      url.origin === value
    );
  } catch {
    return false;
  }
}

export function validateEnvironment(
  config: Record<string, unknown>,
): Environment {
  const result = environmentSchema.safeParse(config);
  if (!result.success) {
    throw new Error(
      `Invalid environment configuration: ${z.prettifyError(result.error)}`,
    );
  }
  return result.data;
}
