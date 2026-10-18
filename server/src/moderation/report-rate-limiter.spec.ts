import { AppException } from '../common/app-exception.js';
import { ReportRateLimiter } from './report-rate-limiter.js';

describe('ReportRateLimiter', () => {
  it('한 사용자의 1분 내 여섯 번째 신고를 막는다', () => {
    const limiter = new ReportRateLimiter();
    for (let index = 0; index < 5; index += 1) limiter.consume('user', 0);
    expect(() => limiter.consume('user', 0)).toThrowError(AppException);
  });

  it('1분이 지나면 새 창으로 센다', () => {
    const limiter = new ReportRateLimiter();
    for (let index = 0; index < 5; index += 1) limiter.consume('user', 0);
    expect(() => limiter.consume('user', 60_000)).not.toThrow();
  });
});
