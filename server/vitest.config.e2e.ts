import { defineConfig } from 'vitest/config';

// vitest.config.ts와 같은 이유로 tsconfigPaths를 쓰지 않는다. server/만으로 돈다.
export default defineConfig({
  test: {
    globals: true,
    root: './',
    include: ['**/*.e2e-spec.ts'],
    // 계약 테스트는 하나의 PostgreSQL 스키마를 함께 쓰므로 파일을 병렬 실행하면
    // 다른 파일의 fixture가 피드/표지 조회에 섞일 수 있다.
    fileParallelism: false,
  },
});
