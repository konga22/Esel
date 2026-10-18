import { ApiProperty } from '@nestjs/swagger';

export class ReportReceiptDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ enum: ['RECEIVED'] })
  status: 'RECEIVED';

  @ApiProperty({ format: 'date-time' })
  createdAt: string;
}
