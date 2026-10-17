import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import type { Request } from 'express';
import type { AuthUser } from './auth-user.js';

export interface AuthenticatedRequest extends Request {
  authUser?: AuthUser;
}

export const CurrentUser = createParamDecorator(
  (_data: unknown, context: ExecutionContext): AuthUser => {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    if (!request.authUser) {
      throw new Error('인증 가드가 사용자 정보를 넣지 않았어요.');
    }
    return request.authUser;
  },
);
