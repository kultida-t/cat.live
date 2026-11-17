import { type INestApplication } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import { createServer, type IncomingHttpHeaders, type Server } from 'node:http';
import type { AddressInfo } from 'node:net';
import request from 'supertest';
import { AppModule } from '../src/app.module.js';
import { configureApp } from '../src/app.setup.js';
import { PrismaService } from '../src/prisma/prisma.service.js';
import { OBJECT_PRESIGNER, type PresignPutInput } from '../src/media/s3-presigner.js';

const CIL_KEY = 'test-cil-key';
const PRESET = 'avatar_400';
const CALLBACK_BASE_URL = 'https://callback.test';
const CALLBACK_TYPE = 'avatar';
const CALLBACK_SECRET = 'test-callback-secret';
const CALLBACK_URL = `${CALLBACK_BASE_URL}/api/webhooks/cloudimagelab?type=${CALLBACK_TYPE}&secret=${CALLBACK_SECRET}`;

describe('Media API — รูปโปรไฟล์ (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let jwt: JwtService;
  let cil: Server;
  let cilCalls: { body: { s3Key: string; outputPath: string; presetNames: string[]; callbackUrl: string }; headers: IncomingHttpHeaders }[] = [];
  let cilFileSeq = 0;
  const presigns: PresignPutInput[] = [];

  beforeAll(async () => {
    cil = createServer((req, res) => {
      let raw = '';
      req.on('data', (c: Buffer) => (raw += c));
      req.on('end', () => {
        cilFileSeq += 1;
        cilCalls.push({ body: JSON.parse(raw), headers: req.headers });
        res.writeHead(202, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ fileId: `cil-file-${cilFileSeq}`, status: 'Processing' }));
      });
    });
    await new Promise<void>((resolve) => cil.listen(0, '127.0.0.1', resolve));
    const port = (cil.address() as AddressInfo).port;
    process.env.CLOUDIMAGELAB_BASE_URL = `http://127.0.0.1:${port}`;
    process.env.CLOUDIMAGELAB_API_KEY = CIL_KEY;
    process.env.CLOUDIMAGELAB_CALLBACK_BASE_URL = CALLBACK_BASE_URL;
    process.env.CLOUDIMAGELAB_CALLBACK_TYPE = CALLBACK_TYPE;
    process.env.CLOUDIMAGELAB_CALLBACK_SECRET = CALLBACK_SECRET;
    process.env.CLOUDIMAGELAB_AVATAR_PRESET = PRESET;
    process.env.AVATAR_SOURCE_BUCKET = 'test-bucket';

    const moduleRef = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(OBJECT_PRESIGNER)
      .useValue({
        presignPut: async (input: PresignPutInput) => {
          presigns.push(input);
          return `https://s3.test/${input.key}?signature=fake`;
        },
      })
      .compile();
    app = configureApp(moduleRef.createNestApplication());
    await app.init();
    prisma = app.get(PrismaService);
    jwt = app.get(JwtService);
  });

  beforeEach(async () => {
    cilCalls = [];
    cilFileSeq = 0;
    presigns.length = 0;
    await prisma.$executeRawUnsafe(
      'TRUNCATE users, user_private, cats, cat_caretakers, refresh_tokens, user_avatars, media_uploads RESTART IDENTITY CASCADE',
    );
  });

  afterAll(async () => {
    await app.close();
    cil.close();
  });

  const http = () => request(app.getHttpServer());
  let phoneSeq = 0;

  async function createUser(name: string) {
    phoneSeq += 1;
    const user = await prisma.user.create({
      data: {
        displayName: name,
        method: 'phoneOtp',
        private: { create: { phone: `089888${String(phoneSeq).padStart(4, '0')}` } },
      },
    });
    return { id: user.id, token: await jwt.signAsync({ sub: user.id }) };
  }

  /** ขั้นที่ 1 — ขอ presigned URL */
  function requestUpload(token: string, body: Record<string, unknown> = { contentType: 'image/png', fileSize: 2048 }) {
    return http().post('/media/avatar/upload-url').set('Authorization', `Bearer ${token}`).send(body);
  }

  /** ขั้นที่ 3 — แจ้งว่าอัปโหลดเสร็จ */
  function completeUpload(token: string, uploadId: string) {
    return http().post(`/media/avatar/${uploadId}/complete`).set('Authorization', `Bearer ${token}`);
  }

  /** ทำครบทั้งสองขั้น ได้ fileId ของ CloudImageLab กลับมา */
  async function uploadAvatar(token: string) {
    const created = await requestUpload(token).expect(201);
    return completeUpload(token, created.body.uploadId).expect(202);
  }

  function callback(fileId: string, url: string, secret: string | null = CALLBACK_SECRET) {
    const req = http().post('/api/webhooks/cloudimagelab');
    if (secret !== null) req.query({ type: CALLBACK_TYPE, secret });
    else req.query({ type: CALLBACK_TYPE });
    return req.send({
      fileId,
      status: 'Completed',
      variants: [{ presetName: PRESET, url }],
      error: null,
    });
  }

  it('ขอ URL อัปโหลด → ได้ presigned URL ที่ผูกกับโฟลเดอร์ของผู้ใช้เท่านั้น และอายุสั้น', async () => {
    const me = await createUser('ผู้ใช้');
    const res = await requestUpload(me.token).expect(201);

    expect(res.body).toEqual({
      uploadId: expect.any(String),
      uploadUrl: expect.stringContaining('https://s3.test/'),
      expiresInSeconds: 300,
      headers: { 'Content-Type': 'image/png' },
    });
    expect(presigns).toHaveLength(1);
    expect(presigns[0]!.key).toMatch(new RegExp(`^catlive/avatars/${me.id}/[0-9a-f-]+\\.png$`));
    expect(presigns[0]).toMatchObject({ contentType: 'image/png', contentLength: 2048, expiresInSeconds: 300 });
    expect(cilCalls).toHaveLength(0);
  });

  it('แจ้งอัปโหลดเสร็จ → สั่ง CloudImageLab ด้วย s3Key เดียวกันและค่าที่ถูกต้อง', async () => {
    const me = await createUser('ผู้ใช้');
    const res = await uploadAvatar(me.token);

    expect(res.body).toEqual({ uploadId: expect.any(String), status: 'processing' });
    expect(cilCalls).toHaveLength(1);
    expect(cilCalls[0]!.headers['x-api-key']).toBe(CIL_KEY);
    expect(cilCalls[0]!.body).toEqual({
      s3Key: presigns[0]!.key,
      outputPath: `avatars/${me.id}`,
      presetNames: [PRESET],
      callbackUrl: CALLBACK_URL,
    });
    const upload = await prisma.mediaUpload.findFirstOrThrow({ where: { userId: me.id } });
    expect(upload).toMatchObject({ status: 'processing', fileId: 'cil-file-1' });
  });

  it('แจ้งเสร็จซ้ำ → ไม่สั่งประมวลผลซ้ำ', async () => {
    const me = await createUser('ผู้ใช้');
    const created = await requestUpload(me.token).expect(201);
    await completeUpload(me.token, created.body.uploadId).expect(202);
    const again = await completeUpload(me.token, created.body.uploadId).expect(202);
    expect(again.body.status).toBe('processing');
    expect(cilCalls).toHaveLength(1);
  });

  it('ชนิดไฟล์ที่ไม่รองรับหรือขนาดเกินกำหนด → 400 และไม่ออก URL', async () => {
    const me = await createUser('ผู้ใช้');
    await requestUpload(me.token, { contentType: 'text/plain', fileSize: 100 }).expect(400);
    await requestUpload(me.token, { contentType: 'image/png', fileSize: 10 * 1024 * 1024 + 1 }).expect(400);
    await requestUpload(me.token, { contentType: 'image/png', fileSize: 0 }).expect(400);
    expect(presigns).toHaveLength(0);
  });

  it('ไม่มี token → 401', async () => {
    await http().post('/media/avatar/upload-url').send({ contentType: 'image/png', fileSize: 10 }).expect(401);
    await http().post('/media/avatar/00000000-0000-4000-8000-000000000000/complete').expect(401);
  });

  it('แจ้งเสร็จของรายการคนอื่น หรือ id ที่ไม่ถูกรูปแบบ → 404 / 400 และไม่สั่งประมวลผล', async () => {
    const me = await createUser('ผู้ใช้');
    const other = await createUser('คนอื่น');
    const created = await requestUpload(me.token).expect(201);
    await completeUpload(other.token, created.body.uploadId).expect(404);
    await completeUpload(me.token, 'not-a-uuid').expect(400);
    expect(cilCalls).toHaveLength(0);
  });

  it('callback ที่ secret ไม่ถูกต้องหรือไม่มี secret → 401 และไม่เปลี่ยนข้อมูล', async () => {
    const me = await createUser('ผู้ใช้');
    await uploadAvatar(me.token);
    await callback('cil-file-1', 'https://cdn.test/a.webp', 'wrong-secret').expect(401);
    await callback('cil-file-1', 'https://cdn.test/a.webp', null).expect(401);
    const upload = await prisma.mediaUpload.findUniqueOrThrow({ where: { fileId: 'cil-file-1' } });
    expect(upload.status).toBe('processing');
    expect(await prisma.userAvatar.count()).toBe(0);
  });

  it('callback สำเร็จ → บันทึกรูปปัจจุบัน ประวัติรูป และแสดงใน /auth/me', async () => {
    const me = await createUser('ผู้ใช้');
    await uploadAvatar(me.token);
    await callback('cil-file-1', 'https://cdn.test/a.webp').expect(200);

    const list = await http().get('/media/avatars').set('Authorization', `Bearer ${me.token}`).expect(200);
    expect(list.body).toEqual([{ id: expect.any(String), url: 'https://cdn.test/a.webp', isCurrent: true }]);
    const profile = await http().get('/auth/me').set('Authorization', `Bearer ${me.token}`).expect(200);
    expect(profile.body.avatarUrl).toBe('https://cdn.test/a.webp');
  });

  it('callback ซ้ำ fileId เดิม → ไม่เพิ่มรูปซ้ำ', async () => {
    const me = await createUser('ผู้ใช้');
    await uploadAvatar(me.token);
    await callback('cil-file-1', 'https://cdn.test/a.webp').expect(200);
    await callback('cil-file-1', 'https://cdn.test/a.webp').expect(200);
    expect(await prisma.userAvatar.count({ where: { userId: me.id } })).toBe(1);
  });

  it('ประมวลผลไม่สำเร็จ → ไม่เปลี่ยนรูปปัจจุบัน และบันทึกสถานะล้มเหลว', async () => {
    const me = await createUser('ผู้ใช้');
    await uploadAvatar(me.token);
    await callback('cil-file-1', 'https://cdn.test/a.webp').expect(200);
    await uploadAvatar(me.token);
    await http()
      .post('/api/webhooks/cloudimagelab')
      .query({ type: CALLBACK_TYPE, secret: CALLBACK_SECRET })
      .send({ fileId: 'cil-file-2', status: 'Failed', variants: [], error: 'unsupported image' })
      .expect(200);

    const upload = await prisma.mediaUpload.findUniqueOrThrow({ where: { fileId: 'cil-file-2' } });
    expect(upload).toMatchObject({ status: 'failed', error: 'unsupported image' });
    const profile = await http().get('/auth/me').set('Authorization', `Bearer ${me.token}`).expect(200);
    expect(profile.body.avatarUrl).toBe('https://cdn.test/a.webp');
  });

  it('เลือกรูปที่เคยใช้กลับมาเป็นรูปปัจจุบันได้ และรูปของคนอื่นเลือกไม่ได้', async () => {
    const me = await createUser('ผู้ใช้');
    const other = await createUser('คนอื่น');
    await uploadAvatar(me.token);
    await callback('cil-file-1', 'https://cdn.test/first.webp').expect(200);
    await uploadAvatar(me.token);
    await callback('cil-file-2', 'https://cdn.test/second.webp').expect(200);

    const list = await http().get('/media/avatars').set('Authorization', `Bearer ${me.token}`).expect(200);
    const first = list.body.find((a: { url: string }) => a.url.endsWith('first.webp'));
    await http()
      .post(`/media/avatars/${first.id}/select`)
      .set('Authorization', `Bearer ${me.token}`)
      .expect(204);
    const profile = await http().get('/auth/me').set('Authorization', `Bearer ${me.token}`).expect(200);
    expect(profile.body.avatarUrl).toBe('https://cdn.test/first.webp');

    await http()
      .post(`/media/avatars/${first.id}/select`)
      .set('Authorization', `Bearer ${other.token}`)
      .expect(404);
  });
});
