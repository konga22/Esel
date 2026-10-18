import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { GARMENT_KINDS, GARMENT_NOTES } from './garment-input.dto.js';

export class IssueGarmentDto {
  @ApiProperty({ format: 'uuid' })
  garmentId: string;

  @ApiProperty({ enum: GARMENT_KINDS })
  kind: string;

  @ApiProperty({ maxLength: 40 })
  name: string;

  @ApiProperty({ enum: ['', ...GARMENT_NOTES] })
  note: string;

  @ApiProperty()
  todayColor: boolean;

  @ApiPropertyOptional({ nullable: true, minimum: 0, maximum: 1 })
  x: number | null;

  @ApiPropertyOptional({ nullable: true, minimum: 0, maximum: 1 })
  y: number | null;
}
