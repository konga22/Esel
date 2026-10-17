import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateProfileDto {
  @ApiPropertyOptional({ example: 'selin', pattern: '^[a-z]{2,10}$' })
  @IsOptional()
  @IsString()
  masthead?: string;

  @ApiPropertyOptional({ example: '옷으로 남기는 나의 계절.', maxLength: 80 })
  @IsOptional()
  @IsString()
  @MaxLength(80)
  bio?: string;
}
