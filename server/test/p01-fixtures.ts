import { randomUUID } from 'node:crypto';
import { PrismaService } from '../src/prisma/prisma.service.js';

export async function createLockedIssuePerCandidate(
  prisma: PrismaService,
  candidateIds: string[],
  serviceDateKey: string,
  emailDomain: string,
  storagePrefix: string,
): Promise<string[]> {
  const lockedIds: string[] = [];
  let authorIndex = 0;

  for (const colorId of candidateIds) {
    for (let position = 0; position < 4; position += 1) {
      const suffix = randomUUID().replaceAll('-', '');
      const mastheadSuffix = suffix
        .slice(0, 9)
        .replace(/[0-9]/g, (digit) =>
          String.fromCharCode('g'.charCodeAt(0) + Number(digit)),
        );
      const author = await prisma.user.create({
        data: {
          email: `${suffix}@${emailDomain}`,
          profile: {
            create: { masthead: `p${mastheadSuffix}` },
          },
        },
      });
      const media = await prisma.mediaAsset.create({
        data: {
          ownerId: author.id,
          storageKey: `${storagePrefix}/${suffix}`,
          status: 'READY',
          mimeType: 'image/png',
          sizeBytes: 24,
          width: 1080,
          height: 1440,
        },
      });
      const issue = await prisma.issue.create({
        data: {
          authorId: author.id,
          serviceDate: new Date(`${serviceDateKey}T00:00:00.000Z`),
          issueNumber: 1,
          colorId,
          mediaId: media.id,
          caption: `P01 후보 ${authorIndex++}`,
          faceCrop: 'ORIGINAL',
          paintStroke: false,
          publishedAt:
            position === 0
              ? new Date('2000-01-01T00:00:00.000Z')
              : new Date(`2099-01-0${position}T00:00:00.000Z`),
        },
      });
      if (position === 0) lockedIds.push(issue.id);
    }
  }

  return lockedIds;
}
