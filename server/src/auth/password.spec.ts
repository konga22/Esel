import { hashPassword } from './password.js';

describe('hashPassword', () => {
  it('비밀번호 원문을 저장하지 않고 같은 비밀번호도 서로 다른 해시를 만든다', async () => {
    const first = await hashPassword('correct horse battery staple');
    const second = await hashPassword('correct horse battery staple');

    expect(first).toMatch(/^scrypt\$[^$]+\$[^$]+$/);
    expect(second).toMatch(/^scrypt\$[^$]+\$[^$]+$/);
    expect(first).not.toContain('correct horse battery staple');
    expect(second).not.toBe(first);
  });
});
