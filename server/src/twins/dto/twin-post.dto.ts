import { ApiProperty } from '@nestjs/swagger';
import { IsUUID } from 'class-validator';

export class TwinPostDto {
  @ApiProperty({ format: 'uuid', description: '업로드 완료된 내 미디어 ID' })
  @IsUUID()
  mediaId: string;
}
