// Only creates new local test accounts and one metadata-only issue. No existing rows/volumes are deleted.
import { randomUUID, randomBytes } from 'node:crypto';
import { writeFile, mkdtemp } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const baseUrl = 'http://127.0.0.1:3000/api';
async function request(route, body, token) {
  const response = await fetch(baseUrl + route, {
    method: body ? 'POST' : 'GET',
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  if (!response.ok) throw new Error(`${route}: ${response.status}`);
  return response.json();
}
async function actor() {
  const suffix = randomBytes(4).toString('hex');
  const masthead = 't' + [...suffix].map(v => String.fromCharCode(97 + parseInt(v, 16))).join('');
  const password = randomBytes(24).toString('hex');
  const email = `core-${suffix}@example.com`;
  const session = await request('/auth/email/signup', { email, password });
  return { email, password, masthead, userId: session.userId, token: session.accessToken };
}
const owner = await actor();
const reader = await actor();
await request('/profile', { masthead: owner.masthead }, owner.token);
const today = await request('/today', null, owner.token);
const date = new Date(`${today.serviceDate}T00:00:00Z`);
date.setUTCDate(date.getUTCDate() - 1);
const day = date.toISOString().slice(0, 10);
const media = randomUUID(), issueId = randomUUID();
if (!/^[0-9a-f-]{36}$/.test(owner.userId)) throw new Error('Invalid test user ID');
const sql = `BEGIN;
INSERT INTO media_assets(id,owner_id,storage_key,status,mime_type,size_bytes,width,height,created_at,updated_at)
VALUES ('${media}','${owner.userId}','core-api-test/${media}.png','READY','image/png',1,1,1,NOW(),NOW());
INSERT INTO issues(id,author_id,service_date,issue_number,color_id,media_id,caption,face_crop,paint_stroke,published_at)
VALUES ('${issueId}','${owner.userId}','${day}',1,'sage','${media}','API integration fixture','ORIGINAL',false,NOW());
UPDATE profiles SET issue_count=1 WHERE user_id='${owner.userId}';
COMMIT;`;
const result = spawnSync('docker', ['compose', 'exec', '-T', 'postgres', 'psql', '-v', 'ON_ERROR_STOP=1', '-U', 'esel', '-d', 'esel'],
  { cwd: root, input: sql, encoding: 'utf8', windowsHide: true });
if (result.status !== 0) throw new Error('Fixture SQL failed. No cleanup or reset was attempted.');
delete owner.token; delete reader.token;
const directory = await mkdtemp(path.join(tmpdir(), 'esel-api-test-'));
const fixturePath = path.join(directory, 'fixture.json');
await writeFile(fixturePath, JSON.stringify({ owner, reader, issueId, baseUrl }), { mode: 0o600 });
// Only the path is printed; the file contains temporary test credentials. Never commit it.
process.stdout.write(fixturePath + '\n');
