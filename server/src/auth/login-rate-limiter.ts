import { Injectable } from '@nestjs/common';
import { AppException } from '../common/app-exception.js';

const WINDOW_MS = 60_000;
const MAX_ATTEMPTS = 5;

interface AttemptWindow {
  count: number;
  startedAt: number;
}

/**
 * 외부 서비스 없이 한 서버 프로세스 안에서 로그인 대입 공격을 완화한다.
 *
 * - 비밀번호를 확인하기 **전에** `consume`으로 시도를 센다. 그래서 제한에 걸린 동안에는
 *   비밀번호가 맞아도 429이고, 비밀번호 확인이 끝나기 전에 몰려온 동시 요청도 다섯 개까지만 통과한다.
 * - 로그인이 성공하면 `reset`으로 기록을 지운다.
 * - 1분이 지난 기록은 1분에 한 번씩 정리해 메모리에 계속 쌓이지 않게 한다.
 */
@Injectable()
export class LoginRateLimiter {
  private readonly attempts = new Map<string, AttemptWindow>();
  private lastSweptAt = 0;

  consume(key: string, now = Date.now()): void {
    this.sweepExpired(now);

    const current = this.attempts.get(key);
    if (!current || now - current.startedAt >= WINDOW_MS) {
      this.attempts.set(key, { count: 1, startedAt: now });
      return;
    }
    if (current.count >= MAX_ATTEMPTS) {
      throw new AppException('RATE_LIMITED');
    }
    current.count += 1;
  }

  reset(key: string): void {
    this.attempts.delete(key);
  }

  /** 테스트에서 정리 여부를 확인하려고 둔 값이다. */
  trackedKeyCount(): number {
    return this.attempts.size;
  }

  private sweepExpired(now: number): void {
    if (now - this.lastSweptAt < WINDOW_MS) return;
    this.lastSweptAt = now;
    for (const [key, window] of this.attempts) {
      if (now - window.startedAt >= WINDOW_MS) this.attempts.delete(key);
    }
  }
}
