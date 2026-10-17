import { describe, expect, it } from 'vitest';
import { AppException } from '../common/app-exception.js';
import { ReaderLineRateLimiter } from './reader-line-rate-limiter.js';

describe('ReaderLineRateLimiter', () => {
  it('같은 키의 여섯 번째 1분 내 요청을 막는다', () => {
    const limiter = new ReaderLineRateLimiter();
    for (let index = 0; index < 5; index += 1) {
      expect(() =>
        limiter.consume('reader:issue', 1_000 + index),
      ).not.toThrow();
    }
    expect(() => limiter.consume('reader:issue', 2_000)).toThrowError(
      expect.objectContaining<AppException>({ code: 'RATE_LIMITED' }),
    );
  });

  it('1분이 지나면 다시 허용한다', () => {
    const limiter = new ReaderLineRateLimiter();
    for (let index = 0; index < 5; index += 1) limiter.consume('key', 0);
    expect(() => limiter.consume('key', 60_000)).not.toThrow();
  });
});
