import { ApiProperty } from '@nestjs/swagger';

export class BlockStateDto {
  @ApiProperty({ example: 'selin' })
  masthead: string;

  @ApiProperty()
  blocked: boolean;
}
