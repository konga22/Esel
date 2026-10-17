import { ApiProperty } from '@nestjs/swagger';

export class ReactionStateDto {
  @ApiProperty({ description: '내 좋아요 상태' })
  liked: boolean;

  @ApiProperty({ description: '내 스크랩 상태' })
  scrapped: boolean;
}
