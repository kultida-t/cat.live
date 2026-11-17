import {
  Inject,
  Injectable,
  NotFoundException,
  ServiceUnavailableException,
  UnauthorizedException,
  UnsupportedMediaTypeException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { randomUUID, timingSafeEqual } from 'node:crypto';
import { PrismaService } from '../prisma/prisma.service.js';
import { CloudImageLabClient } from './cloudimagelab.client.js';
import { OBJECT_UPLOADER, type ObjectUploader } from './s3-uploader.js';

const AVATAR_EXTENSIONS: Record<string, string> = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
};

export interface CallbackBody {
  fileId: string;
  status: string;
  variants?: { presetName: string; url: string }[] | null;
  error?: string | null;
}

@Injectable()
export class MediaService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly cil: CloudImageLabClient,
    private readonly config: ConfigService,
    @Inject(OBJECT_UPLOADER) private readonly objects: ObjectUploader,
  ) {}

  /** รับรูปโปรไฟล์ เก็บไว้ที่ S3 แล้วสั่ง CloudImageLab ประมวลผล (Flow B) ผลจะกลับมาทาง callback */
  async uploadAvatar(userId: string, file: { buffer: Buffer; mimetype: string }) {
    const ext = AVATAR_EXTENSIONS[file.mimetype];
    if (!ext) throw new UnsupportedMediaTypeException('รองรับเฉพาะไฟล์ JPEG, PNG และ WebP');
    const presetName = this.config.get<string>('CLOUDIMAGELAB_AVATAR_PRESET');
    const callbackUrl = this.config.get<string>('CLOUDIMAGELAB_CALLBACK_URL');
    if (!presetName || !callbackUrl) {
      throw new ServiceUnavailableException('ระบบประมวลผลรูปยังไม่ได้ตั้งค่า');
    }

    const s3Key = `avatars/${userId}/${randomUUID()}.${ext}`;
    await this.objects.put(s3Key, file.buffer, file.mimetype);
    const { fileId } = await this.cil.processExternalFile({
      s3Key,
      outputPath: `avatars/${userId}`,
      presetNames: [presetName],
      callbackUrl,
    });
    await this.prisma.mediaUpload.create({ data: { userId, fileId, s3Key } });
    return { fileId, status: 'processing' as const };
  }

  /** รับผลจาก CloudImageLab — ตรวจ key ก่อนทุกครั้ง และทำซ้ำได้โดยไม่เปลี่ยนผลเดิม */
  async handleCallback(callbackKey: string | undefined, body: CallbackBody): Promise<void> {
    if (!this.isValidCallbackKey(callbackKey)) throw new UnauthorizedException();
    const upload = await this.prisma.mediaUpload.findUnique({ where: { fileId: body.fileId } });
    if (!upload) throw new NotFoundException('ไม่พบงานประมวลผลรูปนี้');
    if (upload.status !== 'processing') return;

    if (body.status !== 'Completed') {
      await this.prisma.mediaUpload.update({
        where: { id: upload.id },
        data: { status: 'failed', error: body.error ?? 'ประมวลผลไม่สำเร็จ' },
      });
      return;
    }
    const presetName = this.config.get<string>('CLOUDIMAGELAB_AVATAR_PRESET');
    const variant = body.variants?.find((v) => v.presetName === presetName);
    if (!variant) {
      await this.prisma.mediaUpload.update({
        where: { id: upload.id },
        data: { status: 'failed', error: 'ไม่พบรูปตามขนาดที่กำหนด' },
      });
      return;
    }
    await this.prisma.$transaction([
      this.prisma.mediaUpload.update({
        where: { id: upload.id },
        data: { status: 'completed', variantUrl: variant.url },
      }),
      this.prisma.userAvatar.updateMany({
        where: { userId: upload.userId, isCurrent: true },
        data: { isCurrent: false },
      }),
      this.prisma.userAvatar.create({
        data: { userId: upload.userId, url: variant.url, isCurrent: true },
      }),
      this.prisma.user.update({
        where: { id: upload.userId },
        data: { avatarUrl: variant.url },
      }),
    ]);
  }

  /** รูปที่เคยใช้ทั้งหมดของผู้ใช้ เรียงจากใหม่ไปเก่า */
  listAvatars(userId: string) {
    return this.prisma.userAvatar.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      select: { id: true, url: true, isCurrent: true },
    });
  }

  /** เลือกรูปที่เคยใช้กลับมาเป็นรูปปัจจุบัน */
  async selectAvatar(userId: string, avatarId: string): Promise<void> {
    const avatar = await this.prisma.userAvatar.findFirst({ where: { id: avatarId, userId } });
    if (!avatar) throw new NotFoundException('ไม่พบรูปนี้');
    await this.prisma.$transaction([
      this.prisma.userAvatar.updateMany({
        where: { userId, isCurrent: true },
        data: { isCurrent: false },
      }),
      this.prisma.userAvatar.update({ where: { id: avatar.id }, data: { isCurrent: true } }),
      this.prisma.user.update({ where: { id: userId }, data: { avatarUrl: avatar.url } }),
    ]);
  }

  private isValidCallbackKey(received: string | undefined): boolean {
    const expected = this.config.get<string>('CLOUDIMAGELAB_API_KEY');
    if (!expected || !received) return false;
    const a = Buffer.from(received);
    const b = Buffer.from(expected);
    return a.length === b.length && timingSafeEqual(a, b);
  }
}
