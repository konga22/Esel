import { Injectable } from '@nestjs/common';
import { AppException } from '../common/app-exception.js';

const WINDOW_MS = 60_000;
const MAX_ATTEMPTS = 5;

interface AttemptWindow {
  count: number;
  startedAt: number;
}

/** 외부 서비스 없이 한 서버 프로세스 안에서 가입 폭주를 완화한다. */
@Injectable()
export class SignupRateLimiter {
  private readonly attempts = new Map<string, AttemptWindow>();

  consume(key: string, now = Date.now()): void {
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
}
