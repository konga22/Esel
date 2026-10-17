import { isWriteConflict } from './is-write-conflict.js';

describe('isWriteConflict', () => {
  it('Prisma P2034 오류를 쓰기 충돌로 판별한다', () => {
    expect(isWriteConflict({ code: 'P2034' })).toBe(true);
  });

  it('adapter-pg DriverAdapterError를 쓰기 충돌로 판별한다', () => {
    expect(
      isWriteConflict({
        name: 'DriverAdapterError',
        message: 'TransactionWriteConflict',
        cause: { kind: 'TransactionWriteConflict' },
      }),
    ).toBe(true);
  });

  it('관계없는 데이터베이스 오류는 쓰기 충돌이 아니다', () => {
    expect(isWriteConflict({ code: 'P2002' })).toBe(false);
  });
});
