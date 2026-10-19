import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IssueGarmentDto } from '../../issues/dto/issue-garment.dto.js';
import { IssueMediaDto } from '../../issues/dto/issue-media.dto.js';
import { ColorDto } from './color.dto.js';

export class TodayCoverIssueDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ example: 'selin' })
  masthead: string;

  @ApiProperty({ minimum: 1 })
  issueNumber: number;

  @ApiProperty({ format: 'date-time' })
  publishedAt: string;

  @ApiProperty({ type: ColorDto })
  color: ColorDto;

  @ApiProperty({ type: IssueMediaDto })
  media: IssueMediaDto;

  @ApiProperty({ maxLength: 280 })
  caption: string;

  @ApiProperty({ enum: ['ORIGINAL', 'BEHIND_LOGO', 'BELOW_NECK'] })
  faceCrop: string;

  @ApiProperty({ description: '얼굴 위 물감 한 획 사용 여부' })
  paintStroke: boolean;

  @ApiProperty({ type: IssueGarmentDto, isArray: true })
  garments: IssueGarmentDto[];
}

export class TodayCoverPublicDto {
  @ApiProperty({ example: '2026-10-18' })
  serviceDate: string;

  @ApiPropertyOptional({ type: TodayCoverIssueDto, nullable: true })
  cover: TodayCoverIssueDto | null;

  @ApiProperty({ type: TodayCoverIssueDto, isArray: true, maxItems: 2 })
  pages: TodayCoverIssueDto[];
}
