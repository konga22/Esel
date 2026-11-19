import type { MediaService } from './media.service.js';
import { MediaCleanupScheduler } from './media-cleanup.scheduler.js';

type CleanupResult = { removed: number; failedFiles: number };

/** 테스트가 원하는 때에 끝낼 수 있는 "느린 정리"를 만든다. */
function deferred() {
  let finish!: (value: CleanupResult) => void;
  const promise = new Promise<CleanupResult>((done) => {
    finish = done;
  });
  return { promise, resolve: () => finish({ removed: 0, failedFiles: 0 }) };
}

function schedulerWith(cleanup: () => Promise<unknown>) {
  const media = { cleanupUnusedMedia: vi.fn(cleanup) };
  return {
    media,
    scheduler: new MediaCleanupScheduler(media as unknown as MediaService),
  };
}

describe('MediaCleanupScheduler', () => {
  afterEach(() => {
    vi.useRealTimers();
  });

  it('서버가 켜지면 한 번, 그 뒤 6시간마다 정리한다', async () => {
    vi.useFakeTimers();
    const { media, scheduler } = schedulerWith(async () => ({
      removed: 0,
      failedFiles: 0,
    }));

    scheduler.onApplicationBootstrap();
    expect(media.cleanupUnusedMedia).toHaveBeenCalledTimes(1);

    await vi.advanceTimersByTimeAsync(6 * 60 * 60 * 1000);
    expect(media.cleanupUnusedMedia).toHaveBeenCalledTimes(2);

    await scheduler.onModuleDestroy();
    await vi.advanceTimersByTimeAsync(6 * 60 * 60 * 1000);
    expect(media.cleanupUnusedMedia).toHaveBeenCalledTimes(2);
  });

  it('앞 정리가 아직 돌고 있으면 겹쳐 실행하지 않는다', async () => {
    vi.useFakeTimers();
    const slow = deferred();
    const { media, scheduler } = schedulerWith(() => slow.promise);

    scheduler.onApplicationBootstrap();
    await vi.advanceTimersByTimeAsync(6 * 60 * 60 * 1000);
    expect(media.cleanupUnusedMedia).toHaveBeenCalledTimes(1);

    slow.resolve();
    await scheduler.onModuleDestroy();
  });

  it('서버가 꺼질 때 돌던 정리가 끝날 때까지 기다린다(DB 연결이 먼저 닫히지 않게)', async () => {
    const slow = deferred();
    const { scheduler } = schedulerWith(() => slow.promise);
    scheduler.onApplicationBootstrap();

    let destroyed = false;
    const destroying = scheduler.onModuleDestroy().then(() => {
      destroyed = true;
    });
    await Promise.resolve();
    expect(destroyed).toBe(false);

    slow.resolve();
    await destroying;
    expect(destroyed).toBe(true);
  });

  it('정리가 실패해도 서버를 멈추지 않는다', async () => {
    const { scheduler } = schedulerWith(() =>
      Promise.reject(new Error('db offline')),
    );

    expect(() => scheduler.onApplicationBootstrap()).not.toThrow();
    await expect(scheduler.onModuleDestroy()).resolves.toBeUndefined();
  });
});
