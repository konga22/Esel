import { ApiProperty } from '@nestjs/swagger';

export class ColorDto {
  @ApiProperty({ example: 'camel' })
  id: string;

  @ApiProperty({ example: '카멜' })
  nameKo: string;

  @ApiProperty({ example: 'Camel' })
  nameEn: string;

  @ApiProperty({ example: '#C1945F', pattern: '^#[0-9A-Fa-f]{6}$' })
  hex: string;
}
