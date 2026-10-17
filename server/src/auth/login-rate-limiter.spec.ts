import { AppException } from '../common/app-exception.js';
import { LoginRateLimiter } from './login-rate-limiter.js';

describe('LoginRateLimiter', () => {
  it('같은 이메일의 1분 안 여섯 번째 시도를 막는다', () => {
    const limiter = new LoginRateLimiter();

    for (let attempt = 0; attempt < 5; attempt += 1) {
      expect(() => limiter.consume('me@example.com', 1_000)).not.toThrow();
    }
    expect(() => limiter.consume('me@example.com', 1_000)).toThrow(
      AppException,
    );
  });

  it('1분이 지나면 다시 시도할 수 있다', () => {
    const limiter = new LoginRateLimiter();
    for (let attempt = 0; attempt < 5; attempt += 1) {
      limiter.consume('me@example.com', 1_000);
    }

    expect(() => limiter.consume('me@example.com', 61_000)).not.toThrow();
  });
});
