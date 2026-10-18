import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IssueGarmentDto } from '../../issues/dto/issue-garment.dto.js';
import { IssueMediaDto } from '../../issues/dto/issue-media.dto.js';
import { ColorDto } from '../../today/dto/color.dto.js';

export class SharedIssueDto {
  @ApiProperty({ example: 'selin' })
  masthead: string;

  @ApiProperty({ minimum: 1 })
  issueNumber: number;

  @ApiProperty({ example: '2026-10-18' })
  serviceDate: string;

  @ApiProperty({ format: 'date-time' })
  publishedAt: string;

  @ApiProperty({ type: ColorDto })
  color: ColorDto;

  @ApiProperty({ type: IssueMediaDto })
  media: IssueMediaDto;

  @ApiProperty({ maxLength: 280 })
  caption: string;

  @ApiProperty({ enum: ['PLAIN', 'PAINT', 'BEHIND_MASTHEAD', 'NECK_DOWN'] })
  faceMode: string;

  @ApiProperty({ type: IssueGarmentDto, isArray: true })
  garments: IssueGarmentDto[];
}

export class SharedTwinPostDto {
  @ApiProperty({ example: 'selin' })
  masthead: string;

  @ApiProperty({ type: ColorDto })
  color: ColorDto;

  @ApiProperty({ type: IssueMediaDto })
  media: IssueMediaDto;

  @ApiProperty({ format: 'date-time' })
  postedAt: string;
}

export class SharedTwinDto {
  @ApiProperty({ example: '2026-10-18' })
  serviceDate: string;

  @ApiProperty({ format: 'date-time' })
  publishedAt: string;

  @ApiProperty({ type: SharedTwinPostDto, isArray: true })
  posts: SharedTwinPostDto[];
}

export class SharedIssuePublicDto {
  @ApiProperty({ enum: ['ISSUE', 'TWIN'] })
  kind: 'ISSUE' | 'TWIN';

  @ApiPropertyOptional({ type: SharedIssueDto, nullable: true })
  issue: SharedIssueDto | null;

  @ApiPropertyOptional({ type: SharedTwinDto, nullable: true })
  twin: SharedTwinDto | null;
}
