import { ApiProperty } from '@nestjs/swagger';
import { ColorDto } from '../../today/dto/color.dto.js';
import { IssueMediaDto } from './issue-media.dto.js';

export class IssuePublicDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

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

  @ApiProperty({ description: '요청한 사용자가 좋아요를 눌렀는지' })
  liked: boolean;

  @ApiProperty({ description: '요청한 사용자가 스크랩했는지' })
  scrapped: boolean;
}
