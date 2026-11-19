import {
  Injectable,
  Logger,
  OnApplicationBootstrap,
  OnModuleDestroy,
} from '@nestjs/common';
import { MediaService } from './media.service.js';

const CLEANUP_INTERVAL_MS = 6 * 60 * 60 * 1000;

/**
 * 쓰이지 않은 사진 정리를 서버 안에서 자동으로 돌린다.
 * 서버가 켜지면 한 번, 그 뒤 6시간마다. 외부 패키지 없이 Node 내장 타이머만 쓴다.
 *
 * - 앞 정리가 아직 돌고 있으면 겹쳐 실행하지 않는다.
 * - 정리가 실패해도 로그만 남기고 서버는 계속 돈다(다음 차례에 다시 시도).
 * - 서버가 꺼질 때는 돌던 정리가 끝날 때까지 기다린다. Nest는 이 모듈을 전역 PrismaModule보다 먼저 닫으므로
 *   DB 연결이 정리 도중에 끊기지 않는다.
 */
@Injectable()
export class MediaCleanupScheduler
  implements OnApplicationBootstrap, OnModuleDestroy
{
  private readonly logger = new Logger(MediaCleanupScheduler.name);
  private timer: NodeJS.Timeout | null = null;
  private running: Promise<void> | null = null;

  constructor(private readonly media: MediaService) {}

  onApplicationBootstrap(): void {
    this.trigger();
    this.timer = setInterval(() => this.trigger(), CLEANUP_INTERVAL_MS);
    // 이 타이머 하나 때문에 프로세스가 끝나지 못하는 일이 없게 한다.
    this.timer.unref();
  }

  async onModuleDestroy(): Promise<void> {
    if (this.timer) clearInterval(this.timer);
    this.timer = null;
    await this.running;
  }

  private trigger(): void {
    if (this.running) return;
    this.running = this.media
      .cleanupUnusedMedia()
      .then(
        (result) => {
          if (result.removed || result.failedFiles) {
            this.logger.log(
              `쓰이지 않은 사진 ${result.removed}장을 정리했어요(파일 삭제 실패 ${result.failedFiles}장).`,
            );
          }
        },
        (error: unknown) => {
          this.logger.warn('쓰이지 않은 사진 정리에 실패했어요.', error);
        },
      )
      .finally(() => {
        this.running = null;
      });
  }
}
