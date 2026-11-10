# แผนพัฒนาแมว.live ตามมาตรฐาน UNIVERZA (Dev Roadmap)

> **สถานะ:** ร่างวิเคราะห์ — รอพี่มาเต็ม/พี่คิงตรวจ ยังไม่ใช่ baseline
> **อิงจาก:** มาตรฐาน UNIVERZA ที่พี่คิงแจ้งในกลุ่ม (3 ภาพ: 7-Layer App Standard, Future App Concept & Defensible Platform, UOAA Reference Architecture) + `docs/requirement-analysis.md` + `docs/design-spec.md`
> **จัดทำเมื่อ:** 2026-11-10

---

## 1. กติกาจากพี่คิงที่ทุกโปรเจกต์ต้องยึด

1. ภาพ **UOAA Reference Architecture** และ **Future App Concept** = Standard Requirement ตอนเริ่มทำโปรเจกต์ทุกตัว
2. ชั้น 2 **Embedded AI** (AI Chat, Voice, Analysis) → ต้องมีในทุกแอป
3. ชั้น 3 **Agent Interface** (API, MCP, Webhook) → ให้ "แตะไว้เลย" ตั้งแต่ต้น สุดท้ายทุกแอปต้องมีเช่นกัน

## 2. มาตรฐาน 7 ชั้น เทียบกับแมว.live

| # | ชั้นมาตรฐาน | ในแมว.live คืออะไร | สถานะตอนนี้ |
|---|---|---|---|
| 1 | Human Interface | แอปมือถือ React Native (Expo) ตาม `design-spec.md`, เว็บ prototype เป็น design reference | มี prototype แล้ว — ต้องเขียนแอปจริง |
| 2 | Embedded AI *(บังคับทุกแอป)* | Cat AI: แชทถามอาการ, พิมพ์+เสียง, โทรคุยสัตวแพทย์ AI, ตรวจใบหน้าแมว (face-check) | มี UX แล้ว — ต้องทำจริงผ่าน AI Model Router |
| 3 | Agent Interface *(แตะไว้ตั้งแต่ต้น)* | REST API แบบ OpenAPI ตั้งแต่วันแรก + เผื่อ MCP server + Webhook (เบาะแส, แมวหาย, แจ้งเตือน) | ต้องใส่ในการออกแบบ Phase 0 |
| 4 | Business Engine | กฎธุรกิจกลาง: ประกาศ 5 แบบ↔ฟีด, โหมดแมวหาย, ระดมทุน, workflow ปิดประกาศ/อนุมัติ | กระจายอยู่ใน requirement — ต้องรวมเป็นชั้นบริการกลาง |
| 5 | Data Intelligence | PostgreSQL + PostGIS (พิกัด/แผนที่) + pgvector (ความรู้ให้ Cat AI) + search | ต้องวาง schema ตั้งแต่ Phase 0 |
| 6 | Integration Engine | LINE OA/LINE Login, Google Maps, ชำระเงิน QR, SIP/เสียง (AI call), แชร์ต่อแอปอื่น | เฟสหลัง — เผื่อจุดต่อไว้ก่อน |
| 7 | Trust & Governance | ยืนยันตัวตน, PDPA/consent, กฎ "ฟิลด์ลับห้ามออก API สาธารณะ" รายฟิลด์, audit log, ระบบรายงาน | **หัวใจของแอปนี้** — ต้องเริ่มตั้งแต่ schema แรก ห้ามทำย้อนหลัง |

## 3. มาตรฐาน U-01 ถึง U-12 ที่เกี่ยวกับแมว.live

| รหัส | มาตรฐาน | แปลงเป็นงานของเรา |
|---|---|---|
| U-01 | Responsive Human UI | แอป Expo ออกแบบฐาน 390×844 ตาม design-spec |
| U-02 | AI Assistant | Cat AI เป็นผู้ช่วยหลักของแอป |
| U-03 | API First | ทุกบริการเปิดผ่าน OpenAPI spec ก่อนเขียนจอ |
| U-04 | MCP Ready | วางโครง MCP server ตั้งแต่ต้น (tools: ค้นแมวหาย, สถานที่, สร้างประกาศ) |
| U-05 | Unified Identity | OIDC/OAuth ออกแบบให้ย้ายขึ้น UNIVERZA Gateway ได้ + LINE Login |
| U-06 | Permission | สิทธิ์รายฟิลด์: ที่อยู่/บัญชี/จุดสังเกต เห็นเฉพาะเจ้าของ |
| U-07 | Data Ownership | ผู้ใช้ลบ/ส่งออกข้อมูลตัวเองได้ตาม PDPA |
| U-08 | Event Driven | เหตุการณ์กลาง: แมวหาย, เบาะแสใหม่, แจ้งเตือน, ชำระเงิน |
| U-09 | Integration | LINE OA, payment QR, Google Maps, แชร์ต่อ |
| U-10 | Auditability | audit log ทุก action สำคัญ (ประกาศ, เบาะแส, เงิน, สิทธิ์) |
| U-11 | AI Independence | AI Model Router กลาง — เปลี่ยน provider ได้โดยไม่แก้แอป |
| U-12 | Security & Recovery | สำรองข้อมูล, นโยบายกู้คืน, rate limit, ลบ EXIF GPS ก่อนเก็บรูป |

## 4. Tech Stack ที่ตกลงใช้วางแผน

| ส่วน | เทค | หมายเหตุ |
|---|---|---|
| แอปมือถือ | React Native + Expo | ตาม `design-spec.md` |
| Backend | Node.js + NestJS (TypeScript) | ภาษาเดียวกันทั้งสแตก โมดูลแบ่งตามโดเมนตรงชั้น Domain Services ของ UOAA |
| API | REST + OpenAPI spec | ตรง U-03 API First |
| ฐานข้อมูล | PostgreSQL + PostGIS + pgvector | ตัวเดียวครอบ: ข้อมูลหลัก / พิกัดแผนที่ / ความรู้ AI |
| เครื่องมือดู DB | pgAdmin 4 | เครื่องมือบนเครื่อง dev (อยู่ใน `env-setup.md` ข้อลงเครื่องแล้ว ไม่ใช่ส่วนของระบบ) |
| Cache/คิว | Redis | cache, rate limit, คิวงานพื้นหลัง (ลบ EXIF, แจ้งเตือน) |
| ไฟล์สื่อ | S3-compatible storage | รูป/วิดีโอโพสต์และแมว |
| ยืนยันตัวตน | OIDC + LINE Login | ออกแบบให้ย้ายขึ้น UNIVERZA Gateway ได้ (U-05) |
| AI | AI Model Router กลาง + เผื่อ MCP server | ตรงข้อ 2-3 ของกติกาพี่คิง |

## 5. ลำดับเฟสพัฒนา (แนะนำ)

| เฟส | งาน | ทำไมต้องมาก่อน/หลัง |
|---|---|---|
| **0 — รากฐาน** | ตั้ง repo แอป (Expo) + backend (NestJS), OpenAPI skeleton, PostgreSQL+PostGIS+pgvector, auth OIDC เบื้องต้น, ตาราง audit log + events | ทุกอย่างอื่นยืนบนอันนี้; ใส่ Agent Interface (OpenAPI/MCP placeholder) ตรงนี้เลยตามคำสั่ง "แตะไว้เลย" |
| **1 — แมวและฉัน** | users, cats, cat_health + หน้าจอตาม design-spec + กฎฟิลด์ลับ (ที่อยู่/บัญชี) | ข้อมูลแกนกลางที่ทุกฟีเจอร์อ้างถึง (vertical slice แรกจบครบหน้าบ้าน→หลังบ้าน) |
| **2 — ฟีดชุมชน** | posts/comments/likes/follows/saves + อัปโหลดสื่อจริง (ลบ EXIF GPS) + ระบบรายงาน | ฐาน social ที่ประกาศแมวหายจะมาผูกทีหลัง |
| **3 — แมวหายครบวงจร** | ประกาศ 5 แบบ + เบาะแส sightings + ลงฟีด + แชตยืนยันผู้พบ + workflow ปิดประกาศ | หัวใจของแอป — ต้องมีฟีดก่อนจึงทำได้ครบ |
| **4 — ใกล้ฉัน** | places + PostGIS + แผนที่เต็มจอ + รพ.สัตว์ฉุกเฉินข้อมูลจริง | ใช้ PostGIS ที่วางไว้ Phase 0 เต็มกำลัง |
| **5 — Embedded AI** | AI Model Router + Cat AI แชท + knowledge (pgvector) + เสียง; face-check ตามหลัง | บังคับตามมาตรฐาน — ถ้าต้องอยู่ใน release แรกให้ดึงเฟสนี้ขึ้นก่อนเฟส 3-4 (ดูข้อค้างถาม) |
| **6 — รายได้** | เลี้ยงขนม/บริจาค/ระดมทุน + ชำระ QR + บัญชีผู้รับ + ประวัติช่วยเหลือ | ต้องมี user/แมว/ประกาศครบก่อน เงินเอาไว้หลังเพราะเสี่ยงสูงสุด |
| **7 — Agent Interface เปิดใช้จริง** | MCP server เปิด tools ตามสิทธิ์ + Webhook สำหรับ event | "แตะ" ไว้ตั้งแต่ Phase 0 แล้ว — เฟสนี้คือเปิดใช้เต็มรูปแบบ |
| **8 — Tag/IoT + Integration เต็มตัว** | แมว.live Tag (ตำแหน่ง/แบต/เสียง), LINE OA, แจ้งเตือนหลายช่องทาง | ต่อฮาร์ดแวร์และช่องทางภายนอก ทำเมื่อระบบหลักนิ่ง |

## 6. ประเด็นค้างที่ต้องถามพี่คิง/BA

1. แอปยืน self-contained ก่อนแล้วค่อยขึ้น UNIVERZA Gateway ใช่ไหม หรือต้องต่อ Gateway ร่วมตั้งแต่แรก
2. "แตะ" Agent Interface ระดับแรกถึงแค่ไหน — พอแค่ OpenAPI + โครง MCP เปล่า หรือต้องมี tools read-only ใช้ได้จริง
3. Embedded AI ต้องอยู่ใน release แรกไหม — ถ้าใช่ต้องดึงเฟส 5 ขึ้นก่อนเฟส 3–4
4. 35 ข้อใน `docs/questions-for-ba.md` ยังไม่มีคำตอบ — requirement ยังไม่ baseline ลำดับเฟสอาจขยับได้
5. โมเดลรายได้ของแมว.live วางตาม UNIVERZA Revenue Model แบบไหน (subscription / transaction fee / อื่น)
