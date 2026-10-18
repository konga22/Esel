import { Injectable } from '@nestjs/common';
import { AppException } from '../common/app-exception.js';

const WINDOW_MS = 60_000;
const MAX_REPORTS = 5;

interface ReportWindow {
  count: number;
  startedAt: number;
}

/** 외부 서비스 없이 한 서버 프로세스 안에서 신고 도배를 완화한다. */
@Injectable()
export class ReportRateLimiter {
  private readonly windows = new Map<string, ReportWindow>();

  consume(userId: string, now = Date.now()): void {
    const current = this.windows.get(userId);
    if (!current || now - current.startedAt >= WINDOW_MS) {
      this.windows.set(userId, { count: 1, startedAt: now });
      return;
    }
    if (current.count >= MAX_REPORTS) throw new AppException('RATE_LIMITED');
    current.count += 1;
  }
}
