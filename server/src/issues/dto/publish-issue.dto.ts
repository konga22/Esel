import { Type, Transform } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  ArrayMaxSize,
  IsArray,
  IsIn,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  ValidateNested,
} from 'class-validator';
import { GarmentInputDto } from './garment-input.dto.js';

export class PublishIssueDto {
  @ApiProperty({ format: 'uuid', description: '업로드 완료된 내 미디어 ID' })
  @IsUUID()
  mediaId: string;

  @ApiProperty({ maxLength: 280, example: '오늘은 파우더 블루.' })
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @MaxLength(280)
  caption: string;

  @ApiProperty({
    enum: ['PLAIN', 'PAINT', 'BEHIND_MASTHEAD', 'NECK_DOWN'],
  })
  @IsString()
  @IsIn(['PLAIN', 'PAINT', 'BEHIND_MASTHEAD', 'NECK_DOWN'])
  faceMode: 'PLAIN' | 'PAINT' | 'BEHIND_MASTHEAD' | 'NECK_DOWN';

  @ApiPropertyOptional({ type: GarmentInputDto, isArray: true, maxItems: 8 })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(8)
  @ValidateNested({ each: true })
  @Type(() => GarmentInputDto)
  garments?: GarmentInputDto[];
}
