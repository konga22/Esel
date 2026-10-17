import { ApiProperty } from '@nestjs/swagger';

export class MediaUploadDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({
    example: 'pending/550e8400-e29b-41d4-a716-446655440000.upload',
  })
  storageKey: string;

  @ApiProperty({ example: 15_728_640 })
  maxSizeBytes: number;

  @ApiProperty({ example: ['image/jpeg', 'image/png', 'image/heic'] })
  allowedMimeTypes: string[];
}
