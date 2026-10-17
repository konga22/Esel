import { ApiProperty } from '@nestjs/swagger';
import { ReaderLinePublicDto } from '../../issues/dto/reader-line-public.dto.js';
import { ReactionUserDto } from './reaction-user.dto.js';

export class IssueReactionsOwnerDto {
  @ApiProperty({ format: 'uuid' })
  issueId: string;

  @ApiProperty({ minimum: 0 })
  likeCount: number;

  @ApiProperty({ minimum: 0 })
  scrapCount: number;

  @ApiProperty({ minimum: 0 })
  lineCount: number;

  @ApiProperty({ type: ReactionUserDto, isArray: true })
  likes: ReactionUserDto[];

  @ApiProperty({ type: ReactionUserDto, isArray: true })
  scraps: ReactionUserDto[];

  @ApiProperty({ type: ReaderLinePublicDto, isArray: true })
  lines: ReaderLinePublicDto[];
}
