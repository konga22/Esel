import { defineConfig } from 'vitest/config';

// vitest.config.ts와 같은 이유로 tsconfigPaths를 쓰지 않는다. server/만으로 돈다.
export default defineConfig({
  test: {
    globals: true,
    root: './',
    include: ['**/*.e2e-spec.ts'],
  },
});
