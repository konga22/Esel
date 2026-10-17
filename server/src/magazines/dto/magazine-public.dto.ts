import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IssuePublicDto } from '../../issues/dto/issue-public.dto.js';

export class MagazinePublicDto {
  @ApiProperty({ example: 'selin' })
  masthead: string;

  @ApiProperty({ minimum: 0, description: '발행으로만 증가하는 공개 호수' })
  issueCount: number;

  @ApiProperty({ description: '요청한 사용자의 구독 상태' })
  isSubscribed: boolean;

  @ApiProperty({ type: IssuePublicDto, isArray: true })
  issues: IssuePublicDto[];

  @ApiPropertyOptional({ nullable: true, type: String })
  nextCursor: string | null;
}
