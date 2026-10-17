import { ApiProperty } from '@nestjs/swagger';

export class FriendDto {
  @ApiProperty({ format: 'uuid', description: '트윈 초대에 사용할 친구 ID' })
  friendId: string;

  @ApiProperty({ example: 'selin' })
  masthead: string;

  @ApiProperty({ format: 'date-time' })
  friendsSince: string;
}
