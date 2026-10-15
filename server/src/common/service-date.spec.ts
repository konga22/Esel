import { describe, expect, it } from 'vitest';
import { isValidTimeZone, serviceDate } from './service-date.js';

describe('serviceDate', () => {
  const seoul = 'Asia/Seoul';

  it('한국 시간 자정 직전은 아직 전날이다', () => {
    // 2026-10-14T14:59:59Z = 한국 시간 10월 14일 23:59:59
    expect(serviceDate(new Date('2026-10-14T14:59:59Z'), seoul)).toBe(
      '2026-10-14',
    );
  });

  it('한국 시간 0시와 0시 1분은 새 날짜다', () => {
    expect(serviceDate(new Date('2026-10-14T15:00:00Z'), seoul)).toBe(
      '2026-10-15',
    );
    expect(serviceDate(new Date('2026-10-14T15:01:00Z'), seoul)).toBe(
      '2026-10-15',
    );
  });

  it('같은 순간이라도 시간대가 다르면 날짜가 다를 수 있다', () => {
    const moment = new Date('2026-10-14T15:30:00Z');
    expect(serviceDate(moment, seoul)).toBe('2026-10-15');
    expect(serviceDate(moment, 'UTC')).toBe('2026-10-14');
  });

  it('달과 해가 바뀌는 자정도 맞게 넘어간다', () => {
    expect(serviceDate(new Date('2026-12-31T15:00:00Z'), seoul)).toBe(
      '2027-01-01',
    );
    expect(serviceDate(new Date('2026-02-28T15:00:00Z'), seoul)).toBe(
      '2026-03-01',
    );
  });
});

describe('isValidTimeZone', () => {
  it('IANA 시간대 이름은 통과한다', () => {
    expect(isValidTimeZone('Asia/Seoul')).toBe(true);
    expect(isValidTimeZone('UTC')).toBe(true);
  });

  it('없는 이름과 빈 값은 거절한다', () => {
    expect(isValidTimeZone('Mars/Base')).toBe(false);
    expect(isValidTimeZone('')).toBe(false);
  });
});
