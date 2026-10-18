import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

export class ScrapsQueryDto {
  @ApiPropertyOptional({ description: '다음 페이지 cursor' })
  @IsOptional()
  @IsString()
  cursor?: string;
}
