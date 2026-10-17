import { ApiProperty } from '@nestjs/swagger';
import { IsString, Matches } from 'class-validator';

export class RestoreDateParamDto {
  @ApiProperty({ example: '2026-10-07', pattern: '^\\d{4}-\\d{2}-\\d{2}$' })
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  date: string;
}
