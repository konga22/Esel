const RANDOM_MODULUS = 2_147_483_647;

export interface TwinCandidates {
  userA: string[];
  userB: string[];
}

export function twinCandidateIds(
  key: string,
  orderedColorIds: readonly string[],
): TwinCandidates {
  if (orderedColorIds.length < 5) {
    throw new Error('트윈 후보를 고르려면 DB에 색이 5개 이상 있어야 해요.');
  }
  let state = 1;
  const seed = `esel|twin|${key}`;
  for (let index = 0; index < seed.length; index += 1) {
    state = (state * 31 + seed.charCodeAt(index)) % RANDOM_MODULUS;
  }
  if (state === 0) state = 1;

  const pool = [...orderedColorIds];
  const picked: string[] = [];
  for (let index = 0; index < 5; index += 1) {
    state = (state * 48_271) % RANDOM_MODULUS;
    const pickedIndex = state % pool.length;
    const [colorId] = pool.splice(pickedIndex, 1);
    if (!colorId) throw new Error('트윈 색 후보를 고르지 못했어요.');
    picked.push(colorId);
  }
  return {
    userA: [picked[0]!, picked[1]!, picked[2]!],
    userB: [picked[0]!, picked[3]!, picked[4]!],
  };
}
