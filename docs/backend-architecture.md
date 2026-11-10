# สถาปัตยกรรม Backend + โครง Repo Phase 0 — แมว.live

> **สถานะ:** ร่างวิเคราะห์ — รอพี่มาเต็มตรวจ ยังไม่ใช่ baseline
> **อิงจาก:** `docs/dev-roadmap.md` (stack+เฟส) + `docs/data-schema.md` (ตาราง) + มาตรฐาน UOAA
> **จัดทำเมื่อ:** 2026-11-10

---

## 1. โครง Repo — แนะนำ Monorepo

ใช้ repo `catlive` อันเดียวที่มีอยู่นี่แหละ เก็บทุกอย่างไว้ด้วยกัน:

```
catlive/
├── apps/
│   ├── mobile/        # แอป React Native (Expo)
│   └── api/           # backend NestJS
├── packages/
│   └── shared/        # types + validation ที่หน้าบ้าน-หลังบ้านใช้ร่วมกัน
├── docs/              # เอกสารทั้งหมด (อยู่แล้ว)
└── scripts/           # สคริปต์ช่วยงาน (อยู่แล้ว)
```

**เพราะอะไร:** พัฒนาคนเดียว+AI — หน้าบ้านและหลังบ้านใช้ TypeScript เหมือนกัน แชร์ type ของ API/ตารางผ่าน `packages/shared` ได้เลย แก้ฟิลด์ทีเดียวเห็นผลทั้งสองฝั่ง ไม่ต้องไล่แก้ 2 repo
**เครื่องมือ:** pnpm workspaces หรือ npm workspaces ธรรมดาก็พอ (ยังไม่ต้อง Turborepo ช่วงแรก)

## 2. โมดูล NestJS เทียบชั้น UOAA และตาราง

| NestJS Module | อยู่ชั้นมาตรฐานไหน | ดูแลตาราง |
|---|---|---|
| `AuthModule` | 7 Trust — ยืนยันตัวตน (U-05) | users, user_private |
| `UsersModule` | 4 Business — โปรไฟล์+สิทธิ์ | users, user_private, user_addresses |
| `CatsModule` | 4 Business — แมว+สุขภาพ | cats, cat_caretakers, cat_health |
| `FeedModule` | 4 Business — social | posts, comments, likes, saves, follows |
| `ReportsModule` | 7 Trust — รายงาน/ดูแลชุมชน | reports |
| `AnnouncementsModule` | 4 Business — ประกาศ+workflow | announcements, (ลิงก์ posts) |
| `SightingsModule` | 4 Business — เบาะแส | sightings |
| `PlacesModule` | 5 Data — พิกัด/ค้นใกล้ | places, place_reviews |
| `AiModule` | 2 Embedded AI — ผ่าน AI Model Router (U-02/U-11) | ai_chats, ai_messages, knowledge_chunks |
| `PaymentsModule` | 6 Integration — เงิน | transactions |
| `DevicesModule` | 6 Integration — Tag/IoT | devices, cat_locations |
| `ChatModule` | 4 Business — ข้อความ | chats, chat_members, messages |
| `NotificationsModule` | 6 Integration — แจ้งเตือน | (อ่าน events → push/LINE) |
| `FilesModule` | 6 Integration — สื่อ | media (S3 + คิวลบ EXIF) |
| `AuditModule` | 7 Trust — U-10 | audit_logs |
| `EventsModule` | 5 Data — กระดานเหตุการณ์ (U-08) | events |
| `WebhooksModule` | 3 Agent Interface — U-09 | webhook_subscriptions |
| `McpModule` | 3 Agent Interface — U-04 (placeholder) | — |

> หลักคิด: 1 module = 1 โดเมนธุรกิจ = ตารางกลุ่มเดียว เผื่อวันไหนใหญ่ขึ้นแล้วแยกเป็น service ตาม UOAA ได้โดยไม่ต้องรื้อ

## 3. วิธีทำ API (U-03 API First)

1. ออกแบบ endpoint ใน **OpenAPI spec ก่อน** ทุกตัว
2. generate types จาก spec ลง `packages/shared` → หน้าบ้านกับหลังบ้านเห็นสัญญาเดียวกัน
3. ค่อยเขียนโค้ด implement + contract test เทียบ spec
4. URL ทุกตัวใต้ `/api/v1/` — เผื่อเปลี่ยนสัญญาในอนาคตโดยไม่ทำลูกค้าเก่าพัง

## 4. จุด "แตะ" Agent Interface ตั้งแต่ต้น (ตามคำสั่งพี่คิง)

| ชิ้น | ทำตอน Phase 0 แค่ไหน |
|---|---|
| OpenAPI spec | ครบทุก endpoint ตั้งแต่แรก — นี่คือหน้าด่านของ agent แล้ว |
| `McpModule` | วางโครง server + ลิสต์ tools ที่วางแผนไว้ ยังไม่เปิดใช้จริง |
| tools ที่เผื่อไว้ | ระดับอ่านอย่างเดียวก่อน: `search_lost_cats`, `get_places_nearby`, `get_announcement` (ระดับ L1–L2 ตามสเกล agent ของ UOAA — เขียน/กระทำจริง L4–L5 ค่อยเปิดทีหลังพร้อมระบบอนุมัติ) |
| Webhook dispatcher | `EventsModule` → ยิงตาม `webhook_subscriptions` ทำโครงไว้พร้อมใช้ |
| Token scopes | ออกแบบ JWT เผื่อ scope (เช่น `read:announcements`) ตั้งแต่ต้น วันที่ agent มาจะได้แยกสิทธิ์ได้ทันที |

## 5. ยืนยันตัวตน (เผื่อขึ้น UNIVERZA Gateway)

- ทำชั้น `IdentityProvider` เป็น interface กลาง — วันนี้ implement แบบยืนตัวเอง (OIDC + LINE Login + email)
- วันที่ย้ายขึ้น UNIVERZA Gateway แค่เขียน provider ใหม่ให้ implement interface เดิม ไม่ต้องแก้โค้ดธุรกิจเลย
- JWT access + refresh token, ใส่ scopes ไว้ใน token (ดูข้อ 4)

## 6. กลไกบังคับ "ฟิลด์ลับห้ามออก API" (หัวใจของแอปนี้)

1. **ตารางลับไม่มี endpoint สาธารณะเลย** — `user_private`, `sightings.location_point`, `cat_locations` อ่านได้ผ่าน endpoint ที่ล็อกเจ้าของเท่านั้น (`/me/...`)
2. **Response ใช้ allowlist ไม่ใช่ blocklist** — DTO ประกาศชัด ๆ ว่า "ฟิลด์ไหนออกได้บ้าง" ฟิลด์ใหม่จะไม่หลุดออกไปเองโดยไม่ได้ตั้งใจ
3. **ประกาศสาธารณะส่งแค่ `area_label`** — `location_point`/`secret_landmark` อยู่ใน DTO เวอร์ชันเจ้าของเท่านั้น
4. **ทุกครั้งที่อ่านฟิลด์ลับ → audit log** — รู้ว่าใครเปิดข้อมูลอะไรเมื่อไหร่ (U-10)

## 7. Media Pipeline (รูป/วิดีโอ)

```
อัปโหลด → S3 (ชั่วคราว) → คิว BullMQ/Redis → ลบ EXIF GPS + ตรวจชนิด/ขนาดซ้ำ
        → ย้ายเข้าที่จริง → ผูกกับโพสต์/แมว → ล้างไฟล์ชั่วคราว
```

- ลบ GPS ใน EXIF เสมอก่อนเก็บ — ไม่งั้นรูปแมวหายรั่วพิกัดบ้านคนโพสต์
- เช็กขีดจำกัด (รูป ≤3, วิดีโอ ≤60 วิ ≤200MB) ซ้ำฝั่ง server แม้ client เช็กแล้ว

## 8. Events → แจ้งเตือน

- ทุกโมดูลยิง event ผ่าน `EventsModule` (ลงตาราง `events`)
- `NotificationsModule` หยิบ event ไปส่ง: push (Expo), LINE OA, webhook ภายนอก
- เช็ก `quiet_hours` ของผู้รับก่อนส่งเสมอ (ยกเว้นเหตุฉุกเฉินที่ตกลงกัน)

## 9. เทคเลือกเสริมที่เสนอ

| เรื่อง | เสนอ | เหตุ |
|---|---|---|
| ORM | Prisma | นิยมคู่ NestJS, type-safe, migration ชัด — ส่วน query พิกัด PostGIS ใช้ raw SQL เฉพาะจุด |
| คิวงาน | BullMQ + Redis | คิวลบ EXIF, ส่งแจ้งเตือน, webhook retry |
| Validation | zod หรือ class-validator ใน `shared` | schema เดียวใช้ได้ทั้งสองฝั่ง |

## 10. ประเด็นรอตัดสินใจ

1. Monorepo ตามข้อ 1 โอเคไหม (หรืออยากแยก repo แอป/api)
2. ORM เลือก Prisma ตามข้อ 9 ไหม
3. LINE OA/LINE Login เอาเข้าเฟสไหน (ใน roadmap อยู่เฟส 8 — แต่ล็อกอินไทยอาจความจำเป็นเร็วกว่านั้น รอดูคำตอบ BA)
4. Expo push + ช่องทางแจ้งเตือนอื่นลำดับความสำคัญ
