import { PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { Provider } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/** ที่เก็บไฟล์ต้นฉบับก่อนส่งให้ CloudImageLab ประมวลผล (Flow B) */
export const OBJECT_UPLOADER = Symbol('OBJECT_UPLOADER');

export interface ObjectUploader {
  put(key: string, body: Buffer, contentType: string): Promise<void>;
}

/** เขียนไฟล์ลง S3 โดยใช้ค่าจาก AWS_REGION และ AVATAR_SOURCE_BUCKET; credential อ่านจากตัวแปรสภาพแวดล้อม AWS ตามปกติ */
export const s3UploaderProvider: Provider = {
  provide: OBJECT_UPLOADER,
  inject: [ConfigService],
  useFactory: (config: ConfigService): ObjectUploader => {
    const client = new S3Client({ region: config.get<string>('AWS_REGION') });
    return {
      put: async (key, body, contentType) => {
        await client.send(
          new PutObjectCommand({
            Bucket: config.getOrThrow<string>('AVATAR_SOURCE_BUCKET'),
            Key: key,
            Body: body,
            ContentType: contentType,
          }),
        );
      },
    };
  },
};
