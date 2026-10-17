import { ApiProperty } from '@nestjs/swagger';

export class ReaderLinePublicDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ example: 'selin' })
  authorMasthead: string;

  @ApiProperty({ maxLength: 60 })
  text: string;

  @ApiProperty({ format: 'date-time' })
  createdAt: string;
}
