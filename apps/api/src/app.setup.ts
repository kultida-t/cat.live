import {
  StandardSchemaValidationPipe,
  type INestApplication,
} from '@nestjs/common';

/** ตั้งค่าที่ใช้ร่วมกันระหว่างรันจริงและเทส (validation ทุก body/param) */
export function configureApp(app: INestApplication): INestApplication {
  // API ฝั่งแอปทุก route อยู่ใต้ /api/v1 ตาม docs/backend-architecture.md —
  // ยกเว้น /health ที่ LB เรียกตรง ๆ โดยไม่ผ่าน prefix
  app.setGlobalPrefix('api/v1', { exclude: ['health'] });
  app.useGlobalPipes(new StandardSchemaValidationPipe());
  return app;
}
