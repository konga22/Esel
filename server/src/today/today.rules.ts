const CANDIDATE_COUNT = 3;
const RANDOM_MODULUS = 2_147_483_647;
const DEMO_DATE = '2026-09-06';
const DEMO_CANDIDATES = ['camel', 'lilac', 'olive'] as const;

/**
 * 같은 서비스 날짜에는 모든 사용자에게 같은 세 색을 돌려주는 임시 규칙.
 * 실제 확률과 희귀 팔레트 정책이 정해지기 전까지 Flutter 데모와 같은 계산을 쓴다.
 */
export function dailyCandidateIds(
  serviceDate: string,
  orderedColorIds: readonly string[],
): string[] {
  if (orderedColorIds.length < CANDIDATE_COUNT) {
    throw new Error('오늘의 색을 고르려면 DB에 색이 3개 이상 있어야 해요.');
  }

  if (
    serviceDate === DEMO_DATE &&
    DEMO_CANDIDATES.every((id) => orderedColorIds.includes(id))
  ) {
    return [...DEMO_CANDIDATES];
  }

  let state = 1;
  const seed = `esel|${serviceDate}`;
  for (let index = 0; index < seed.length; index += 1) {
    state = (state * 31 + seed.charCodeAt(index)) % RANDOM_MODULUS;
  }
  if (state === 0) state = 1;

  const pool = [...orderedColorIds];
  const picked: string[] = [];
  for (let index = 0; index < CANDIDATE_COUNT; index += 1) {
    state = (state * 48_271) % RANDOM_MODULUS;
    const pickedIndex = state % pool.length;
    const [pickedId] = pool.splice(pickedIndex, 1);
    if (!pickedId) throw new Error('오늘의 색 후보를 고르지 못했어요.');
    picked.push(pickedId);
  }
  return picked;
}
