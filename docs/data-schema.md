# โครงสร้างฐานข้อมูลแมว.live (Data Schema Draft)

> **สถานะ:** ร่างวิเคราะห์ — รอพี่มาเต็ม/BA ตรวจ ยังไม่ใช่ baseline (requirement ยังรอคำตอบ 35 ข้อ)
> **อิงจาก:** `docs/requirement-analysis.md` (ข้อ 4 Entity) + `docs/dev-roadmap.md` (เฟสพัฒนา)
> **จัดทำเมื่อ:** 2026-11-10
> **ฐานข้อมูลเป้าหมาย:** PostgreSQL + PostGIS (พิกัด) + pgvector (ความรู้ AI)

---

## 1. หลักการออกแบบ

1. **แยกตาราง "ลับ" ออกจากตารางปกติ** — ฟิลด์ลับ (ที่อยู่, เลขบัญชี, พิกัดจริง, เบอร์/อีเมล) อยู่ตารางแยก เช่น `user_private` เพื่อบังคับกฎ "ห้ามออก API สาธารณะ" ได้ง่ายระดับตาราง ไม่ต้องเช็กทีละฟิลด์
2. **เก็บพิกัดจริง แต่โชว์แค่ย่าน** — ประกาศแมวหายเก็บ `location_point` ละเอียดไว้ใช้ค้น/แจ้งเตือนพื้นที่ใกล้เคียง แต่ API สาธารณะส่งออกเฉพาะ `area_label` (ชื่อย่าน ~500 ม.) เท่านั้น
3. **ทุก action สำคัญลง audit log** — ตรงมาตรฐาน U-10 ตั้งแต่ตารางแรก (ประกาศ, เบาะแส, เงิน, เปลี่ยนสิทธิ์)
4. **แนวทางทั่วไป:** ใช้ `uuid` เป็น primary key ทุกตาราง, เวลาเป็น `timestamptz`, ข้อมูลที่รูปทรงยืดหยุ่นใช้ `jsonb`, มี `created_at`/`updated_at` ครบ, ตารางที่ข้อมูลเป็นของผู้ใช้ใช้ soft delete (`deleted_at`) เพื่อรองรับสิทธิ์ลบข้อมูลตาม PDPA (U-07)

สัญลักษณ์ 🔒 = ฟิลด์ลับ ห้ามส่งออกผ่าน API สาธารณะเด็ดขาด (ดูสรุปข้อ 4)

---

## 2. ตารางตามกลุ่มเฟส

### Phase 0 — โครงระบบกลาง

**`audit_logs`** — บันทึกทุกการกระทำสำคัญของระบบ
| ฟิลด์ | ชนิด | คำอธิบาย |
|---|---|---|
| id | uuid |รหัส log |
| actor_id | uuid→users | ใครทำ (null = ระบบ) |
| action | text | เช่น announcement.create, report.resolve |
| entity_type / entity_id | text / uuid | กระทำกับอะไร |
| meta | jsonb | รายละเอียดเพิ่ม (ค่าเดิม→ค่าใหม่) |
| ip | inet | ที่อยู่ผู้เรียก |
| created_at | timestamptz |เวลาที่บันทึก |

**`events`** — คิวเหตุการณ์กลางเบา ๆ ให้ระบบอื่น subscribe (U-08)
| ฟิลด์ | ชนิด | คำอธิบาย |
|---|---|---|
| id | uuid |รหัสเหตุการณ์ |
| type | text | เช่น cat.lost, sighting.created, payment.paid |
| payload | jsonb | ข้อมูลเหตุการณ์ |
| emitted_at | timestamptz | เวลาที่เกิด |

**`webhook_subscriptions`** — เผื่อ Agent Interface/ระบบภายนอกมารับ event (U-09)
| ฟิลด์ | ชนิด | คำอธิบาย |
|---|---|---|
| id | uuid |รหัส subscription |
| owner_id | uuid→users | ใครลงทะเบียน |
| url | text | ปลายทางรับ webhook |
| event_types | text[] | อยากรับ event แบบไหน |
| secret | text | 🔒 ใช้เซ็นยืนยัน payload |
| is_active | bool |เปิด/ปิดการส่ง webhook |

### Phase 1 — แมวและฉัน

**`users`** — ข้อมูลสาธารณะของผู้ใช้
| ฟิลด์ | ชนิด | คำอธิบาย |
|---|---|---|
| id | uuid |รหัสผู้ใช้ |
| username | text | ไม่ซ้ำ |
| display_name | text | ชื่อที่โชว์ |
| avatar_url / bio | text |รูปโปรไฟล์ / คำแนะนำตัวสั้น |
| verified_status | text | pending / verified / rejected — ยืนยันตัวตน |
| locale | text | th / en |
| quiet_hours | jsonb | ช่วงเงียบแจ้งเตือน (ดีฟอลต์ 22:00–07:00) |
| role | text | user / staff / admin |
| created_at / updated_at / deleted_at | timestamptz | soft delete |

**`user_private`** 🔒 — ข้อมูลส่วนตัว เจ้าของเห็นคนเดียว (แยกตารางตามหลักการข้อ 1)
| ฟิลด์ | ชนิด | คำอธิบาย |
|---|---|---|
| user_id | uuid→users | PK |
| phone / email | text | 🔒 ไม่เปิดสาธารณะ |
| line_user_id | text | 🔒 ผูก LINE Login |
| treat_address | jsonb | 🔒 ที่อยู่รับขนมแมว |
| bank_name / bank_account_no | text | 🔒 บัญชีรับบริจาค — UI โชว์แค่ชื่อ+ท้าย 4 ตัว |
| id_verification | jsonb | 🔒 หลักฐานยืนยันตัวตน |

**`cats`** — แมวหลายตัวต่อผู้ใช้
| ฟิลด์ | ชนิด | คำอธิบาย |
|---|---|---|
| id | uuid |รหัสแมวในระบบ |
| owner_id | uuid→users | เจ้าของหลัก |
| public_id | text | Cat ID สาธารณะ @MAW000xxx |
| name / breed / sex / neutered / birth_date | text / bool / date |ชื่อ / สายพันธุ์ / เพศ / ทำหมันแล้วไหม / วันเกิด |
| photo_urls | text[] |รูปแมวหลายรูป |
| qr_payload | text | ข้อมูลใน QR Cat ID |
| status | text | normal / lost / found / memorial |
| created_at / updated_at / deleted_at | timestamptz |สร้าง / แก้ / ลบ (soft delete) |

**`cat_caretakers`** — ผู้ดูแลร่วมหลายคนต่อแมวตัวเดียว
| ฟิลด์ | ชนิด | คำอธิบาย |
|---|---|---|
| cat_id / user_id | uuid | คีย์รวม |
| role | text | co_owner / caretaker / viewer |

**`cat_health`** — สมุดสุขภาพและรูทีนดูแล
| ฟิลด์ | ชนิด | คำอธิบาย |
|---|---|---|
| id | uuid |รหัสบันทึกสุขภาพ |
| cat_id | uuid→cats |บันทึกของแมวตัวไหน |
| type | text | vaccine / weight / symptom / routine / note |
| detail | jsonb | รายละเอียดตาม type (เช่น ชื่อวัคซีน, น้ำหนัก) |
| attachments | text[] | รูปแนบ |
| record_date | date | วันที่บันทึก/นัดถัดไป |

### Phase 2 — ฟีดชุมชน

**`posts`**
| ฟิลด์ | ชนิด | คำอธิบาย |
|---|---|---|
| id | uuid |รหัสโพสต์ |
| author_id / cat_id | uuid | โพสต์ผูกแมวตัวไหน (ได้หรือไม่ได้) |
| type | text | normal / lost_cat (โพสต์จากประกาศ) |
| caption / category | text |ข้อความโพสต์ / หมวดหมู่ |
| media | jsonb | รูป ≤3 หรือวิดีโอ ≤60 วิ (เก็บ url+kind) — ลบ EXIF GPS ก่อนเก็บ |
| announcement_id | uuid→announcements | ถ้ามาจากประกาศแมวหาย |
| visibility | text | public / followers |
| created_at / updated_at / deleted_at | timestamptz |สร้าง / แก้ / ลบ (soft delete) |

**`comments`** (post_id, author_id, body, parent_id สำหรับตอบกลับ) · **`likes`** (post_id, user_id) · **`saves`** (post_id, user_id) · **`follows`** (follower_id, followee_id)

**`reports`** — รายงานโพสต์/ผู้ใช้/ประกาศส่งทีมงาน
| ฟิลด์ | ชนิด | คำอธิบาย |
|---|---|---|
| id | uuid |รหัสรายงาน |
| reporter_id | uuid→users |คนกดรายงาน |
| target_type / target_id | text / uuid | report อะไร (post/comment/user/announcement) |
| reason / detail | text |เหตุผลที่เลือก / รายละเอียดเพิ่มเติม |
| status | text | open / reviewing / resolved |
| resolved_by | uuid→users | ทีมงานคนปิดเคส |

### Phase 3 — แมวหายและประกาศ

**`announcements`** — ประกาศ 5 แบบ + ระดมทุน
| ฟิลด์ | ชนิด | คำอธิบาย |
|---|---|---|
| id | uuid |รหัสประกาศ |
| user_id / cat_id | uuid | ประกาศของใคร ผูกแมวตัวไหน |
| type | text | lost / found / help_wanted / adoption / foster / fundraiser |
| title / detail | text |หัวข้อประกาศ / รายละเอียด |
| area_label | text | ชื่อย่านที่โชว์สาธารณะ (~500 ม.) |
| location_point | geometry(Point,4326) | 🔒 พิกัดจริง ห้ามส่งสาธารณะ |
| secret_landmark | text | 🔒 จุดสังเกตลับ เฉพาะเจ้าของประกาศ |
| status | text | open / resolved / closed — ปิดแล้วถอนออกจากฟีด |
| post_id | uuid→posts | ลิงก์โพสต์ในฟีด (ถ้าสลับลงฟีด) |
| goal_amount / raised_amount | numeric | เฉพาะประกาศระดมทุน |
| created_at / updated_at / closed_at | timestamptz |สร้าง / แก้ / ปิดประกาศ |

**`sightings`** — เบาะแสพบแมว
| ฟิลด์ | ชนิด | คำอธิบาย |
|---|---|---|
| id | uuid |รหัสเบาะแส |
| announcement_id | uuid→announcements |เบาะแสของประกาศไหน |
| reporter_id | uuid→users | คนแจ้งเบาะแส |
| location_point | geometry(Point,4326) | 🔒 ส่งเจ้าของ+ทีมงานเท่านั้น |
| photo_url / note | text |รูปที่ถ่ายเจอ / บันทึกเพิ่มเติม |
| created_at | timestamptz |เวลาแจ้งเบาะแส |

### Phase 4 — ใกล้ฉัน

**`places`** — สถานที่ผูกพิกัด
| ฟิลด์ | ชนิด | คำอธิบาย |
|---|---|---|
| id | uuid |รหัสสถานที่ |
| name / category | text | cafe / clinic / shop / grooming / boarding / emergency_vet |
| location_point | geometry(Point,4326) | พิกัดสาธารณะ (อันนี้เปิดได้) |
| open_hours | jsonb | เวลาเปิดปิดรายวัน |
| phone / is_24h | text / bool | เบอร์จริง (รพ.สัตว์ฉุกเฉิน) |

**`place_reviews`** (place_id, user_id, rating, body) — เฟสถัดไปเสริมได้

### Phase 5 — Embedded AI

**`ai_chats`** / **`ai_messages`** — เซสชัน Cat AI ผูกกับแมวที่เลือก
| ตาราง | ฟิลด์สำคัญ |
|---|---|
| ai_chats | id, user_id, cat_id, channel (text/voice), created_at |
| ai_messages | id, chat_id, role (user/assistant), content, model_used (เก็บ provider+รุ่น ตรง U-11), disclaimer_shown |

**`knowledge_chunks`** — ความรู้การเลี้ยงแมวให้ AI ค้น (RAG)
| ฟิลด์ | ชนิด | คำอธิบาย |
|---|---|---|
| id | uuid |รหัสชิ้นความรู้ |
| source / title | text | ที่มาของความรู้ |
| content | text | เนื้อความ |
| embedding | vector | เวกเตอร์สำหรับค้นคล้าย (pgvector) |

### Phase 6 — รายได้

**`transactions`** — เลี้ยงขนม / บริจาค / ระดมทุน / สั่งซื้อ Tag
| ฟิลด์ | ชนิด | คำอธิบาย |
|---|---|---|
| id | uuid |รหัสธุรกรรม |
| type | text | treat / donation / fundraiser / tag_order |
| payer_id / payee_user_id | uuid→users | ผู้จ่าย / ผู้รับ (payee ไม่โชว์เลขบัญชีให้ payer) |
| announcement_id | uuid | ถ้าเป็นบริจาคประกาศระดมทุน |
| amount / fee_amount | numeric | ยอดจ่าย / ส่วนแบ่งแพลตฟอม (ถ้ามี) |
| status | text | pending / paid / failed / refunded |
| payment_ref | text | 🔒 อ้างอิงจากผู้ให้บริการชำระเงิน (QR) |
| shipping_address | jsonb | 🔒 ที่อยู่จัดส่ง (เฉพาะออเดอร์ของจริง) |
| created_at / paid_at | timestamptz |สร้างรายการ / จ่ายสำเร็จ |

### Phase 8 — Tag/IoT

**`devices`** — แมว.live Tag
| ฟิลด์ | ชนิด | คำอธิบาย |
|---|---|---|
| id | uuid |รหัสอุปกรณ์ในระบบ |
| public_id | text | รหัสอุปกรณ์ |
| cat_id | uuid→cats | ผูกแมวตัวไหน |
| battery_pct / is_connected | int / bool | สถานะอุปกรณ์ |
| last_seen_at | timestamptz |เห็นอุปกรณ์ล่าสุดเมื่อไหร่ |

**`cat_locations`** 🔒 — ประวัติตำแหน่งจาก Tag
| ฟิลด์ | ชนิด | คำอธิบาย |
|---|---|---|
| id | uuid |รหัสบันทึกพิกัด |
| device_id | uuid→devices |พิกัดจาก Tag ตัวไหน |
| location_point | geometry(Point,4326) | 🔒 เจ้าของแมว+ผู้ดูแลเท่านั้น |
| recorded_at | timestamptz |เวลาที่บันทึกพิกัด |

### ข้อความ (ทุกเฟสที่ต้องแชต)

**`chats`** / **`messages`** — แชตระหว่างผู้ใช้ รวมแชตยืนยันผู้พบแมว
| ตาราง | ฟิลด์สำคัญ |
|---|---|
| chats | id, type (direct / finder_verify), announcement_id (ถ้าเป็นแชตยืนยันผู้พบ), created_at |
| chat_members | chat_id, user_id — 🔒 เห็นแชตได้เฉพาะสมาชิก |
| messages | id, chat_id, sender_id, body / media, created_at |

---

## 3. ความสัมพันธ์หลัก (ภาพรวม)

```
users ─┬─< cats ─┬─< cat_health
       │         ├─< cat_caretakers >── users
       │         └─< devices >── cat_locations
       ├─< posts >── comments / likes / saves
       │     └─ announcement_id ──> announcements ──< sightings
       ├─< announcements ─┬─ post_id ──> posts
       │                  └─< transactions (ระดมทุน)
       ├─< ai_chats >── ai_messages
       ├─< chats (ผ่าน chat_members) >── messages
       └─< transactions / follows / reports / webhook_subscriptions
places >── place_reviews     audit_logs/events เก็บแยกอิสระ
```

## 4. ตารางฟิลด์ลับห้ามออก API สาธารณะ

| ฟิลด์ | อยู่ตาราง | ใครเห็นได้ |
|---|---|---|
| เบอร์ / อีเมล / LINE ID | `user_private` | เจ้าของเท่านั้น (ไม่เปิดสาธารณะเลย) |
| ที่อยู่รับขนม | `user_private.treat_address` | เจ้าของ + ระบบจัดส่ง |
| เลขบัญชีรับบริจาค | `user_private.bank_*` | เจ้าของ — UI โชว์ชื่อ+ท้าย 4 ตัวเท่านั้น |
| หลักฐานยืนยันตัวตน | `user_private.id_verification` | เจ้าของ + ทีมงานตรวจสอบ |
| พิกัดจริงประกาศ | `announcements.location_point` | เจ้าของประกาศเท่านั้น — สาธารณะเห็นแค่ `area_label` |
| จุดสังเกตลับ | `announcements.secret_landmark` | เจ้าของประกาศเท่านั้น |
| พิกัดเบาะแส | `sightings.location_point` | เจ้าของประกาศ + ทีมงาน |
| ที่อยู่จัดส่ง / ref ชำระเงิน | `transactions` | คู่ธุรกรรมเท่านั้น (payer ไม่เห็นบัญชี payee) |
| ตำแหน่ง Tag เรียลไทม์+ย้อนหลัง | `cat_locations` | เจ้าของแมว + ผู้ดูแล |
| เนื้อแชต | `messages` | สมาชิกแชตเท่านั้น |
| secret webhook | `webhook_subscriptions.secret` | เจ้าของ subscription เท่านั้น |

## 5. ประเด็นที่รอคำตอบ/อาจขยับตาม BA

1. แมวมี "ผู้ดูแลหลายคน" ระดับสิทธิ์แค่ไหน (ดูสุขภาพได้ไหม / แก้ไขได้ไหม) — `cat_caretakers.role` รอล็อก
2. ประกาศระดมทุนต้อง KYC ผู้รับเงินเพิ่มไหม เกี่ยวกับ `user_private.id_verification`
3. เก็บประวัติตำแหน่ง Tag นานแค่ไหน (policy ลบข้อมูลเก่า — เกี่ยวกับ PDPA/ค่าเก็บ)
4. รายงาน (reports) ต้องมี SLA/ขั้นตอนทีมงานเพิ่มไหม
5. โมเดลรายได้ล็อกแล้วค่อยเติมตารางส่วนแบ่ง (`fee_amount`/settlement) ให้ครบ
