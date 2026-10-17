import { hashToken, newSessionTokens } from './session-token.js';

describe('newSessionTokens', () => {
  it('원문과 다른 고정 길이 해시 및 만료 시각을 만든다', () => {
    const now = new Date('2026-10-17T00:00:00.000Z');
    const tokens = newSessionTokens(now);

    expect(tokens.accessTokenHash).toBe(hashToken(tokens.accessToken));
    expect(tokens.refreshTokenHash).toBe(hashToken(tokens.refreshToken));
    expect(tokens.accessTokenHash).toHaveLength(64);
    expect(tokens.refreshTokenHash).toHaveLength(64);
    expect(tokens.accessTokenHash).not.toBe(tokens.accessToken);
    expect(tokens.refreshExpiresAt.getTime()).toBeGreaterThan(
      tokens.accessExpiresAt.getTime(),
    );
  });
});
