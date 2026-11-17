import { PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { Provider } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/** ออก presigned URL ให้แอปอัปโหลดรูปต้นฉบับตรงไปที่ S3 (ทีมกำหนดให้อัปโหลดด้วย presigned URL เท่านั้น) */
export const OBJECT_PRESIGNER = Symbol('OBJECT_PRESIGNER');

export interface PresignPutInput {
  key: string;
  contentType: string;
  contentLength: number;
  expiresInSeconds: number;
}

export interface ObjectPresigner {
  presignPut(input: PresignPutInput): Promise<string>;
}

/** ใช้ AWS_REGION และ AVATAR_SOURCE_BUCKET; credential อ่านจากตัวแปรสภาพแวดล้อม AWS ตามปกติ ไม่เก็บในโค้ด */
export const s3PresignerProvider: Provider = {
  provide: OBJECT_PRESIGNER,
  inject: [ConfigService],
  useFactory: (config: ConfigService): ObjectPresigner => {
    const client = new S3Client({ region: config.get<string>('AWS_REGION') });
    return {
      presignPut: ({ key, contentType, contentLength, expiresInSeconds }) =>
        getSignedUrl(
          client,
          new PutObjectCommand({
            Bucket: config.getOrThrow<string>('AVATAR_SOURCE_BUCKET'),
            Key: key,
            ContentType: contentType,
            ContentLength: contentLength,
          }),
          { expiresIn: expiresInSeconds, signableHeaders: new Set(['content-type']) },
        ),
    };
  },
};
