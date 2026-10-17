import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { FriendsModule } from './friends/friends.module.js';
import { validateEnvironment } from './config/environment.js';
import { HealthModule } from './health/health.module.js';
import { PrismaModule } from './prisma/prisma.module.js';
import { AuthModule } from './auth/auth.module.js';
import { ProfileModule } from './profile/profile.module.js';
import { TodayModule } from './today/today.module.js';
import { AccountModule } from './account/account.module.js';
import { MediaModule } from './media/media.module.js';
import { IssuesModule } from './issues/issues.module.js';
import { MagazinesModule } from './magazines/magazines.module.js';
import { MeModule } from './me/me.module.js';
import { RecordsModule } from './records/records.module.js';
import { UsersModule } from './users/users.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      validate: validateEnvironment,
    }),
    PrismaModule,
    HealthModule,
    AuthModule,
    ProfileModule,
    TodayModule,
    AccountModule,
    MediaModule,
    IssuesModule,
    MagazinesModule,
    MeModule,
    RecordsModule,
    UsersModule,
    FriendsModule,
  ],
})
export class AppModule {}
