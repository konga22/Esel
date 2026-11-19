import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Prisma } from '../generated/prisma/client.js';
import { AppException } from '../common/app-exception.js';
import { serviceDate } from '../common/service-date.js';
import { PrismaService } from '../prisma/prisma.service.js';
import type { AuthUser } from './auth-user.js';
import { EmailLoginDto } from './dto/email-login.dto.js';
import { EmailSignupDto } from './dto/email-signup.dto.js';
import { RefreshDto } from './dto/refresh.dto.js';
import { SessionDto } from './dto/session.dto.js';
import { LoginRateLimiter } from './login-rate-limiter.js';
import { hashPassword, verifyPassword } from './password.js';
import { hashToken, newSessionTokens } from './session-token.js';
import type { NewSessionTokens } from './session-token.js';
import { SignupRateLimiter } from './signup-rate-limiter.js';

// 없는 계정도 실제 계정과 같은 scrypt 연산을 거쳐 응답 시간 차이를 줄인다.
const LOGIN_TIMING_DUMMY_HASH =
  'scrypt$login-timing-pad$7lYuTTiWNL52uUOjLYvIYf-HYmhWpvuyxWkaHFpxyb1jmA7ftMRM6FjB-blKP3fORSGJLnrymQrTjpu1AyGv1g';

interface SessionUser {
  id: string;
  email: string | null;
  profile: { masthead: string; issueCount: number } | null;
}

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly signupRateLimiter: SignupRateLimiter,
    private readonly loginRateLimiter: LoginRateLimiter,
    private readonly config: ConfigService,
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

  async login(input: EmailLoginDto): Promise<SessionDto> {
    const email = input.email.trim().toLowerCase();
    // 비밀번호를 확인하기 전에 시도를 센다. 제한에 걸리면 맞는 비밀번호여도 여기서 429로 끝난다.
    // 계정이 있든 없든 같은 이메일 기준으로 똑같이 세므로, 429로 계정 존재 여부가 드러나지 않는다.
    this.loginRateLimiter.consume(email);

    const user = await this.prisma.user.findUnique({
      where: { email },
      include: { emailCredential: true, profile: true },
    });
    const passwordHash =
      user?.emailCredential?.passwordHash ?? LOGIN_TIMING_DUMMY_HASH;
    const passwordMatches = await verifyPassword(input.password, passwordHash);

    if (!user || user.status !== 'ACTIVE' || !passwordMatches) {
      throw new AppException('WRONG_CREDENTIALS');
    }
    this.loginRateLimiter.reset(email);

    const hasPublishedToday = await this.hasPublishedToday(user.id);
    const tokens = newSessionTokens();
    await this.prisma.authSession.create({
      data: {
        userId: user.id,
        accessTokenHash: tokens.accessTokenHash,
        refreshTokenHash: tokens.refreshTokenHash,
        accessExpiresAt: tokens.accessExpiresAt,
        refreshExpiresAt: tokens.refreshExpiresAt,
      },
    });

    return this.toSessionDto(user, email, hasPublishedToday, tokens);
  }

  async refresh(input: RefreshDto): Promise<SessionDto> {
    const now = new Date();
    const session = await this.prisma.authSession.findUnique({
      where: { refreshTokenHash: hashToken(input.refreshToken) },
      include: { user: { include: { profile: true } } },
    });

    if (!session) throw new AppException('AUTH_REQUIRED');

    if (
      session.revokedAt ||
      session.user.status !== 'ACTIVE' ||
      !session.user.email
    ) {
      await this.revokeAllSessions(session.userId, now);
      throw new AppException('AUTH_REQUIRED');
    }

    if (session.refreshExpiresAt <= now) {
      await this.prisma.authSession.updateMany({
        where: { id: session.id, revokedAt: null },
        data: { revokedAt: now },
      });
      throw new AppException('TOKEN_EXPIRED');
    }

    const hasPublishedToday = await this.hasPublishedToday(session.userId, now);
    const tokens = newSessionTokens(now);
    const rotated = await this.prisma.$transaction(async (transaction) => {
      const claimed = await transaction.authSession.updateMany({
        where: {
          id: session.id,
          revokedAt: null,
          refreshExpiresAt: { gt: now },
        },
        data: { revokedAt: now },
      });

      if (claimed.count === 0) {
        await transaction.authSession.updateMany({
          where: { userId: session.userId, revokedAt: null },
          data: { revokedAt: now },
        });
        return false;
      }

      await transaction.authSession.create({
        data: {
          userId: session.userId,
          accessTokenHash: tokens.accessTokenHash,
          refreshTokenHash: tokens.refreshTokenHash,
          accessExpiresAt: tokens.accessExpiresAt,
          refreshExpiresAt: tokens.refreshExpiresAt,
        },
      });
      return true;
    });

    if (!rotated) throw new AppException('AUTH_REQUIRED');
    return this.toSessionDto(
      session.user,
      session.user.email,
      hasPublishedToday,
      tokens,
    );
  }

  async authenticateAccessToken(token: string): Promise<AuthUser> {
    const now = new Date();
    const session = await this.prisma.authSession.findUnique({
      where: { accessTokenHash: hashToken(token) },
      include: { user: { select: { status: true } } },
    });

    if (!session || session.revokedAt) {
      throw new AppException('AUTH_REQUIRED');
    }
    if (session.user.status !== 'ACTIVE') {
      await this.revokeAllSessions(session.userId, now);
      throw new AppException('AUTH_REQUIRED');
    }
    if (session.accessExpiresAt <= now) {
      throw new AppException('TOKEN_EXPIRED');
    }
    return { id: session.userId, sessionId: session.id };
  }

  async logout(sessionId: string): Promise<void> {
    await this.prisma.authSession.updateMany({
      where: { id: sessionId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }

  private async revokeAllSessions(userId: string, revokedAt: Date) {
    await this.prisma.authSession.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt },
    });
  }

  private async hasPublishedToday(
    userId: string,
    now = new Date(),
  ): Promise<boolean> {
    const today = new Date(
      `${serviceDate(
        now,
        this.config.getOrThrow<string>('SERVICE_TIME_ZONE'),
      )}T00:00:00.000Z`,
    );
    const issue = await this.prisma.issue.findUnique({
      where: { authorId_serviceDate: { authorId: userId, serviceDate: today } },
      select: { id: true, deletedAt: true },
    });
    return Boolean(issue && !issue.deletedAt);
  }

  private toSessionDto(
    user: SessionUser,
    email: string,
    hasPublishedToday: boolean,
    tokens: NewSessionTokens,
  ): SessionDto {
    return {
      userId: user.id,
      email,
      masthead: user.profile?.masthead ?? '',
      profileImageUrl: null,
      hasPublishedToday,
      issueCount: user.profile?.issueCount ?? 0,
      isMinor: false,
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    };
  }
}
