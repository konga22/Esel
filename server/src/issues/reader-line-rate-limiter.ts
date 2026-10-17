import { Injectable } from '@nestjs/common';
import { AppException } from '../common/app-exception.js';

const WINDOW_MS = 60_000;
const MAX_LINES = 5;

interface LineWindow {
  count: number;
  startedAt: number;
}

/** 외부 서비스 없이 한 서버 프로세스 안에서 같은 호의 한 줄 도배를 완화한다. */
@Injectable()
export class ReaderLineRateLimiter {
  private readonly windows = new Map<string, LineWindow>();

  consume(key: string, now = Date.now()): void {
    const current = this.windows.get(key);
    if (!current || now - current.startedAt >= WINDOW_MS) {
      this.windows.set(key, { count: 1, startedAt: now });
      return;
    }
    if (current.count >= MAX_LINES) throw new AppException('RATE_LIMITED');
    current.count += 1;
  }
}
