import { Transform } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsIn,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export const GARMENT_KINDS = [
  '코트',
  '니트',
  '셔츠',
  '바지',
  '치마',
  '원피스',
  '신발',
  '가방',
  '액세서리',
] as const;

export const GARMENT_NOTES = [
  '빈티지',
  '물려받음',
  '직접 만듦',
  '오래 입음',
] as const;

export class GarmentInputDto {
  @ApiPropertyOptional({ format: 'uuid', description: '내 옷을 다시 고를 때' })
  @IsOptional()
  @IsUUID()
  garmentId?: string;

  @ApiProperty({ enum: GARMENT_KINDS, example: '셔츠' })
  @IsString()
  @IsIn(GARMENT_KINDS)
  kind: string;

  @ApiPropertyOptional({ example: '내 파란 셔츠', maxLength: 40 })
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsOptional()
  @IsString()
  @MaxLength(40)
  name?: string;

  @ApiPropertyOptional({ enum: GARMENT_NOTES, example: '오래 입음' })
  @IsOptional()
  @IsString()
  @IsIn(['', ...GARMENT_NOTES])
  note?: string;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  todayColor?: boolean;

  @ApiPropertyOptional({ minimum: 0, maximum: 1 })
  @IsOptional()
  @IsNumber({ allowNaN: false, allowInfinity: false })
  @Min(0)
  @Max(1)
  x?: number;

  @ApiPropertyOptional({ minimum: 0, maximum: 1 })
  @IsOptional()
  @IsNumber({ allowNaN: false, allowInfinity: false })
  @Min(0)
  @Max(1)
  y?: number;
}
