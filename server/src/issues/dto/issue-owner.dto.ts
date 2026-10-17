import { ApiProperty } from '@nestjs/swagger';
import { IssuePublicDto } from './issue-public.dto.js';

export class IssueOwnerDto extends IssuePublicDto {
  @ApiProperty({ minimum: 0, description: '발행한 본인에게만 제공' })
  likeCount: number;

  @ApiProperty({ minimum: 0, description: '발행한 본인에게만 제공' })
  scrapCount: number;

  @ApiProperty({ minimum: 0, description: '발행한 본인에게만 제공' })
  lineCount: number;
}
