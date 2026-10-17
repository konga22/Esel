import {
  ArgumentsHost,
  BadRequestException,
  Catch,
  ExceptionFilter,
} from '@nestjs/common';
import { Response } from 'express';
import { AppException } from './app-exception.js';
import { APP_ERRORS } from './errors.js';

type ValidationMessage = string | { property?: string; constraints?: string[] };

@Catch(AppException, BadRequestException)
export class AppExceptionFilter implements ExceptionFilter<
  AppException | BadRequestException
> {
  catch(exception: AppException | BadRequestException, host: ArgumentsHost) {
    const response = host.switchToHttp().getResponse<Response>();

    if (exception instanceof AppException) {
      const definition = APP_ERRORS[exception.code];
      response.status(definition.status).json({
        error: {
          code: exception.code,
          message: definition.message,
          hint: definition.hint,
          ...(exception.details ? { details: exception.details } : {}),
        },
      });
      return;
    }

    const definition = APP_ERRORS.VALIDATION;
    response.status(definition.status).json({
      error: {
        code: 'VALIDATION',
        message: definition.message,
        hint: definition.hint,
        details: validationDetails(exception.getResponse()),
      },
    });
  }
}

function validationDetails(value: unknown): Record<string, string[]> {
  const response = value as {
    message?: ValidationMessage | ValidationMessage[];
  };
  const messages = Array.isArray(response.message)
    ? response.message
    : response.message
      ? [response.message]
      : [];

  return messages.reduce<Record<string, string[]>>((details, message) => {
    if (typeof message === 'string') {
      (details.request ??= []).push(message);
      return details;
    }
    const property = message.property ?? 'request';
    details[property] = message.constraints ?? ['형식이 맞지 않아요.'];
    return details;
  }, {});
}
