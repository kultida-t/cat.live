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
| `FilesModule` | 6 Integration — สื่อ (ผ่าน CloudImageLab ของบริษัท) | media metadata |
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

## 7. Media Pipeline — ใช้ CloudImageLab ของบริษัท

ไม่ต้องทำระบบอัปโหลด/resize เอง ใช้บริการกลาง **CloudImageLab** (Flow A: Presigned Upload → Process) แบบ fire-and-forget:

```
แอปขอ presigned URL (ผ่าน api เรา) → อัปไฟล์ขึ้น S3 ตรง ๆ
→ แจ้ง upload-complete พร้อม callbackUrl → CloudImageLab gen variants
→ callback กลับมาที่ POST /api/v1/webhooks/cloudimagelab
→ api อัปเดตสถานะ media + ผูกกับโพสต์/แมว
```

- **Base URL:** staging `https://stg-cloudimagelab-api.mrfox.store` / production `https://cloudimagelab-api.univerza.co` — เอกสาร: `/docs/api-usage-guide`
- **Auth:** header `X-Api-Key` — ต้องขอ key ของแอปแมว.live จากทีมที่ดูแล CloudImageLab (staging/prod คนละตัว) เก็บใน env/secrets **ห้าม commit ลง repo**
- **Output path:** แยกตาม entity เช่น `posts/{postId}`, `cats/{catId}`, `announcements/{id}`, `avatars/{userId}` — ระบบ gen variants ตาม preset ที่ admin config (เช่น thumbnail/medium/large) รู้ path ล่วงหน้าได้ไม่ต้องถาม
- **Callback เป็นหลัก ไม่ใช้ polling** — endpoint รับ callback ต้อง verify ว่ามาจาก CloudImageLab จริง และรองรับ retry
- **เช็กฝั่งเราก่อนส่งเสมอ:** ชนิดไฟล์ (jpeg/png/webp/gif, mp4/mov/avi/webm), ขนาด (ระบบรับถึง 500MB แต่เราล็อกเอง รูป ≤3 ใบ/โพสต์, วิดีโอ ≤60 วิ ≤200MB)
- **⚠️ EXIF GPS:** เอกสารยังไม่ยืนยันว่า variants ลบ EXIF ให้ — ต้องถามทีม CloudImageLab ถ้าไม่ลบ เราต้อง strip เองก่อนอัป (ห้ามข้าม เพราะรูปจะรั่วพิกัดบ้านคนโพสต์)

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

## 10. ข้อตัดสินใจ (ล็อกแล้ว 2026-11-10)

| เรื่อง | ตัดสินใจ | เหตุผล |
|---|---|---|
| โครง repo | **Monorepo ใน repo `catlive` อันเดียว** | คนเดียวดูแล+ภาษาเดียวกัน แชร์ type ได้ ไม่ต้องไล่แก้ 2 repo |
| ORM | **Prisma** | นิยมคู่ NestJS, type-safe, migration ชัด — query พิกัด PostGIS ใช้ raw SQL เฉพาะจุด |
| LINE | **LINE Login เข้า Phase 0–1 คู่กับ auth** (คนไทยล็อกอินผ่าน LINE เป็นเรื่องพื้นฐาน) ส่วน **LINE OA ส่งข้อความ/แจ้งเตือนอยู่เฟส 8** ตาม roadmap เดิม | แยก "ล็อกอิน" (จำเป็นเร็ว) ออกจาก "ช่องทางแจ้งเตือน" (ทีหลังได้) |
| แจ้งเตือน | **Expo push เป็นช่องหลักก่อน** LINE OA ตามมาเฟส 8, email เป็น optional | push มากับ Expo อยู่แล้ว ไม่เพิ่ม dependency ภายนอก |
| ระบบสื่อ | **ใช้ CloudImageLab ของบริษัท** ไม่ทำเอง | มีของกลางตรง spec (ภาพ+วิดีโอ, variants, callback) ประหยัดงานและตรงแนว Integration Engine |

## 11. ประเด็นที่ต้องถาม/ทำต่อกับทีม CloudImageLab

1. ขอ **API key** สำหรับแอปแมว.live (staging ก่อน) + ให้ admin config **presets** ที่เราต้องการ (thumbnail square สำหรับฟีด, medium, large)
2. ยืนยันเรื่อง **EXIF GPS ถูกลบจาก variants หรือไม่** — ถ้าไม่ ต้อง strip ฝั่งเราก่อนอัป
3. วิธี **verify callback** ว่ามาจาก CloudImageLab จริง (signature/secret?) — ดูในเอกสารส่วน Callback (Webhook) อีกทีตอน implement
4. S3 ที่ variants ไปลงเป็นของบริษัท หรือต้อง BYOS (bring your own storage) — ถ้า BYOS ต้องเตรียม bucket ของเราเอง

## 12. บริการกลางของบริษัทที่เกี่ยวกับแมว.live (Univerza Shared Services)

ประกาศจากทีมกลาง (2026-11-10) — บริษัทมีบริการร่วมที่ทุกแอปสามารถ/ควรใช้ ไม่ต้องทำเอง:

| บริการ | คืออะไร | แมว.live ใช้ยังไง | เว็บ |
|---|---|---|---|
| **CloudImageLab** | อัปโหลด+ประมวลผลภาพ/วิดีโอ (variants, callback) | ระบบสื่อทั้งหมด (ข้อ 7) | stg `stg-cloudimagelab-api.mrfox.store` |
| **UGC** (Univerza Governance Center) | คลังเอกสารกลาง: นโยบาย, PDPA, เอกสารแอป + เวอร์ชัน + API | (ก) ลงทะเบียนแอปแมว.live ใน BackOffice — **บังคับตามประกาศ: เอกสารที่ล็อก baseline ต้องย้ายขึ้น UGC** (ข) หน้ากฎชุมชน/PDPA ในแอปดึงเนื้อหาจาก UGC API ได้ | stg `stg-ugc.mrfox.store` |
| **Today** | ตัวกลางข้อมูลภายนอก (อากาศ, ฝุ่น, ปฏิทิน, ทอง, หุ้น ฯลฯ) | nice-to-have เฟสหลัง: widget อากาศ/ฝุ่น หน้าแรกหรือใกล้ฉัน — บริการอื่นไม่เกี่ยว | stg `stg-today.mrfox.store` |

**กฎใช้ key ร่วมกันทุกบริการ:** key แยกตาม environment (staging/prod) และแยกตาม application, เรียกจาก backend เท่านั้น — ห้ามฝังในแอป/โค้ด/แชท/ภาพหน้าจอ (ตรงกับกฎ repo เราอยู่แล้ว)

**ลำดับ onboarding ที่ต้องทำ:** ลงทะเบียนแอปใน UGC ก่อน (ต้องมี owner/member + สถานะ Active) → แล้วค่อยขอ key บริการอื่นตาม flow ของแต่ละระบบ
