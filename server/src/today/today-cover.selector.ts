import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';

@Injectable()
export class TodayCoverSelector {
  constructor(private readonly prisma: PrismaService) {}

  async issueIds(date: Date): Promise<string[]> {
    const issues = await this.prisma.issue.findMany({
      where: {
        serviceDate: date,
        deletedAt: null,
        author: { profile: { isNot: null } },
      },
      orderBy: [{ publishedAt: 'desc' }, { id: 'desc' }],
      take: 3,
      select: { id: true },
    });
    return issues.map(({ id }) => id);
  }
}
