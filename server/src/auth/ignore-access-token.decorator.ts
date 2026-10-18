import { SetMetadata } from '@nestjs/common';

export const IGNORE_ACCESS_TOKEN_KEY = 'ignoreAccessToken';

/**
 * 공개 인증 진입점에서 Authorization 헤더를 의도적으로 무시한다.
 * 만료된 access token과 유효한 refresh token이 함께 오는 갱신 요청도 허용한다.
 */
export const IgnoreAccessToken = () =>
  SetMetadata(IGNORE_ACCESS_TOKEN_KEY, true);
