import { Injectable } from '@nestjs/common';
import { Prisma } from '../generated/prisma/client.js';
import { AppException } from '../common/app-exception.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { EmailSignupDto } from './dto/email-signup.dto.js';
import { SessionDto } from './dto/session.dto.js';
import { hashPassword } from './password.js';
import { newSessionTokens } from './session-token.js';
import { SignupRateLimiter } from './signup-rate-limiter.js';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly signupRateLimiter: SignupRateLimiter,
  ) {}

  async signup(input: EmailSignupDto): Promise<SessionDto> {
    const email = input.email.trim().toLowerCase();
    this.signupRateLimiter.consume(email);

    const [passwordHash, tokens] = await Promise.all([
      hashPassword(input.password),
      Promise.resolve(newSessionTokens()),
    ]);

    try {
      const user = await this.prisma.$transaction(async (transaction) => {
        const created = await transaction.user.create({ data: { email } });
        await transaction.emailCredential.create({
          data: { userId: created.id, passwordHash },
        });
        await transaction.authSession.create({
          data: {
            userId: created.id,
            accessTokenHash: tokens.accessTokenHash,
            refreshTokenHash: tokens.refreshTokenHash,
            accessExpiresAt: tokens.accessExpiresAt,
            refreshExpiresAt: tokens.refreshExpiresAt,
          },
        });
        return created;
      });

      return {
        userId: user.id,
        email,
        masthead: '',
        profileImageUrl: null,
        hasPublishedToday: false,
        issueCount: 0,
        isMinor: false,
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      };
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        throw new AppException('EMAIL_TAKEN');
      }
      throw error;
    }
  }
}
