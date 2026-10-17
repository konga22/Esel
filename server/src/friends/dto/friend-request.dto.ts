import { ApiProperty } from '@nestjs/swagger';

export class FriendRequestDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({
    example: 'selin',
    description: '요청 상대의 제호(받은 요청 목록에서는 보낸 사람)',
  })
  masthead: string;

  @ApiProperty({ format: 'date-time' })
  createdAt: string;
}
