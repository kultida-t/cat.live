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
import { AuditService } from '../common/audit.js';
import { CloudImageLabClient } from './cloudimagelab.client.js';
import { OBJECT_PRESIGNER, type ObjectPresigner } from './s3-presigner.js';

export const AVATAR_EXTENSIONS: Record<string, string> = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
};

export const MAX_AVATAR_BYTES = 10 * 1024 * 1024;
const UPLOAD_URL_TTL_SECONDS = 300;

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
    private readonly audit: AuditService,
    @Inject(OBJECT_PRESIGNER) private readonly presigner: ObjectPresigner,
  ) {}

  /** ออก presigned URL ให้แอปอัปโหลดรูปตรงไปที่ S3 — ไฟล์อยู่ใต้ `<โปรเจกต์>/avatars/<userId>/` ของผู้ใช้คนนั้นเท่านั้น */
  async createAvatarUpload(userId: string, input: { contentType: string; fileSize: number }) {
    const ext = AVATAR_EXTENSIONS[input.contentType];
    if (!ext) throw new UnsupportedMediaTypeException('รองรับเฉพาะไฟล์ JPEG, PNG และ WebP');
    this.requireMediaConfig();

    const s3Key = `${this.keyPrefix()}/avatars/${userId}/${randomUUID()}.${ext}`;
    const uploadUrl = await this.presigner.presignPut({
      key: s3Key,
      contentType: input.contentType,
      contentLength: input.fileSize,
      expiresInSeconds: UPLOAD_URL_TTL_SECONDS,
    });
    const upload = await this.prisma.mediaUpload.create({ data: { userId, s3Key } });
    return {
      uploadId: upload.id,
      uploadUrl,
      expiresInSeconds: UPLOAD_URL_TTL_SECONDS,
      headers: { 'Content-Type': input.contentType },
    };
  }

  /** ออก presigned URL สำหรับรูปแมว — ไฟล์ดิบใต้ `<prefix>/cats/<userId>/` แอปเอา imageUrl ไปส่งต่อให้ POST /cats/:id/photos
   *  (รูปแมวยังไม่ผ่าน CloudImageLab ในเฟสนี้ — อ่านตรงจาก CloudFront หน้า bucket) */
  async createCatPhotoUpload(userId: string, input: { contentType: string; fileSize: number }) {
    const ext = AVATAR_EXTENSIONS[input.contentType];
    if (!ext) throw new UnsupportedMediaTypeException('รองรับเฉพาะไฟล์ JPEG, PNG และ WebP');
    const s3Key = `${this.keyPrefix()}/cats/${userId}/${randomUUID()}.${ext}`;
    const uploadUrl = await this.presigner.presignPut({
      key: s3Key,
      contentType: input.contentType,
      contentLength: input.fileSize,
      expiresInSeconds: UPLOAD_URL_TTL_SECONDS,
    });
    return {
      uploadUrl,
      expiresInSeconds: UPLOAD_URL_TTL_SECONDS,
      headers: { 'Content-Type': input.contentType },
      imageUrl: `${this.publicMediaBase()}/${s3Key}`,
    };
  }

  /** base URL สาธารณะของไฟล์ใน bucket (CloudFront) — ค่าเริ่มต้นตาม infra ปัจจุบัน ปรับผ่าน PUBLIC_MEDIA_BASE_URL */
  private publicMediaBase(): string {
    return (
      this.config.get<string>('PUBLIC_MEDIA_BASE_URL') ??
      'https://d2kz9pl8iwzvcz.cloudfront.net'
    ).replace(/\/$/, '');
  }

  /** แอปอัปโหลดเสร็จแล้ว — สั่ง CloudImageLab ประมวลผล (Flow B) ผลจะกลับมาทาง callback เรียกซ้ำได้โดยไม่สั่งซ้ำ */
  async completeAvatarUpload(userId: string, uploadId: string) {
    const upload = await this.prisma.mediaUpload.findFirst({ where: { id: uploadId, userId } });
    if (!upload) throw new NotFoundException('ไม่พบรายการอัปโหลดนี้');
    const { presetName, callbackUrl } = this.requireMediaConfig();

    const claimed = await this.prisma.mediaUpload.updateMany({
      where: { id: upload.id, status: 'awaiting_upload' },
      data: { status: 'submitting' },
    });
    if (claimed.count === 0) return { uploadId, status: this.publicStatus(upload.status) };

    try {
      const { fileId } = await this.cil.processExternalFile({
        s3Key: upload.s3Key,
        outputPath: `avatars/${userId}`,
        presetNames: [presetName],
        callbackUrl,
      });
      await this.prisma.mediaUpload.update({
        where: { id: upload.id },
        data: { fileId, status: 'processing' },
      });
    } catch (error) {
      await this.prisma.mediaUpload.update({
        where: { id: upload.id },
        data: { status: 'awaiting_upload' },
      });
      throw error;
    }
    return { uploadId, status: 'processing' as const };
  }

  /** รับผลจาก CloudImageLab — ตรวจ key ก่อนทุกครั้ง และทำซ้ำได้โดยไม่เปลี่ยนผลเดิม */
  async handleCallback(secret: string | undefined, body: CallbackBody): Promise<void> {
    if (!this.isValidCallbackSecret(secret)) {
      await this.audit.record('media.callback_rejected', {
        entityType: 'media_upload',
        meta: { reason: 'invalid_secret' },
      });
      throw new UnauthorizedException();
    }
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

  private keyPrefix(): string {
    return this.config.get<string>('MEDIA_KEY_PREFIX') ?? 'catlive';
  }

  private publicStatus(status: string): string {
    return status === 'submitting' ? 'processing' : status;
  }

  /** ประกอบ URL ที่ CloudImageLab จะเรียกกลับ: base URL + path + ?type=&secret= */
  private requireMediaConfig(): { presetName: string; callbackUrl: string } {
    const presetName = this.config.get<string>('CLOUDIMAGELAB_AVATAR_PRESET');
    const baseUrl = this.config.get<string>('CLOUDIMAGELAB_CALLBACK_BASE_URL');
    const type = this.config.get<string>('CLOUDIMAGELAB_CALLBACK_TYPE');
    const secret = this.config.get<string>('CLOUDIMAGELAB_CALLBACK_SECRET');
    const bucket = this.config.get<string>('AVATAR_SOURCE_BUCKET');
    if (!presetName || !baseUrl || !type || !secret || !bucket) {
      throw new ServiceUnavailableException('ระบบประมวลผลรูปยังไม่ได้ตั้งค่า');
    }
    const query = new URLSearchParams({ type, secret });
    const callbackUrl = `${baseUrl.replace(/\/+$/, '')}/api/v1/webhooks/cloudimagelab?${query}`;
    return { presetName, callbackUrl };
  }

  private isValidCallbackSecret(received: string | undefined): boolean {
    const expected = this.config.get<string>('CLOUDIMAGELAB_CALLBACK_SECRET');
    if (!expected || !received) return false;
    const a = Buffer.from(received);
    const b = Buffer.from(expected);
    return a.length === b.length && timingSafeEqual(a, b);
  }
}
