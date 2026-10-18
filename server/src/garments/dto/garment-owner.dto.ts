import { ApiProperty } from '@nestjs/swagger';

export class GarmentOwnerDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ example: 'top' })
  kind: string;

  @ApiProperty({ example: '흰 셔츠' })
  name: string;

  @ApiProperty({ example: '오버핏' })
  note: string;

  @ApiProperty({ format: 'date-time' })
  createdAt: string;
}
