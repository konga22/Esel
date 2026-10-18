import { ApiProperty } from '@nestjs/swagger';
import { IssuePublicDto } from '../../issues/dto/issue-public.dto.js';

export class FeedItemDto extends IssuePublicDto {
  @ApiProperty({ enum: ['SUBSCRIPTION', 'RECOMMENDED'] })
  source: 'SUBSCRIPTION' | 'RECOMMENDED';
}
