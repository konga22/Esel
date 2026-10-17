import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IssueMediaDto } from '../../issues/dto/issue-media.dto.js';
import { ColorDto } from '../../today/dto/color.dto.js';

export class DayRecordDto {
  @ApiProperty({ example: '2026-10-07' })
  serviceDate: string;

  @ApiProperty({ enum: ['ISSUE', 'RESTORED'] })
  kind: 'ISSUE' | 'RESTORED';

  @ApiProperty({ type: ColorDto })
  color: ColorDto;

  @ApiPropertyOptional({ nullable: true, format: 'uuid' })
  issueId: string | null;

  @ApiPropertyOptional({ nullable: true, type: IssueMediaDto })
  media: IssueMediaDto | null;
}
