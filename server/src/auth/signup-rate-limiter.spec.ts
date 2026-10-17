import { AppException } from '../common/app-exception.js';
import { SignupRateLimiter } from './signup-rate-limiter.js';

describe('SignupRateLimiter', () => {
  it('1분 안의 여섯 번째 같은 이메일 요청을 막는다', () => {
    const limiter = new SignupRateLimiter();
    for (let count = 0; count < 5; count += 1) {
      expect(() => limiter.consume('me@example.com', 1_000)).not.toThrow();
    }
    expect(() => limiter.consume('me@example.com', 1_000)).toThrow(
      AppException,
    );
  });

  it('1분이 지나면 다시 요청할 수 있다', () => {
    const limiter = new SignupRateLimiter();
    for (let count = 0; count < 5; count += 1) {
      limiter.consume('me@example.com', 1_000);
    }
    expect(() => limiter.consume('me@example.com', 61_000)).not.toThrow();
  });
});
