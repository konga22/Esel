import { ApiProperty } from '@nestjs/swagger';

export class ShareLinkDto {
  @ApiProperty({ example: 'Y7Xq2_uP4r6q8x...' })
  token: string;

  @ApiProperty({ example: '/api/share-links/Y7Xq2_uP4r6q8x...' })
  path: string;

  @ApiProperty({ format: 'date-time' })
  createdAt: string;
}
