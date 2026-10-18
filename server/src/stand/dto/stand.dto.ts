import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IssuePublicDto } from '../../issues/dto/issue-public.dto.js';
import { ColorDto } from '../../today/dto/color.dto.js';

export class StandDto {
  @ApiProperty({ example: '2026-10-18' })
  serviceDate: string;

  @ApiProperty({ type: ColorDto })
  color: ColorDto;

  @ApiProperty({ description: '오늘 후보색 미리보기 상태' })
  locked: boolean;

  @ApiProperty({ description: '미래 날짜라 닫힌 상태' })
  closed: boolean;

  @ApiProperty({ minimum: 0, description: '잠겨서 ID 없이 감춘 사진 개수' })
  hiddenCount: number;

  @ApiProperty({ type: IssuePublicDto, isArray: true })
  items: IssuePublicDto[];

  @ApiPropertyOptional({ nullable: true })
  nextCursor: string | null;
}
