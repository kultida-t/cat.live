import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module.js';
import { configureApp } from '../src/app.setup.js';
import { CLOCK } from '../src/common/clock.js';
import { PrismaService } from '../src/prisma/prisma.service.js';
import { SMS_SENDER } from '../src/sms/sms.js';

const PHONE = '0899998888';
const ADULT_BIRTH_YEAR = 1990;

describe('Auth API (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let now: Date;
  const sentOtps: { phone: string; code: string; refCode: string }[] = [];

  const advance = (ms: number) => {
    now = new Date(now.getTime() + ms);
  };

  beforeAll(async () => {
    now = new Date('2026-11-17T10:00:00+07:00');
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(CLOCK)
      .useValue(() => now)
      .overrideProvider(SMS_SENDER)
      .useValue({
        sendOtp: async (phone: string, code: string, refCode: string) => {
          sentOtps.push({ phone, code, refCode });
        },
      })
      .compile();
    app = configureApp(moduleRef.createNestApplication());
    await app.init();
    prisma = app.get(PrismaService);
  });

  beforeEach(async () => {
    now = new Date('2026-11-17T10:00:00+07:00');
    sentOtps.length = 0;
    await prisma.$executeRawUnsafe(
      'TRUNCATE users, user_private, pin_credentials, otp_challenges, refresh_tokens, audit_logs RESTART IDENTITY CASCADE',
    );
  });

  afterAll(async () => {
    await app.close();
  });

  const http = () => request(app.getHttpServer());

  /** ขอ OTP แล้วยืนยันด้วยรหัสที่ส่งออกไป (ใช้ตัวส่งจำลอง) */
  async function loginWithOtp(
    overrides: Record<string, unknown> = {},
    status = 201,
  ) {
    // รอให้พ้นช่วงคูลดาวน์การขอรหัสซ้ำ (60 วินาที) เหมือนผู้ใช้จริง
    advance(60 * 1000);
    const requested = await http()
      .post('/api/v1/auth/otp/request')
      .send({ phone: PHONE })
      .expect(201);
    const sent = sentOtps.at(-1)!;
    const res = await http()
      .post('/api/v1/auth/otp/verify')
      .send({
        refCode: requested.body.refCode,
        code: sent.code,
        birthYear: ADULT_BIRTH_YEAR,
        guardianConsentGranted: false,
        ...overrides,
      });
    expect(res.status).toBe(status);
    return res;
  }

  async function setupPin(accessToken: string, pin = '123456') {
    await http()
      .post('/api/v1/auth/pin')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ pin })
      .expect(204);
  }

  describe('OTP', () => {
    it('ขอ OTP → ยืนยันสำเร็จ สร้างบัญชีใหม่และคืน token', async () => {
      const res = await loginWithOtp({ displayName: 'ลูกแก้ว' });
      expect(res.body.accessToken).toEqual(expect.any(String));
      expect(res.body.refreshToken).toEqual(expect.any(String));
      expect(res.body.user).toMatchObject({
        displayName: 'ลูกแก้ว',
        phoneMasked: '089-xxx-8888',
      });
    });

    it('รหัส OTP ผิด 5 ครั้ง → ล็อก 15 นาที และรหัสที่ถูกก็ใช้ไม่ได้ระหว่างล็อก', async () => {
      const requested = await http()
        .post('/api/v1/auth/otp/request')
        .send({ phone: PHONE })
        .expect(201);
      const body = (code: string) => ({
        refCode: requested.body.refCode,
        code,
        birthYear: ADULT_BIRTH_YEAR,
        guardianConsentGranted: false,
      });
      const correct = sentOtps[0].code;
      const wrong = correct === '000000' ? '111111' : '000000';

      for (let i = 1; i <= 4; i++) {
        const res = await http()
          .post('/api/v1/auth/otp/verify')
          .send(body(wrong))
          .expect(401);
        expect(res.body).toMatchObject({
          code: 'otp_invalid',
          remainingAttempts: 5 - i,
        });
      }
      const fifth = await http()
        .post('/api/v1/auth/otp/verify')
        .send(body(wrong))
        .expect(423);
      expect(fifth.body).toMatchObject({
        code: 'otp_locked',
        unlockSeconds: 900,
      });

      const whileLocked = await http()
        .post('/api/v1/auth/otp/verify')
        .send(body(correct))
        .expect(423);
      expect(whileLocked.body.code).toBe('otp_locked');
    });

    it('รหัสหมดอายุหลัง 5 นาที → otp_expired', async () => {
      const requested = await http()
        .post('/api/v1/auth/otp/request')
        .send({ phone: PHONE })
        .expect(201);
      advance(5 * 60 * 1000);
      const res = await http()
        .post('/api/v1/auth/otp/verify')
        .send({
          refCode: requested.body.refCode,
          code: sentOtps[0].code,
          birthYear: ADULT_BIRTH_YEAR,
          guardianConsentGranted: false,
        })
        .expect(410);
      expect(res.body.code).toBe('otp_expired');
    });

    it('ขอรหัสซ้ำได้หลังรอ 60 วินาทีเท่านั้น', async () => {
      await http().post('/api/v1/auth/otp/request').send({ phone: PHONE }).expect(201);
      const early = await http()
        .post('/api/v1/auth/otp/request')
        .send({ phone: PHONE })
        .expect(429);
      expect(early.body).toMatchObject({
        code: 'otp_resend_wait',
        waitSeconds: 60,
      });

      advance(60 * 1000);
      await http().post('/api/v1/auth/otp/request').send({ phone: PHONE }).expect(201);
    });

    it('ผู้ใช้อายุต่ำกว่า 13 ปีสมัครไม่ได้ และอายุ 13–19 ต้องมีผู้ปกครองยินยอม', async () => {
      const under13 = await loginWithOtp({ birthYear: 2020 }, 403);
      expect(under13.body.code).toBe('age_under_13');

      const minor = await loginWithOtp(
        { birthYear: 2012, guardianConsentGranted: false },
        403,
      );
      expect(minor.body.code).toBe('guardian_consent_required');
    });
  });

  describe('PIN', () => {
    it('ตั้ง PIN ต้องมี token และล็อกอินด้วย PIN ได้', async () => {
      await http().post('/api/v1/auth/pin').send({ pin: '123456' }).expect(401);

      const { body } = await loginWithOtp();
      await setupPin(body.accessToken);

      const res = await http()
        .post('/api/v1/auth/pin/login')
        .send({ phone: PHONE, pin: '123456' })
        .expect(200);
      expect(res.body.user.phoneMasked).toBe('089-xxx-8888');
    });

    it('เบอร์ที่ยังไม่ตั้ง PIN → no_pin_for_phone', async () => {
      const res = await http()
        .post('/api/v1/auth/pin/login')
        .send({ phone: PHONE, pin: '123456' })
        .expect(404);
      expect(res.body.code).toBe('no_pin_for_phone');
    });

    it('PIN ผิด 5 ครั้ง → ล็อก 15 นาที แม้ PIN ถูกก็เข้าไม่ได้ จนกว่าจะหมดเวลา', async () => {
      const { body } = await loginWithOtp();
      await setupPin(body.accessToken);

      for (let i = 1; i <= 4; i++) {
        const res = await http()
          .post('/api/v1/auth/pin/login')
          .send({ phone: PHONE, pin: '000000' })
          .expect(401);
        expect(res.body).toMatchObject({
          code: 'pin_invalid',
          remainingAttempts: 5 - i,
        });
      }
      const fifth = await http()
        .post('/api/v1/auth/pin/login')
        .send({ phone: PHONE, pin: '000000' })
        .expect(423);
      expect(fifth.body).toMatchObject({
        code: 'pin_locked',
        unlockSeconds: 900,
      });

      await http()
        .post('/api/v1/auth/pin/login')
        .send({ phone: PHONE, pin: '123456' })
        .expect(423);

      advance(15 * 60 * 1000);
      await http()
        .post('/api/v1/auth/pin/login')
        .send({ phone: PHONE, pin: '123456' })
        .expect(200);
    });

    it('pin/status บอกว่าบัญชีตั้ง PIN แล้วหรือยัง', async () => {
      const { body } = await loginWithOtp();
      const auth = `Bearer ${body.accessToken}`;
      expect(
        (
          await http()
            .get('/api/v1/auth/pin/status')
            .set('Authorization', auth)
            .expect(200)
        ).body,
      ).toEqual({ hasPin: false });
      await setupPin(body.accessToken);
      expect(
        (
          await http()
            .get('/api/v1/auth/pin/status')
            .set('Authorization', auth)
            .expect(200)
        ).body,
      ).toEqual({ hasPin: true });
    });

    it('ตรวจ PIN ของบัญชีที่ล็อกอินอยู่ ผิดครบเกณฑ์ก็ล็อก', async () => {
      const { body } = await loginWithOtp();
      const auth = `Bearer ${body.accessToken}`;
      await setupPin(body.accessToken);

      await http()
        .post('/api/v1/auth/pin/verify')
        .set('Authorization', auth)
        .send({ pin: '123456' })
        .expect(204);
      const wrong = await http()
        .post('/api/v1/auth/pin/verify')
        .set('Authorization', auth)
        .send({ pin: '000000' })
        .expect(401);
      expect(wrong.body).toMatchObject({
        code: 'pin_invalid',
        remainingAttempts: 4,
      });
      await http()
        .post('/api/v1/auth/pin/verify')
        .set('Authorization', auth)
        .send({ pin: '000000' })
        .expect(401);
      await http()
        .post('/api/v1/auth/pin/verify')
        .set('Authorization', auth)
        .send({ pin: '000000' })
        .expect(401);
      await http()
        .post('/api/v1/auth/pin/verify')
        .set('Authorization', auth)
        .send({ pin: '000000' })
        .expect(401);
      await http()
        .post('/api/v1/auth/pin/verify')
        .set('Authorization', auth)
        .send({ pin: '000000' })
        .expect(423);
      await http()
        .post('/api/v1/auth/pin/verify')
        .set('Authorization', auth)
        .send({ pin: '123456' })
        .expect(423);
    });

    it('เปลี่ยน PIN ต้องยืนยัน PIN เดิม และผิดครบเกณฑ์ก็ล็อก', async () => {
      const { body } = await loginWithOtp();
      const auth = `Bearer ${body.accessToken}`;
      await setupPin(body.accessToken);

      for (let i = 0; i < 5; i++) {
        await http()
          .post('/api/v1/auth/pin/change')
          .set('Authorization', auth)
          .send({ currentPin: '000000', newPin: '654321' })
          .expect(i < 4 ? 401 : 423);
      }
      await http()
        .post('/api/v1/auth/pin/change')
        .set('Authorization', auth)
        .send({ currentPin: '123456', newPin: '654321' })
        .expect(423);
    });

    it('OTP ที่ผ่านปลดล็อก PIN ที่ค้างอยู่', async () => {
      const { body } = await loginWithOtp();
      await setupPin(body.accessToken);
      for (let i = 0; i < 5; i++) {
        await http()
          .post('/api/v1/auth/pin/login')
          .send({ phone: PHONE, pin: '000000' });
      }
      await http()
        .post('/api/v1/auth/pin/login')
        .send({ phone: PHONE, pin: '123456' })
        .expect(423);

      await loginWithOtp();
      await http()
        .post('/api/v1/auth/pin/login')
        .send({ phone: PHONE, pin: '123456' })
        .expect(200);
    });
  });

  describe('Session', () => {
    it('refresh หมุน token ใหม่ และใช้ token เก่าซ้ำจะยกเลิกทุก session ของบัญชี', async () => {
      const first = (await loginWithOtp()).body;
      const rotated = (
        await http()
          .post('/api/v1/auth/refresh')
          .send({ refreshToken: first.refreshToken })
          .expect(200)
      ).body;
      expect(rotated.refreshToken).not.toBe(first.refreshToken);

      await http()
        .post('/api/v1/auth/refresh')
        .send({ refreshToken: first.refreshToken })
        .expect(401);
      await http()
        .post('/api/v1/auth/refresh')
        .send({ refreshToken: rotated.refreshToken })
        .expect(401);
    });

    it('logout ยกเลิก refresh token และ /api/v1/auth/me ต้องมี access token', async () => {
      const { body } = await loginWithOtp();

      await http().get('/api/v1/auth/me').expect(401);
      const me = await http()
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${body.accessToken}`)
        .expect(200);
      expect(me.body.displayName).toBe('ผู้ใช้แมว.live');

      await http()
        .post('/api/v1/auth/logout')
        .send({ refreshToken: body.refreshToken })
        .expect(204);
      await http()
        .post('/api/v1/auth/refresh')
        .send({ refreshToken: body.refreshToken })
        .expect(401);
    });
  });

  describe('Profile', () => {
    it('PUT /me/profile อัปเดต displayName/birthYear แล้วอ่านกลับได้จาก /auth/me', async () => {
      const { body } = await loginWithOtp();

      const updated = await http()
        .put('/api/v1/me/profile')
        .set('Authorization', `Bearer ${body.accessToken}`)
        .send({ displayName: 'ทาสแมว', birthYear: 1995 })
        .expect(200);
      expect(updated.body.displayName).toBe('ทาสแมว');
      expect(updated.body.birthYear).toBe(1995);

      const me = await http()
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${body.accessToken}`)
        .expect(200);
      expect(me.body.displayName).toBe('ทาสแมว');
      expect(me.body.birthYear).toBe(1995);

      const audits = await prisma.auditLog.findMany({
        where: { action: 'me.profile_updated' },
      });
      expect(audits).toHaveLength(1);
      expect(audits[0].actorId).toBe(me.body.id);
    });

    it('ปฏิเสธเมื่อไม่มี token, ส่ง body ว่าง หรือชื่อว่าง', async () => {
      const { body } = await loginWithOtp();

      await http()
        .put('/api/v1/me/profile')
        .send({ displayName: 'ทาสแมว' })
        .expect(401);
      await http()
        .put('/api/v1/me/profile')
        .set('Authorization', `Bearer ${body.accessToken}`)
        .send({})
        .expect(400);
      await http()
        .put('/api/v1/me/profile')
        .set('Authorization', `Bearer ${body.accessToken}`)
        .send({ displayName: '   ' })
        .expect(400);
    });
  });
});
