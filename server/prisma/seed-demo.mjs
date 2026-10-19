import { PrismaPg } from '@prisma/adapter-pg';
// Docker의 build 단계에서 생성된 JS 클라이언트를 사용한다.
import { PrismaClient } from '../dist/generated/prisma/client.js';
import { createHash } from 'node:crypto';
import { copyFile, mkdir, stat } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import sharp from 'sharp';

const directory = path.dirname(fileURLToPath(import.meta.url));
const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) throw new Error('DATABASE_URL이 필요합니다.');

const storageRoot = path.resolve(
  process.env.MEDIA_STORAGE_ROOT ?? path.join(directory, '../data/media'),
);
const assetRoot = path.resolve(
  process.env.DEMO_ASSET_ROOT ?? path.join(directory, '../../assets/demo'),
);
const timeZone = process.env.SERVICE_TIME_ZONE ?? 'Asia/Seoul';
const serviceDate = new Intl.DateTimeFormat('en-CA', {
  timeZone,
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
}).format(new Date());
const date = new Date(`${serviceDate}T00:00:00.000Z`);

const people = [
  {
    id: '10000000-0000-4000-8000-000000000001',
    masthead: 'dana',
    colorId: 'powder',
    asset: 'blue-city.jpg',
    caption: '도시의 파란빛을 입은 오늘.',
    faceCrop: 'ORIGINAL',
    paintStroke: false,
  },
  {
    id: '10000000-0000-4000-8000-000000000002',
    masthead: 'ama',
    colorId: 'butter',
    asset: 'yellow-dress.jpg',
    caption: '햇살 같은 버터 컬러.',
    faceCrop: 'BEHIND_LOGO',
    paintStroke: true,
  },
  {
    id: '10000000-0000-4000-8000-000000000003',
    masthead: 'elin',
    colorId: 'sage',
    asset: 'green-blouse.jpg',
    caption: '차분한 세이지로 남긴 하루.',
    faceCrop: 'BEHIND_LOGO',
    paintStroke: false,
  },
  {
    id: '10000000-0000-4000-8000-000000000004',
    masthead: 'noor',
    colorId: 'camel',
    asset: 'beige-blazer.jpg',
    caption: '익숙한 재킷을 새로운 표지로.',
    faceCrop: 'ORIGINAL',
    paintStroke: true,
  },
  {
    id: '10000000-0000-4000-8000-000000000005',
    masthead: 'sol',
    colorId: 'cobalt',
    asset: 'blue-outfit.jpg',
    caption: '선명한 코발트 한 장.',
    faceCrop: 'BELOW_NECK',
    paintStroke: false,
  },
];

const prisma = new PrismaClient({
  adapter: new PrismaPg({ connectionString: databaseUrl }),
});

function stableUuid(value) {
  const hex = createHash('sha256').update(value).digest('hex').slice(0, 32);
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-4${hex.slice(13, 16)}-8${hex.slice(17, 20)}-${hex.slice(20)}`;
}

async function seedPerson(person, index) {
  const mediaId = stableUuid(`esel-demo-media:${serviceDate}:${person.id}`);
  const issueId = stableUuid(`esel-demo-issue:${serviceDate}:${person.id}`);
  const storageKey = `demo/${serviceDate}/${person.asset}`;
  const source = path.join(assetRoot, person.asset);
  const original = path.join(storageRoot, storageKey);
  const thumbnail = path.join(storageRoot, 'thumbs', `${mediaId}.jpg`);
  await Promise.all([
    mkdir(path.dirname(original), { recursive: true }),
    mkdir(path.dirname(thumbnail), { recursive: true }),
  ]);
  await copyFile(source, original);
  const metadata = await sharp(source).metadata();
  await sharp(source)
    .rotate()
    .resize(480, 480, { fit: 'inside', withoutEnlargement: true })
    .jpeg({ quality: 72, mozjpeg: true })
    .toFile(thumbnail);

  await prisma.user.upsert({
    where: { id: person.id },
    create: { id: person.id },
    update: {},
  });
  await prisma.profile.upsert({
    where: { userId: person.id },
    create: {
      userId: person.id,
      masthead: person.masthead,
      bio: 'Esel 시연용 예시 스케치북',
    },
    update: { masthead: person.masthead },
  });
  const sizeBytes = (await stat(source)).size;
  await prisma.mediaAsset.upsert({
    where: { id: mediaId },
    create: {
      id: mediaId,
      ownerId: person.id,
      storageKey,
      status: 'READY',
      mimeType: 'image/jpeg',
      sizeBytes,
      width: metadata.width,
      height: metadata.height,
    },
    update: {
      storageKey,
      status: 'READY',
      mimeType: 'image/jpeg',
      sizeBytes,
      width: metadata.width,
      height: metadata.height,
    },
  });
  await prisma.userDailyChoice.upsert({
    where: { userId_serviceDate: { userId: person.id, serviceDate: date } },
    create: {
      userId: person.id,
      serviceDate: date,
      colorId: person.colorId,
      lockedAt: new Date(),
    },
    update: { colorId: person.colorId, lockedAt: new Date() },
  });
  await prisma.issue.upsert({
    where: { authorId_serviceDate: { authorId: person.id, serviceDate: date } },
    create: {
      id: issueId,
      authorId: person.id,
      serviceDate: date,
      issueNumber: 1,
      colorId: person.colorId,
      mediaId,
      caption: person.caption,
      faceCrop: person.faceCrop,
      paintStroke: person.paintStroke,
      publishedAt: new Date(Date.now() - index * 60_000),
    },
    update: {
      colorId: person.colorId,
      caption: person.caption,
      faceCrop: person.faceCrop,
      paintStroke: person.paintStroke,
      deletedAt: null,
    },
  });
  await prisma.profile.update({
    where: { userId: person.id },
    data: {
      issueCount: await prisma.issue.count({ where: { authorId: person.id } }),
    },
  });
}

try {
  for (const [index, person] of people.entries()) {
    await seedPerson(person, index);
  }
  process.stdout.write(
    `Esel 시연 데이터 준비 완료: ${serviceDate}, 예시 표지 ${people.length}장\n`,
  );
} finally {
  await prisma.$disconnect();
}
