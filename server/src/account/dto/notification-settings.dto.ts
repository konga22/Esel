import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean } from 'class-validator';

export class NotificationSettingsDto {
  @ApiProperty({ description: '전체 알림 수신' })
  @IsBoolean()
  enabled: boolean;

  @ApiProperty({ description: '오늘의 새 호 알림' })
  @IsBoolean()
  newIssue: boolean;

  @ApiProperty({ description: '독자 반응 알림' })
  @IsBoolean()
  reactions: boolean;
}
