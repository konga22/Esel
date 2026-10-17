import { ApiProperty } from '@nestjs/swagger';
import { IsString, Matches } from 'class-validator';

export class FriendRequestCreateDto {
  @ApiProperty({ example: 'selin', pattern: '^[a-z]{2,10}$' })
  @IsString()
  @Matches(/^[a-z]{2,10}$/)
  masthead: string;
}
