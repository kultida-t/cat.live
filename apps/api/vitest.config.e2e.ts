import { defineConfig } from 'vitest/config';

export default defineConfig({
  resolve: { tsconfigPaths: true },
  test: {
    globals: true,
    root: './',
    include: ['**/*.e2e-spec.ts'],
    // ใช้ฐานทดสอบเท่านั้น — ตั้งตรงนี้เพื่อไม่ให้ค่าจาก .env (ฐานพัฒนา) ถูกใช้ตอนเทส
    env: {
      DATABASE_URL: 'postgresql://kultida@localhost:5432/catlive_test',
      JWT_SECRET: 'test-only-secret',
      DB_SSL_CA_FILE: '',
    },
  },
});
