# แมว.live API (Phase 0 — Auth)

Backend ของแอป Flutter (`app/`) ตาม `docs/backend-architecture.md` และ `docs/dev-roadmap.md`

## การตัดสินใจ (ตัดสินแล้ว — ไม่ต้องรอประชุม)

| เรื่อง | เลือก | เหตุผล |
|---|---|---|
| Framework | NestJS 12 + TypeScript (ESM) | ตรงกับเอกสาร roadmap/architecture อยู่แล้ว ภาษาเดียวกับแอป/ชุด shared |
| ฐานข้อมูล | PostgreSQL 18 | ตรงเอกสาร; PostGIS/pgvector เพิ่มตอนถึง Phase ที่ใช้ |
| ORM | Prisma 7.10 + `@prisma/adapter-pg` | Prisma 8 ยังเป็น release candidate บน npm จึงยังไม่ใช้ในงานจริง |
| OTP | เก็บเป็น scrypt hash, หมดอายุ 5 นาที, ขอใหม่ได้หลัง 60 วิ, ผิด 5 ครั้งล็อก 15 นาที | ตรงกติกาเดิมในแอป |
| ผู้ให้บริการ SMS | interface `SmsSender` — ตอนพัฒนาใช้ `ConsoleSmsSender` แสดงรหัสใน console ของ server | ยังไม่เลือกผู้ให้บริการจริง; ระบบจะไม่ยอมรันบน `NODE_ENV=production` จนกว่าจะตั้งผู้ให้บริการจริง |
| PIN | scrypt hash + salt, ผิด 5 ครั้งล็อก 15 นาที นับบน **server** | แอปเดิมนับบนเครื่องอย่างเดียว ซึ่งหลบได้ |
| Session | JWT access 15 นาที + refresh token 30 วัน (หมุนใช้ทุกครั้ง, เก็บ sha256) | ใช้ token เก่าซ้ำ = ยกเลิกทุก session ของบัญชี |
| Social login (Apple/Google/LINE) | ยังไม่ทำ | ต้องมี credential จากผู้ให้บริการก่อน |
| AUTH-04 (รายการอุปกรณ์/ออกจากระบบจากระยะไกล) | ยังไม่ทำ | งานถัดไป |

## เอนด์พอยต์

| Method | Path | ใช้เมื่อ |
|---|---|---|
| POST | `/auth/otp/request` | ขอรหัส OTP → `{refCode, expiresAt, resendAvailableAt, maskedPhone}` |
| POST | `/auth/otp/verify` | ยืนยัน OTP → สร้างบัญชีถ้ายังไม่มี → `{accessToken, refreshToken, expiresIn, user}` |
| POST | `/auth/pin/login` | เข้าด้วยเบอร์ + PIN |
| POST | `/auth/pin` | ตั้ง PIN (ต้องมี token และบัญชีผูกเบอร์) |
| POST | `/auth/pin/change` | เปลี่ยน PIN (ต้องยืนยัน PIN เดิม) |
| POST | `/auth/refresh` | หมุน refresh token |
| POST | `/auth/logout` | ยกเลิก refresh token |
| GET | `/auth/me` | ข้อมูลบัญชีปัจจุบัน |

ข้อผิดพลาดทุกเคสตอบเป็น `{code, ...}` เช่น `otp_invalid`, `otp_locked` (มี `unlockSeconds`), `pin_invalid` (มี `remainingAttempts`), `pin_locked`, `no_pin_for_phone`, `age_under_13`, `guardian_consent_required`

## รันในเครื่อง

```bash
cd apps/api
npm install --legacy-peer-deps      # ต้องใส่ flag นี้ เพราะ npm 10 ชนกับ dependency บางตัวของ Nest 12
cp .env.example .env                # แล้วตั้ง JWT_SECRET ให้เป็นค่าสุ่มของเครื่อง
npx prisma migrate deploy           # ใช้ DATABASE_URL ใน .env
npx nest build && PORT=3000 node dist/main.js
```

ขอ OTP แล้วดูรหัสใน console ของ server (บรรทัด `[DevSms] OTP ...`)

## ต่อฐานข้อมูล staging (สำหรับทีม)

ห้ามใส่รหัสผ่านลงในไฟล์ที่ git ติดตาม และห้ามใช้ user `postgres` ในแอป ขั้นตอน:

1. ผู้ดูแลฐานข้อมูลสร้าง user ของแอปและ DB โดยให้ user เป็น owner ของ DB (ตัวอย่างชื่อ `catlive_app` / `catlive_staging`)
2. ตั้งรหัสใหม่ที่สุ่มขึ้นมา เก็บใน password manager ของทีม
3. ใส่ค่าในไฟล์ `apps/api/.env` บนเครื่องตัวเองเท่านั้น ในรูป URL (ถ้ารหัสมีอักขระพิเศษ ต้องแปลงด้วย URL encoding ก่อน):
   `DATABASE_URL="postgresql://catlive_app:<รหัส-encode-แล้ว>@<host>:5432/catlive_staging?sslmode=require"`
4. รัน `npx prisma migrate deploy` เพื่อสร้างตาราง (ทำเมื่อทีมตกลงแล้วเท่านั้น)
5. ตรวจว่า `DATABASE_URL` ไม่ปรากฏใน `git status` เลย

สำหรับเครื่องมือดูข้อมูลผ่าน MCP ให้ใช้ user แยกที่มีสิทธิ์อ่านอย่างเดียว อย่าใช้ user owner หรือ `postgres`

## ทดสอบ

```bash
npm run test:e2e   # ใช้ฐาน catlive_test เท่านั้น (ตั้งไว้ใน vitest.config.e2e.ts)
```

ฐานทดสอบต้องมีอยู่และ migrate แล้ว: `DATABASE_URL=postgresql://…/catlive_test npx prisma migrate deploy`

## ตำแหน่งโค้ด

- `src/auth/` — OTP, PIN, session, กติกา (`auth-rules.ts` ค่าเดียวกับแอป)
- `src/sms/` — ตัวส่ง SMS (interface + ตัวพัฒนา)
- `src/common/clock.ts` — เวลาที่ inject ได้ (เทสเลื่อนเวลาได้)
- `prisma/schema.prisma` — ตาราง `users`, `user_private` (เบอร์, ลับ), `pin_credentials`, `otp_challenges`, `refresh_tokens`, `audit_logs`
- `src/generated/prisma/` — ถูกสร้างจาก `prisma generate` (ไม่คอมมิต)
