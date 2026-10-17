import { ApiProperty } from '@nestjs/swagger';
import { IsString, Matches, MaxLength } from 'class-validator';

export class RestoreColorDto {
  @ApiProperty({ example: 'sage', maxLength: 32 })
  @IsString()
  @MaxLength(32)
  @Matches(/^[a-z][a-z0-9-]*$/)
  colorId: string;
}
