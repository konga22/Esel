import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional } from 'class-validator';

export enum MediaSize {
  ORIGINAL = 'original',
  THUMB = 'thumb',
}

export class MediaSizeQueryDto {
  @ApiPropertyOptional({ enum: MediaSize, default: MediaSize.ORIGINAL })
  @IsOptional()
  @IsEnum(MediaSize)
  size: MediaSize = MediaSize.ORIGINAL;
}
