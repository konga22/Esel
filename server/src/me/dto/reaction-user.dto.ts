import { ApiProperty } from '@nestjs/swagger';

export class ReactionUserDto {
  @ApiProperty({ example: 'selin' })
  masthead: string;

  @ApiProperty({ format: 'date-time' })
  createdAt: string;
}
