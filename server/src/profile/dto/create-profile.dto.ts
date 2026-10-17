import { ApiProperty } from '@nestjs/swagger';
import { IsString } from 'class-validator';

export class CreateProfileDto {
  @ApiProperty({ example: 'selin', pattern: '^[a-z]{2,10}$' })
  @IsString()
  masthead: string;
}
