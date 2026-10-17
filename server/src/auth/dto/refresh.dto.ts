import { ApiProperty } from '@nestjs/swagger';
import { IsString, Length, Matches } from 'class-validator';

export class RefreshDto {
  @ApiProperty({
    minLength: 43,
    maxLength: 43,
    description: '로그인이나 이전 갱신에서 받은 일회용 refresh token',
  })
  @IsString()
  @Length(43, 43)
  @Matches(/^[A-Za-z0-9_-]+$/)
  refreshToken: string;
}
