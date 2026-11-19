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

  it('시도는 비밀번호를 확인하기 전에 센다: 동시에 몰려온 요청도 다섯 개까지만 통과한다', () => {
    const limiter = new LoginRateLimiter();
    let allowed = 0;

    // 비밀번호 확인(scrypt)이 끝나기 전에 요청 20개가 한꺼번에 들어온 상황
    for (let attempt = 0; attempt < 20; attempt += 1) {
      try {
        limiter.consume('me@example.com', 1_000);
        allowed += 1;
      } catch {
        // 막힌 요청
      }
    }

    expect(allowed).toBe(5);
  });

  it('1분이 지나면 다시 시도할 수 있다', () => {
    const limiter = new LoginRateLimiter();
    for (let attempt = 0; attempt < 5; attempt += 1) {
      limiter.consume('me@example.com', 1_000);
    }

    expect(() => limiter.consume('me@example.com', 61_000)).not.toThrow();
  });

  it('성공한 로그인은 시도 횟수를 초기화한다', () => {
    const limiter = new LoginRateLimiter();
    for (let attempt = 0; attempt < 4; attempt += 1) {
      limiter.consume('me@example.com', 1_000);
    }

    limiter.reset('me@example.com');

    for (let attempt = 0; attempt < 5; attempt += 1) {
      expect(() => limiter.consume('me@example.com', 1_000)).not.toThrow();
    }
  });

  it('1분이 지난 기록은 메모리에서 지운다', () => {
    const limiter = new LoginRateLimiter();
    for (let user = 0; user < 100; user += 1) {
      limiter.consume(`user${user}@example.com`, 1_000);
    }
    expect(limiter.trackedKeyCount()).toBe(100);

    limiter.consume('late@example.com', 61_000);

    expect(limiter.trackedKeyCount()).toBe(1);
  });

  it('아직 1분이 안 된 기록은 지우지 않는다', () => {
    const limiter = new LoginRateLimiter();
    limiter.consume('old@example.com', 1_000);
    limiter.consume('recent@example.com', 30_000);

    limiter.consume('late@example.com', 61_000);

    expect(limiter.trackedKeyCount()).toBe(2);
    for (let attempt = 0; attempt < 4; attempt += 1) {
      limiter.consume('recent@example.com', 61_000);
    }
    expect(() => limiter.consume('recent@example.com', 61_000)).toThrow(
      AppException,
    );
  });
});
