import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IssueMediaDto } from '../../issues/dto/issue-media.dto.js';
import { ColorDto } from '../../today/dto/color.dto.js';

export class TwinPartnerDto {
  @ApiProperty({ format: 'uuid' })
  friendId: string;

  @ApiProperty({ example: 'selin' })
  masthead: string;
}

export class TwinPostViewDto {
  @ApiProperty({ example: 'camel' })
  colorId: string;

  @ApiProperty({ format: 'date-time' })
  postedAt: string;

  @ApiProperty({ type: IssueMediaDto })
  media: IssueMediaDto;
}

export class TwinDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ example: '2026-10-18' })
  serviceDate: string;

  @ApiProperty({
    enum: [
      'INVITED',
      'CHOOSING',
      'POSTING',
      'REVEALED',
      'SHARING',
      'CONSENT_WAITING',
      'PUBLISHED',
    ],
  })
  status: string;

  @ApiProperty()
  invitedByMe: boolean;

  @ApiProperty({ type: TwinPartnerDto })
  partner: TwinPartnerDto;

  @ApiProperty({ type: ColorDto, isArray: true })
  myCandidates: ColorDto[];

  @ApiProperty({ type: ColorDto, isArray: true })
  partnerCandidates: ColorDto[];

  @ApiPropertyOptional({ nullable: true, type: String })
  myColorId: string | null;

  @ApiPropertyOptional({ nullable: true, type: String })
  partnerColorId: string | null;

  @ApiPropertyOptional({ nullable: true, type: TwinPostViewDto })
  myPost: TwinPostViewDto | null;

  @ApiPropertyOptional({
    nullable: true,
    type: TwinPostViewDto,
    description: '두 사람 모두 게시한 뒤에만 응답한다.',
  })
  partnerPost: TwinPostViewDto | null;

  @ApiPropertyOptional({
    nullable: true,
    enum: ['private', 'solo', 'joint'],
  })
  myVisibility: string | null;

  @ApiPropertyOptional({
    nullable: true,
    enum: ['private', 'solo', 'joint'],
  })
  partnerVisibility: string | null;

  @ApiProperty()
  myConsented: boolean;

  @ApiProperty()
  partnerConsented: boolean;

  @ApiPropertyOptional({ nullable: true, format: 'date-time', type: String })
  publishedAt: string | null;
}
