import { ApiProperty } from '@nestjs/swagger';
import { IsUUID } from 'class-validator';

export class TwinInviteDto {
  @ApiProperty({ format: 'uuid', description: '친구 목록에서 받은 friendId' })
  @IsUUID()
  friendId: string;
}
