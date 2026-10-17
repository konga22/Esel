import { createHash, randomBytes } from 'node:crypto';

const ACCESS_TOKEN_LIFETIME_MS = 15 * 60 * 1_000;
const REFRESH_TOKEN_LIFETIME_MS = 30 * 24 * 60 * 60 * 1_000;

export interface NewSessionTokens {
  accessToken: string;
  refreshToken: string;
  accessTokenHash: string;
  refreshTokenHash: string;
  accessExpiresAt: Date;
  refreshExpiresAt: Date;
}

export function hashToken(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}

export function newSessionTokens(now = new Date()): NewSessionTokens {
  const accessToken = randomBytes(32).toString('base64url');
  const refreshToken = randomBytes(32).toString('base64url');
  return {
    accessToken,
    refreshToken,
    accessTokenHash: hashToken(accessToken),
    refreshTokenHash: hashToken(refreshToken),
    accessExpiresAt: new Date(now.getTime() + ACCESS_TOKEN_LIFETIME_MS),
    refreshExpiresAt: new Date(now.getTime() + REFRESH_TOKEN_LIFETIME_MS),
  };
}
