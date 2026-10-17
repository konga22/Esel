import { HttpException } from '@nestjs/common';
import { APP_ERRORS, AppErrorCode } from './errors.js';

export class AppException extends HttpException {
  constructor(
    readonly code: AppErrorCode,
    readonly details?: Record<string, string[]>,
  ) {
    super(APP_ERRORS[code], APP_ERRORS[code].status);
  }
}
