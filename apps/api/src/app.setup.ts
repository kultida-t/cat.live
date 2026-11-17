import {
  StandardSchemaValidationPipe,
  type INestApplication,
} from '@nestjs/common';

/** ตั้งค่าที่ใช้ร่วมกันระหว่างรันจริงและเทส (validation ทุก body/param) */
export function configureApp(app: INestApplication): INestApplication {
  app.useGlobalPipes(new StandardSchemaValidationPipe());
  return app;
}
