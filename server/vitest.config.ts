import { defineConfig } from 'vitest/config';

// 서버는 상대 경로로만 import한다(tsconfig "paths" 없음). 그래서 tsconfigPaths 옵션을 쓰지 않는다.
// 그 옵션은 server/ 밖(저장소 루트)의 tsconfig까지 읽어서, 루트 앱을 설치하지 않으면 테스트가 실패했다.
export default defineConfig({
  test: {
    globals: true,
    root: './',
    include: ['**/*.spec.ts'],
  },
});
