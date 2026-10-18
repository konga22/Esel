import { ApiProperty } from '@nestjs/swagger';

export class BlockedUserDto {
  @ApiProperty({ example: 'selin' })
  masthead: string;

  @ApiProperty({ format: 'date-time' })
  blockedAt: string;
}
