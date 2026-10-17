import { randomBytes, scrypt, timingSafeEqual } from 'node:crypto';
import { promisify } from 'node:util';

const scryptAsync = promisify(scrypt);
const KEY_LENGTH = 64;

/** 비밀번호 원문 대신 salt와 scrypt 결과만 저장한다. */
export async function hashPassword(password: string): Promise<string> {
  const salt = randomBytes(16).toString('base64url');
  const derivedKey = (await scryptAsync(password, salt, KEY_LENGTH)) as Buffer;
  return `scrypt$${salt}$${derivedKey.toString('base64url')}`;
}

/** 저장된 scrypt 해시와 입력한 비밀번호를 일정 시간 비교로 확인한다. */
export async function verifyPassword(
  password: string,
  storedHash: string,
): Promise<boolean> {
  const [algorithm, salt, encodedKey, ...extra] = storedHash.split('$');
  if (algorithm !== 'scrypt' || !salt || !encodedKey || extra.length) {
    return false;
  }

  const expected = Buffer.from(encodedKey, 'base64url');
  if (expected.length !== KEY_LENGTH) return false;

  const actual = (await scryptAsync(password, salt, KEY_LENGTH)) as Buffer;
  return timingSafeEqual(actual, expected);
}
