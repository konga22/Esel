import { ApiProperty } from '@nestjs/swagger';
import { IsString, Matches, MaxLength } from 'class-validator';

export class ChooseColorDto {
  @ApiProperty({ example: 'camel', maxLength: 32 })
  @IsString()
  @MaxLength(32)
  @Matches(/^[a-z]+$/)
  colorId: string;
}
