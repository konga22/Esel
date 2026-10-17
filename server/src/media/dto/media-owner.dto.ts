import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class MediaOwnerDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ enum: ['PENDING', 'READY', 'REJECTED', 'DELETED'] })
  status: string;

  @ApiProperty({ example: 'image/jpeg' })
  mimeType: string;

  @ApiProperty({ example: 2_400_000 })
  sizeBytes: number;

  @ApiPropertyOptional({ nullable: true, type: Number })
  width: number | null;

  @ApiPropertyOptional({ nullable: true, type: Number })
  height: number | null;

  @ApiProperty()
  storageKey: string;
}
