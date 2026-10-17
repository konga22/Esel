import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ColorDto } from './color.dto.js';

export class TodayDto {
  @ApiProperty({ example: '2026-09-06', format: 'date' })
  serviceDate: string;

  @ApiProperty({ type: [ColorDto], minItems: 3, maxItems: 3 })
  candidates: ColorDto[];

  @ApiPropertyOptional({ example: 'camel', nullable: true, type: String })
  selectedColorId: string | null;

  @ApiProperty()
  hasPublishedToday: boolean;
}
