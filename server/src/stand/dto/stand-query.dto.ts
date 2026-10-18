import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, Matches } from 'class-validator';

export class StandQueryDto {
  @ApiProperty({ example: 'sage' })
  @IsString()
  colorId: string;

  @ApiPropertyOptional({
    example: '2026-10-18',
    pattern: '^\\d{4}-\\d{2}-\\d{2}$',
  })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  date?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  cursor?: string;
}
