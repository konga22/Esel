import { Prisma } from '../generated/prisma/client.js';

type ErrorShape = {
  code?: unknown;
  name?: unknown;
  message?: unknown;
  cause?: unknown;
};

/** Prisma 엔진과 driver adapter가 돌려주는 직렬화 충돌을 같은 오류로 판별한다. */
export function isWriteConflict(error: unknown): boolean {
  if (
    error instanceof Prisma.PrismaClientKnownRequestError &&
    error.code === 'P2034'
  ) {
    return true;
  }

  if (!error || typeof error !== 'object') return false;
  const value = error as ErrorShape;
  if (value.code === 'P2034') return true;
  if (
    value.name === 'DriverAdapterError' &&
    (String(value.message).includes('TransactionWriteConflict') ||
      hasTransactionWriteConflict(value.cause))
  ) {
    return true;
  }
  return hasTransactionWriteConflict(value.cause);
}

function hasTransactionWriteConflict(value: unknown): boolean {
  if (!value || typeof value !== 'object') return false;
  const cause = value as ErrorShape & { kind?: unknown };
  return (
    cause.kind === 'TransactionWriteConflict' ||
    cause.code === 'P2034' ||
    String(cause.message).includes('TransactionWriteConflict')
  );
}
