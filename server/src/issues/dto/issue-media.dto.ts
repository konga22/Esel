import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class IssueMediaDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ example: 'image/png' })
  mimeType: string;

  @ApiPropertyOptional({ nullable: true, type: Number })
  width: number | null;

  @ApiPropertyOptional({ nullable: true, type: Number })
  height: number | null;
}
