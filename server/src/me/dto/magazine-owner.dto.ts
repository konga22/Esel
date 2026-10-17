import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IssueOwnerDto } from '../../issues/dto/issue-owner.dto.js';

export class MagazineOwnerDto {
  @ApiPropertyOptional({ nullable: true, example: 'selin' })
  masthead: string | null;

  @ApiProperty({ minimum: 0, description: '발행으로만 증가하는 호수' })
  issueCount: number;

  @ApiPropertyOptional({ nullable: true, type: IssueOwnerDto })
  todayIssue: IssueOwnerDto | null;

  @ApiProperty({ type: IssueOwnerDto, isArray: true })
  pastIssues: IssueOwnerDto[];

  @ApiPropertyOptional({ nullable: true, type: String })
  nextCursor: string | null;
}
