import { dailyCandidateIds } from './today.rules.js';

const COLORS = [
  'sage',
  'butter',
  'powder',
  'coral',
  'lilac',
  'terracotta',
  'burgundy',
  'olive',
  'cream',
  'charcoal',
  'camel',
  'cobalt',
] as const;

describe('dailyCandidateIds', () => {
  it('디자인 기준일에 카멜·라일락·올리브를 돌려준다', () => {
    expect(dailyCandidateIds('2026-09-06', COLORS)).toEqual([
      'camel',
      'lilac',
      'olive',
    ]);
  });

  it('같은 날짜와 색 순서는 언제나 같은 후보를 만든다', () => {
    expect(dailyCandidateIds('2026-10-17', COLORS)).toEqual([
      'lilac',
      'butter',
      'charcoal',
    ]);
  });

  it('120일 동안 매일 서로 다른 정식 3색만 고른다', () => {
    for (let day = 1; day <= 120; day += 1) {
      const date = new Date(Date.UTC(2026, 0, day)).toISOString().slice(0, 10);
      const result = dailyCandidateIds(date, COLORS);
      expect(result).toHaveLength(3);
      expect(new Set(result)).toHaveLength(3);
      expect(
        result.every((id) => COLORS.includes(id as (typeof COLORS)[number])),
      ).toBe(true);
    }
  });

  it('받은 색 배열을 바꾸지 않는다', () => {
    const colors = [...COLORS];
    dailyCandidateIds('2026-10-17', colors);
    expect(colors).toEqual(COLORS);
  });

  it('색이 3개보다 적으면 설정 오류로 멈춘다', () => {
    expect(() => dailyCandidateIds('2026-10-17', ['sage', 'camel'])).toThrow(
      'DB에 색이 3개 이상',
    );
  });
});
