import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class SessionDto {
  @ApiProperty({ format: 'uuid' })
  userId: string;

  @ApiProperty({ example: 'me@example.com' })
  email: string;

  @ApiProperty({ example: '', description: '창간 전에는 빈 문자열' })
  masthead: string;

  @ApiPropertyOptional({ nullable: true, type: String })
  profileImageUrl: string | null;

  @ApiProperty()
  hasPublishedToday: boolean;

  @ApiProperty({ minimum: 0 })
  issueCount: number;

  @ApiProperty({ description: '판별 정책 확정 전에는 false' })
  isMinor: boolean;

  @ApiProperty({ description: 'Authorization Bearer에 쓰는 불투명 토큰' })
  accessToken: string;

  @ApiProperty({ description: '새 access token을 받을 때 한 번만 쓰는 토큰' })
  refreshToken: string;
}
