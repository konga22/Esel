import { ApiProperty } from '@nestjs/swagger';
import { IsInt, IsString, Min } from 'class-validator';

export class PrepareMediaDto {
  @ApiProperty({ example: 'image/jpeg' })
  @IsString()
  mimeType: string;

  @ApiProperty({ example: 2_400_000, minimum: 1, maximum: 15_728_640 })
  @IsInt()
  @Min(1)
  sizeBytes: number;
}
