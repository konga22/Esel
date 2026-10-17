import { ApiProperty } from '@nestjs/swagger';
import { DayRecordDto } from './day-record.dto.js';

export class MonthRecordDto {
  @ApiProperty({ example: '2026-10' })
  month: string;

  @ApiProperty({ minimum: 0, maximum: 2 })
  remainingRestores: number;

  @ApiProperty({ type: DayRecordDto, isArray: true })
  days: DayRecordDto[];
}
