import { twinCandidateIds } from './twins.rules.js';

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
];

describe('twinCandidateIds', () => {
  it('각자 세 색을 받고 교집합은 정확히 한 색이다', () => {
    const result = twinCandidateIds('2026-10-18:a:b', COLORS);
    expect(result.userA).toHaveLength(3);
    expect(result.userB).toHaveLength(3);
    expect(result.userA.filter((id) => result.userB.includes(id))).toHaveLength(
      1,
    );
  });

  it('같은 날짜와 두 사람은 항상 같은 후보를 받는다', () => {
    expect(twinCandidateIds('2026-10-18:a:b', COLORS)).toEqual(
      twinCandidateIds('2026-10-18:a:b', COLORS),
    );
  });

  it('입력 배열을 바꾸지 않고 다섯 색 미만이면 멈춘다', () => {
    const colors = [...COLORS];
    twinCandidateIds('2026-10-18:a:b', colors);
    expect(colors).toEqual(COLORS);
    expect(() => twinCandidateIds('key', colors.slice(0, 4))).toThrow(
      '5개 이상',
    );
  });
});
