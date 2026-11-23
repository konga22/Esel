// 탈퇴(DELETE /me) 실서버 확인용 준비 도구. 로컬 서버(127.0.0.1:3000) 전용.
// 서버 API만 써서 새 테스트 계정 두 개를 만든다. 기존 계정·DB·사진은 지우거나 바꾸지 않는다.
//   - 탈퇴자: 사인·소개·알림 설정·오늘의 색·사진 있는 오늘 캔버스(착용 정보 1개)
//   - 다른 사람: 그 캔버스에 저장·좋아요·한 줄, 탈퇴자 스케치북 구독
// 출력은 fixture 파일 경로 한 줄뿐이다. 파일에 임시 비밀번호가 있으니 커밋하거나 채팅에 붙이지 않는다.
import { randomBytes } from 'node:crypto';
import { readFile, writeFile, mkdtemp } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const origin = 'http://127.0.0.1:3000';
const baseUrl = `${origin}/api`;

async function call(method, route, { body, token, raw } = {}) {
  const headers = token ? { Authorization: `Bearer ${token}` } : {};
  let payload;
  if (raw) {
    headers['Content-Type'] = raw.type;
    payload = raw.bytes;
  } else if (body !== undefined) {
    headers['Content-Type'] = 'application/json';
    payload = JSON.stringify(body);
  }
  const url = route.startsWith('http') ? route : route.startsWith('/api') ? origin + route : baseUrl + route;
  const response = await fetch(url, { method, headers, body: payload });
  const text = await response.text();
  if (!response.ok) throw new Error(`${method} ${route}: ${response.status}`);
  return text ? JSON.parse(text) : null;
}

const tag = randomBytes(3).toString('hex');
const letters = (prefix) => prefix + [...tag].map((c) => String.fromCharCode(97 + (parseInt(c, 16) % 26))).join('');

async function account(prefix) {
  const email = `delete-${prefix}-${tag}@example.test`;
  const password = randomBytes(16).toString('hex');
  const session = await call('POST', '/auth/email/signup', { body: { email, password } });
  const masthead = letters(prefix);
  await call('POST', '/profile', { body: { masthead }, token: session.accessToken });
  return { email, password, masthead, token: session.accessToken };
}

const victim = await account('dv');
const other = await account('do');

await call('PATCH', '/me/profile', { body: { bio: '탈퇴 확인용 소개' }, token: victim.token });
await call('PUT', '/me/notifications', {
  body: { enabled: true, newIssue: false, reactions: true },
  token: victim.token,
});
const today = await call('GET', '/today', { token: victim.token });
await call('PUT', '/today/choice', { body: { colorId: today.candidates[0].id }, token: victim.token });

const bytes = await readFile(path.join(root, 'assets/models/sage-01.jpg'));
const media = await call('POST', '/media', {
  body: { mimeType: 'image/jpeg', sizeBytes: bytes.length },
  token: victim.token,
});
await call('PUT', media.uploadUrl, { token: victim.token, raw: { type: 'image/jpeg', bytes } });
await call('POST', `/media/${media.id}/complete`, { token: victim.token });
const issue = await call('POST', '/issues', {
  body: {
    mediaId: media.id,
    caption: '탈퇴 확인용 캔버스',
    faceCrop: 'BELOW_NECK',
    paintStroke: false,
    garments: [{ kind: '셔츠', name: '확인용 셔츠' }],
  },
  token: victim.token,
});

await call('POST', `/issues/${issue.id}/scrap`, { token: other.token });
await call('POST', `/issues/${issue.id}/like`, { token: other.token });
await call('POST', `/issues/${issue.id}/lines`, { body: { text: '탈퇴 확인용 한 줄' }, token: other.token });
await call('POST', `/magazines/${victim.masthead}/subscription`, { token: other.token });

delete victim.token;
delete other.token;
const directory = await mkdtemp(path.join(tmpdir(), 'esel-delete-test-'));
const fixturePath = path.join(directory, 'fixture.json');
await writeFile(
  fixturePath,
  JSON.stringify({ baseUrl, victim, other, issueId: issue.id, mediaId: media.id }),
  { mode: 0o600 },
);
process.stdout.write(fixturePath + '\n');
