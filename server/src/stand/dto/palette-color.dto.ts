import { ApiProperty } from '@nestjs/swagger';
import { ColorDto } from '../../today/dto/color.dto.js';

export class PaletteColorDto extends ColorDto {
  @ApiProperty({ description: '오늘 발행 전 후보색인지' })
  locked: boolean;

  @ApiProperty({ description: '내가 오늘 고른 색인지' })
  selected: boolean;
}

export class PaletteColorsDto {
  @ApiProperty({ example: '2026-10-18' })
  serviceDate: string;

  @ApiProperty({ type: PaletteColorDto, isArray: true })
  items: PaletteColorDto[];
}
