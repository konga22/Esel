import { ApiProperty } from '@nestjs/swagger';
import { IssueMediaDto } from '../../issues/dto/issue-media.dto.js';
import { ColorDto } from '../../today/dto/color.dto.js';

export class PaletteTileDto {
  @ApiProperty({ format: 'uuid' })
  issueId: string;

  @ApiProperty({ example: 'selin' })
  masthead: string;

  @ApiProperty({ example: '2026-10-18' })
  serviceDate: string;

  @ApiProperty({ type: ColorDto })
  color: ColorDto;

  @ApiProperty({ type: IssueMediaDto })
  media: IssueMediaDto;
}
