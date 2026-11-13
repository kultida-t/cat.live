---
name: work-summary
description: สรุปงานและจับเวลาการทำ task สำหรับ cat.live — รองรับทั้ง Progress/Handoff Summary สำหรับงานที่ยังไม่จบ และ Final Work Summary หลังปิด task โดยใช้เวลาจริงจาก Kanban
---

# cat.live Work Summary

Workflow สำหรับจับเวลาและสรุปงานที่ทำใน task — ครอบคลุมทั้งวงจรตั้งแต่ **เริ่มทำ task**, **ส่งต่องานที่ยังไม่จบข้าม session**, และ **ปิด task ก่อนสร้าง Final Work Summary** โดยใช้ kanban-tukdaeng MCP เป็นแหล่งข้อมูลและบันทึกหลัก **ไม่มีการส่ง log ไปยังระบบภายนอก**

## Checklist บังคับ (อ่านก่อนเสมอ — ทำครบทุกข้อตาม scenario ที่ตรง)

**ลำดับบังคับต่อ scenario:**

- **เริ่มทำ task:** `get_session_context` → `move_task → in_progress` (ผ่าน confirmation flow) → เริ่มงาน
- **ทำเสร็จ (ผู้ใช้อนุญาตปิดแล้ว):** Verify → `move_task → done` → อ่าน Final Task + Activity → อ่าน Actual Start/End + Final `hours_spent` → สร้าง Final Summary → `save_session_note` → แจ้งปิด task + เวลา (`D.D ชม.`) → handoff prompt งานถัดไป (หรือเสนอทางเลือกถ้าไม่มีงานต่อ) — **ไม่ต้องแสดง Task Block / copy block สรุปหลังปิด task และไม่ต้องสร้างไฟล์หลักฐานลง `deliverables/` หรือ `screenshots/`**
- **Pause ข้าม session (task ยังไม่จบ):** `get_board` → Progress/Handoff Summary (ระบุชัดว่า**ไม่ใช่** Final + เวลายังไม่ใช่ Final Actual Time) → ถามยืนยัน → `save_session_note`
- **สรุป task เดี่ยว:** อ่าน task + `hours_spent` จริงจาก Kanban → Task Block ราย task

**กฎห้ามข้าม:**

1. ⚠️ **Close First** — ห้ามสร้าง Final Work Summary ก่อน `move_task → done`
2. ⚠️ **เวลาต้องมาจาก Kanban เท่านั้น** — ห้ามเดา, ห้ามใช้ elapsed/snapshot ตอน `in_progress` เป็น Final Actual Time
3. ⚠️ **ห้าม `log_time` ใน completion workflow** และห้ามแก้ `hours_spent` เอง — ค่าผิดปกติให้แจ้งผู้ใช้ ทำ correction workflow แยกเมื่อผู้ใช้สั่ง
4. ⚠️ **บันทึกเฉพาะ Session Note** — ไม่ต้องสร้างไฟล์หลักฐาน (`deliverables/`, `screenshots/`, แคปภาพ Before/After, checklist/test `.txt`, PNG card) เก็บผลรันเทส รายการไฟล์ และ commit hash ไว้ใน `save_session_note` บน Kanban เท่านั้น
5. ⚠️ **Manual Review Checklist** — งานที่เปลี่ยนสิ่งที่เห็นบนจอต้องส่ง checklist ให้ผู้ใช้ตรวจในแชท **ก่อน** ขอปิด
6. ⚠️ ทุก task ที่ปิดต้องมี Final Session Note ใน Kanban (**ไม่ต้องแสดง Task Block / copy block ในแชทหลังปิด task** — แสดงเฉพาะเมื่อผู้ใช้ขอสรุปในสถานการณ์ที่ 3 หรือ 4)
7. ⚠️ เวลารอผู้ใช้รีวิวหน้าจอ = เวลาทำงานจริง ห้ามตัดออกจาก `hours_spent`

**Self-check ก่อนส่ง output:** เทียบ output กับลำดับบังคับ + กฎข้างบน — ถ้าขาดข้อไหนให้ย้อนทำให้ครบก่อน ห้ามส่ง output ที่ข้ามขั้น

รายละเอียดเชิงลึกของแต่ละขั้นอยู่ในหัวข้อด้านล่าง และใน `references/` (ดู References Map ด้านล่าง)

## When to Trigger

**เริ่มทำ task:**
- User พูดว่า: "เริ่มทำ task ...", "เริ่ม task ...", "ขอเริ่ม ...", "ทำ task ... นี้"
- ผู้ใช้สั่งให้เริ่มงานใหม่ → ย้าย task เข้า `in_progress` เพื่อเริ่มจับเวลา

**ทำ task เสร็จ:**
- User พูดว่า: "เสร็จแล้ว", "ทำเสร็จแล้ว", "ปิด task นี้", "จบ task แล้ว"
- ผู้ใช้ยืนยันผลลัพธ์และอนุญาตให้ปิด task → Verify → ย้ายเข้า `done` → อ่าน Final Actual Time → สร้างและบันทึก Final Session Note ลง Kanban → แจ้งปิดงาน + เวลาสั้น ๆ + Session Handoff (**ไม่ต้องแสดง Task Block / copy block สรุป**)

**บันทึก session ก่อนขึ้น session ใหม่ (task ยังไม่จบ):**
- User พูดว่า: "บันทึก session", "ขอบันทึกก่อน", "เซฟ session", "จะทำต่อ session ใหม่"
- ผู้ใช้ต้องการ pause task เพื่อไปทำต่อใน session ใหม่ → บันทึก session note (task ยัง `in_progress`)

**สรุปงานทั่วไป:**
- User asks: "สรุปงาน", "สรุปงานวันนี้", "บันทึกงาน", "สรุป session", "ทำอะไรบ้างวันนี้"
- ถ้าผู้ใช้ขอสรุปรวม **ทั้งวันตอนเลิกงาน** เป็น copy block เดียวสำหรับส่งต่อ dev/ตอบหัวหน้า (รวม session note ของทั้งวัน + file path อ้างอิง) ให้ใช้ skill `daily-summary` แทน — skill นี้เน้นสรุปต่อ task/per-session

**สรุป task เดี่ยว (per-task summary):**
- User asks: "สรุป task นี้", "สรุปงาน task <task id>", "สรุป task <ชื่อ>", "ขอสรุป task ปัจจุบัน"
- ผู้ใช้ต้องการสรุปเฉพาะ task หนึ่งเพื่อก๊อปไปลงระบบอื่น — แสดงเวลาเริ่ม-จบจริง + hours_spent + Task Block ราย task

---

## References (อ่าน on-demand ตอนถึงขั้นตอนที่ต้องใช้ — ห้ามข้าม pointer)

- `references/rules-detail.md` — ขั้นตอนดึงข้อมูลจาก kanban + MCP call signatures + ตารางเวลาตามหมวด + validation + over-budget + Manual Review Checklist + Auto Timer + Checklist self-check ละเอียด → **เปิดตอนดึงข้อมูล / ตรวจเวลา**
- `references/templates.md` — template สรุปรวม + Task Block (unified — Mission Mapping Rule + Case variants) + กฎการเขียนสรุป + Plan vs Actual → **เปิดก่อนสร้าง output ทุกครั้ง ห้ามสร้างจากความจำ**
- `references/examples.md` — ตัวอย่างผลลัพธ์ + ตัวอย่างแปลงภาษาเทคนิค → เปิดเมื่อต้องการเห็นตัวอย่าง

## ภาพรวม Workflow (4 สถานการณ์)

```
สถานการณ์ที่ 1: เริ่มทำ task        สถานการณ์ที่ 2: ทำ task เสร็จ
────────────────────────           ──────────────────────────────
ผู้ใช้: "เริ่มทำ task X"             ผลงานผ่าน Verification และผู้ใช้อนุญาตให้ปิด
↓                                    ↓
ย้าย task → in_progress             move_task → done
(เริ่มจับเวลาอัตโนมัติ)              (หยุด timer + bank เวลาจริงอัตโนมัติ)
↓                                    ↓
เริ่มทำงานใน task นั้น               อ่าน Final Task + Activity Timeline
                                     ↓
                                     สร้าง Final Work Summary ชุดเดียว
                                     ↓
                                     save_session_note (Final Summary)
                                     ↓
                                     แจ้งปิด task + เวลาสั้น ๆ
                                     ↓
                                     Session Handoff + Prompt งานถัดไป
                                     (หรือข้อเสนอแนะงานต่อไปถ้าไม่มีงานรอทำ)

สถานการณ์ที่ 3: บันทึก session ก่อนขึ้น session ใหม่
──────────────────────────────────────────────
ผู้ใช้: "บันทึก session" / "จะทำต่อ session ใหม่"
↓
สร้าง Progress / Handoff Summary (ราย task — เท่าที่ทำได้)
↓
ถามยืนยันผู้ใช้
↓
ผู้ใช้ยืนยัน → save_session_note
↓
⚠️ task ยังอยู่ใน in_progress (ห้ามย้ายเป็น done)
↓
ใน session ใหม่: ดึง Project/Kanban context + task เดิม + Session Note ล่าสุด
แล้วทำ task เดิมต่อจาก Next Step
```

**กฎเหล็ก:**
- ไม่มีการส่ง log ไปยังระบบภายนอก (core-portal หรือ API ใด ๆ)
- งานที่มีการแก้ไฟล์ต้องได้รับการยืนยันผลลัพธ์จากผู้ใช้ก่อนเริ่ม completion workflow ตามกฎ Kanban ของ repository
- กรณีที่ 2: **ต้องปิด task ก่อนสร้าง Final Work Summary** และบันทึก Final Session Note ลง Kanban (**ไม่ต้องแสดง Task Block / copy block สรุปในแชทหลังปิด task**)
- กรณีที่ 3 (handoff): **ห้ามย้าย task เป็น `done`** — task ต้องอยู่ใน `in_progress` เพื่อทำต่อใน session ใหม่
- Progress/Handoff Summary ไม่ใช่ Final Work Summary และห้ามใช้เวลาที่ยังวิ่งอยู่เป็น Final Actual Time
- สำหรับ `progress/handoff` และ `report-only` ให้แสดงทั้งสรุปรวมและ Task Block ราย task ในผลลัพธ์เดียวกัน; ส่วน `final` (ปิด task) ไม่ต้องแสดง Task Block ในแชทแล้ว แสดงเฉพาะเมื่อผู้ใช้สั่งขอสรุปเพิ่มตามสถานการณ์ที่ 4

---

## สถานการณ์ที่ 1: เริ่มทำ task

### เงื่อนไขเริ่ม
- ผู้ใช้สั่งให้เริ่ม task ใหม่ (เช่น "เริ่มทำ task X", "เริ่ม task Y", "ขอเริ่ม ...")
- มี task ใน kanban ที่ต้องการเริ่มทำ

### ขั้นตอน

#### 1. ตรวจสอบ task ที่จะเริ่ม
- ถ้าผู้ใช้ระบุ task_id ชัดเจน → ใช้ task_id นั้น
- ถ้าผู้ใช้ระบุแค่ชื่อ/คำค้น → เรียก `get_board` หรือ `get_session_context` เพื่อหา task ที่ตรง
- ถ้าเป็น task ใหม่ที่ยังไม่มีใน kanban → ถามผู้ใช้ว่าต้องการสร้าง task ใหม่หรือไม่ ถ้าใช่ให้ใช้ `create_task` และ Description ต้องมีบรรทัด `Category: <หมวด> | Planned: <X> ชม. (Category Max <Y> ชม.)` เสมอ โดย `Y` เท่ากับเป้าหมายหมวดตามตารางมาตรฐานใน `references/rules-detail.md` ซึ่งเป็นเกณฑ์ Review โดยตรง ไม่ต้องคูณ 1.5; `Planned` คือเวลาประเมินเฉพาะ task ตามงานจริง — ถ้า scope ที่ประเมินเกินเกณฑ์หมวด ให้พิจารณาแบ่ง task โดยห้ามกดเวลา Planned ให้ต่ำกว่าความจริง; ถ้างานเล็กจนแทบไม่ใช้เวลาเลย ควรพิจารณารวมเข้ากับ task ที่เกี่ยวข้องแทนการสร้าง task แยก
- ถ้า task ที่จะเริ่มไม่มีบรรทัด `Planned` ใน Description → แจ้งผู้ใช้และเสนอเติมผ่าน `update_task` ก่อนเริ่มจับเวลา เพื่อให้ติดตามเวลาเทียบแผนเฉพาะ task ได้; ให้ยึดค่าเป้าหมายหมวดเป็นเกณฑ์ Review โดยตรง และห้ามคำนวณเกณฑ์ใหม่ด้วยการคูณ 1.5
- ไม่ต้องสร้างโฟลเดอร์หลักฐานหรือแคปภาพ Before (`screenshots/` / `deliverables/`) ให้ใช้การเทียบกับต้นแบบ `www.แมว.live` และบันทึกความคืบหน้าใน Session Note แทน

#### 2. ตรวจสอบ task อื่นที่อยู่ใน `in_progress` (สำคัญ)

ก่อนย้าย task ใหม่เข้า `in_progress` ต้องตรวจสอบก่อนว่ามี task อื่นของผู้ใช้คนเดียวกันที่อยู่ใน `in_progress` อยู่แล้วหรือไม่ (เพราะควรทำ task เดียวในแต่ละเวลา):

- เรียก `get_board` เพื่อดู task ทั้งหมด
- ถ้ามี task อื่นอยู่ใน `in_progress` → แจ้งผู้ใช้และถามว่า:
  - ต้องการ pause task เดิมก่อน (ย้ายออกจาก `in_progress` ชั่วคราว) แล้วเริ่ม task ใหม่?
  - หรือทำ task เดิมให้จบก่อน?
- ถ้าผู้ใช้เลือก pause task เดิม → ย้าย task เดิมออกจาก `in_progress` (เช่น ไป `todo` หรือ `backlog`) ก่อน

#### 3. ย้าย task เข้า `in_progress` (เริ่มจับเวลา)

เรียก `move_task` → `in_progress` (signature + ตัวอย่าง call: `references/rules-detail.md` § MCP Call Signatures)

- **หลังย้ายแล้ว:**
- ระบบเริ่มจับเวลาอัตโนมัติ
- แจ้งผู้ใช้ว่า "เริ่มจับเวลา task <ชื่อ task> แล้ว"
- **เช็กหน้าเว็บต้นแบบจริงก่อนลงมือทำ (สำหรับงานหน้าจอ/UI):** ตรวจสอบการแสดงผล (สี, ฟอนต์, ขนาด, ข้อความ, สถานะว่าง/โหลด/ผิดพลาด) รวมถึงการทำงานและ flow การนำทางของหน้าจริงบน `www.แมว.live` ให้ครบถ้วนก่อนเริ่มเขียนโค้ด เพื่อให้งานตรงตามเว็บจริงตั้งแต่รอบแรก ไม่ต้องตามแก้หลายรอบในภายหลัง
- เริ่มทำงานใน task นั้นตามที่ผู้ใช้สั่ง

#### กฎสำคัญ
- ⚠️ **ควรมี task ใน `in_progress` เพียง 1 task ต่อผู้ใช้ในแต่ละเวลา** — ถ้ามี task เดิมค้างอยู่ ให้ pause ก่อน
- ห้ามข้ามขั้นตอนการตรวจสอบ task อื่นใน `in_progress`
- หลังย้ายเข้า `in_progress` แล้ว ให้เริ่มทำงานได้เลย ไม่ต้องรอยืนยันเพิ่ม
- ไม่ต้องแคปภาพ Before ลงไฟล์ก่อนเริ่มแก้โค้ด (เทียบต้นแบบจริง `www.แมว.live` และส่ง Manual Review Checklist ให้ผู้ใช้ตรวจแทน)

---

## สถานการณ์ที่ 2: ทำ task เสร็จ

### เงื่อนไขเริ่ม
- งานครบ Acceptance Criteria และผ่าน Verification ตามขอบเขตของ task
- ผู้ใช้บอกว่า task เสร็จแล้วหรืออนุญาตให้ปิด (เช่น "เสร็จแล้ว", "ทำเสร็จแล้ว", "ปิด task นี้", "จบ task แล้ว")
- สำหรับ task ที่มีการแก้ไฟล์ ต้องมีคำยืนยันว่าผลลัพธ์ได้รับการยอมรับก่อนปิด ตามกฎ Kanban ของ repository
- มี task อยู่ใน `in_progress` ที่ต้องการปิด

### ขั้นตอน

#### 1. ตรวจสอบ task ที่อยู่ใน `in_progress`
- เรียก `get_board` เพื่อดู task ที่อยู่ใน `in_progress`
- ถ้ามีหลาย task ใน `in_progress` → ถามผู้ใช้ว่าจะปิด task ไหน
- ถ้าไม่มี task ใน `in_progress` → แจ้งผู้ใช้ว่าไม่มี task ที่กำลังทำอยู่

#### 2. Verify ก่อนปิด
- ตรวจ Acceptance Criteria, test/QA result และผลกระทบตาม task
- ถ้ายังมีงานในขอบเขต task ที่ไม่เสร็จ ให้กลับไปใช้สถานการณ์ที่ 3 และคง `in_progress`
- Open item ที่จะส่งต่อได้ต้องเป็นงานใหม่ที่ไม่ทำให้ task ปัจจุบันไม่ผ่าน Acceptance Criteria

#### 2.1 Manual Review Checklist (บังคับเมื่อ task เปลี่ยนสิ่งที่เห็นบนหน้าจอ)
→ **ต้อง build และรันแอปเวอร์ชันล่าสุดขึ้น Simulator/Emulator (iOS/Android) ให้ผู้ใช้ทดสอบได้จริงก่อนส่ง Checklist ทุกรอบ** (ถ้ามีการแก้โค้ดเพิ่ม ต้อง build อัปเดตใหม่ทุกรอบ)
→ รูปแบบเคส + ข้อมูลทดสอบ + ขั้นกด + ผลที่คาด: `references/rules-detail.md` § Manual Review Checklist — **ต้องส่ง checklist ให้ผู้ใช้ตรวจในแชทก่อนขอปิด ห้ามถามแค่ "รีวิวหน้าจอหน่อย"** (ไม่ต้องบันทึกเป็นไฟล์หลักฐานแยก)

#### 3. ย้าย task เข้า `done` ก่อนสร้าง Final Work Summary

เรียก `move_task` → `done` (signature: `references/rules-detail.md` § MCP Call Signatures)

**หลังย้ายแล้ว:**
- ระบบหยุดจับเวลาและบันทึก `hours_spent` อัตโนมัติ (system minimum 0.1h) — ใช้ค่านี้เป็นเวลาจริงเลย ไม่มี floor ขั้นต่ำ ห้ามปรับขึ้นเพราะค่า "ดูน้อย"
- **หลักเวลาจริง (ใช้ทั้งตอนตั้ง Planned และตอนลงเวลา):** เวลาต้องสะท้อนคนทำจริง — งานที่ AI ทำ (เขียนสคริปต์/สแกนไฟล์/เขียนเอกสาร) ให้ประเมินและลงตามเวลา AI ซึ่งมักเร็วกว่าที่คิด; งานที่ต้องใช้คนทำเองแบบ manual (เช่น ผู้ใช้เปิดจอตรวจเองทีละหน้า, review, ตอบ decision rounds) ให้นับเวลาคนที่ใช้จริง — ถ้า task ผสมทั้งสองอย่าง ให้รวมเวลาทั้งคู่เข้าด้วยกัน
- ห้ามเรียก `log_time` เพราะจะทำให้เวลาถูกบันทึกซ้ำ

#### 4. อ่าน Final Task + Activity Timeline หลังปิด
- เรียก `get_task` หลัง `move_task → done` สำเร็จ เพื่ออ่านสถานะสุดท้าย, Activity Timeline, Actual Start, Actual End และ Final `hours_spent`
- เรียก `get_time_summary` เพิ่มได้เมื่อต้องสรุปรวม แต่ Final Actual Time ราย task ต้องยึด `hours_spent` หลังปิดจาก Kanban
- ถ้าข้อมูล Final Task หรือเวลาจริงยังอ่านไม่ได้ ให้แจ้งปัญหาและลองดึงใหม่ ห้ามใช้ elapsed/snapshot ขณะ `in_progress` หรือค่าประมาณแทน Final Actual Time

#### 5. สร้าง Final Work Summary ชุดเดียว

สร้าง canonical Final Summary จากข้อมูลหลังปิด โดยอย่างน้อยต้องมี:
- Final Result และสถานะ `done`
- Work Completed และไฟล์ที่แก้ (ถ้ามี)
- Decisions / ข้อสรุปสำคัญ
- Verification / Test Result
- Actual Start / Actual End จาก Activity Timeline
- Final Actual Time จาก Final `hours_spent`
- Issues / Fixes
- Scope Changes (ถ้ามี)
- Open Items และ Next Step

Final Summary ชุดนี้ต้องเป็นแหล่งเดียวสำหรับทั้ง Final Session Note และ Task Block ห้ามร่างคนละชุดจนข้อมูลไม่ตรงกัน

#### 6. บันทึก Final Session Note ลง Kanban

เรียก `save_session_note` หลังสร้าง Final Summary แล้ว แม้ task จะเป็น `done` เพื่อเก็บ Persistent Task History (สรุปผลเทส รายการไฟล์ และ commit hash ไว้ใน Session Note โดยไม่ต้องสร้างไฟล์หลักฐานลง `deliverables/` หรือ `screenshots/`) — signature + พารามิเตอร์: `references/rules-detail.md` §10

การบันทึก Final Session Note ไม่ใช่การเพิ่มเวลา และห้ามเรียก `log_time`

#### 7. แจ้งปิด task และเวลาสั้น ๆ (ไม่ต้องแสดง copy block สรุป)

- หลัง `save_session_note` สำเร็จ ให้แจ้งผู้ใช้สั้น ๆ ว่า task ถูกปิดแล้ว พร้อมแสดงเวลาในรูปแบบ `D.D ชม.` (ทศนิยม 1 ตำแหน่ง) และหมายเหตุเรื่องเวลา (ถ้ามี เช่น มี dead time หรือไม่ได้เปิด timer ระหว่างทำ)
- **ไม่ต้องแสดง Task Block / copy block สรุปในแชทหลังปิด task** (หากผู้ใช้ต้องการก๊อปไปลงระบบอื่นภายหลัง ค่อยสั่ง `"สรุป task นี้"` ตามสถานการณ์ที่ 4)

#### 8. ปิดท้ายด้วย Session Handoff + Prompt งานถัดไป หรือข้อเสนอแนะงานต่อไป (บังคับทุกครั้งหลังปิด task)

หลังแจ้งปิด task แล้ว ต้องทำขั้นนี้เสมอก่อนจบ turn:

**กรณีมีงานรอทำต่อ** (มี task ถัดไปใน approved execution order หรืองานที่เหลือใน mission/plan ที่ผู้ใช้อนุมัติแล้ว):

1. บันทึก session note ลง kanban (`save_session_note`) เก็บ state ปัจจุบันให้ session ใหม่ทำต่อได้ — เขียนบน task ที่เพิ่งปิดหรือ planning task ของ mission ตามความเหมาะสม โดยมี: สถานะรวม mission/แผน (ทำถึงไหน), สิ่งที่ทำใน session นี้, state ปัจจุบัน (branch/commit/tests), decisions/gotchas ที่ session ใหม่ต้องรู้, และ Next Step ชัดเจน
2. สร้าง **prompt สำหรับเริ่มงานถัดไปใน session ใหม่** เป็น copy block ให้ผู้ใช้ก๊อปไปวาง — โครงเดียวกับ prompt ที่ผู้ใช้เคยสั่ง task นี้: ชื่อ task + mission/requirement context + ข้อมูลที่ task ต้องรู้ (task ก่อนหน้าสำเร็จอะไร, contract/spec ที่ต้องยึด, scope, fixture ที่เกี่ยวข้อง, constraints/gotchas, out-of-scope) + ขั้นตอน workflow (ดึง context → สร้าง/เริ่ม task → เสนอ approach → implement/test → รอรีวิว)

**กรณีไม่มีงานรอทำต่อ** (mission/plan ครบแล้ว หรือไม่มี task ถัดไปในลำดับ):

- ไม่ต้องสร้าง handoff prompt; ให้บันทึก session note สถานะปิดงานตามความจำเป็น แล้วเสนอแนวทางงานต่อไปให้ผู้ใช้ตัดสินใจ เช่น: สร้าง mission ใหม่สำหรับ requirement/scope ที่ยังไม่ได้ทำ, งาน outstanding ใน requirement, backlog/debt ที่ตั้งไว้, หรือขั้นตอนต่อไปของโปรเจกต์ (เช่น Mission Closure, เตรียมหลักฐานส่งตรวจ) — เสนอเป็นทางเลือกให้ผู้ใช้เลือก ห้ามสร้าง mission/task เองโดยไม่ได้รับคำสั่ง

#### กฎสำคัญ
- ⚠️ **Close First:** ห้ามสร้างหรือแสดง Final Work Summary ก่อน `move_task → done`
- ⚠️ Final Actual Time ต้องมาจาก Kanban หลังปิด task เท่านั้น ห้ามใช้ snapshot/elapsed time ตอน `in_progress`
- ⚠️ ห้ามเรียก `log_time` ใน completion workflow ไม่ว่าก่อนหรือหลังปิด task
- ⚠️ ห้ามปรับ `hours_spent` เองระหว่าง completion workflow; ถ้าค่าผิดปกติให้รายงานผู้ใช้และแยกเป็น correction workflow ที่ผู้ใช้สั่งชัดเจน
- ⚠️ **เวลารอผู้ใช้รีวิวหน้าจอ/prototype = เวลาทำงานจริง** — task ที่เปลี่ยนสิ่งที่เห็นบนหน้าจอแล้วรอผู้ใช้ตรวจตาม Manual Review Checklist ต้องนับเวลาต่อเนื่อง เพราะ review gate คือส่วนหนึ่งของงาน ห้ามตัดเวลารอรีวิวออกจาก `hours_spent`
- ⚠️ **ตัดเวลาหลุดได้เฉพาะงานประเภท run** (เช่น run tests/regression/long-running command) ที่ผลลัพธ์เสร็จสมบูรณ์แล้วแต่ timer ยังเดินต่อเพราะผู้ใช้ไม่ได้อยู่หน้าจอ — ถ้าพบ banked time มีช่วงหลุดแบบนี้หลังปิด task ให้แจ้งผู้ใช้พร้อมตัวเลข banked vs เวลางานจริง และ correct `hours_spent` ด้วย `update_task` (SET) เมื่อผู้ใช้ยืนยันเวลาจริงแล้วเท่านั้น โดยทำเป็น correction workflow แยกหลังปิด task
- ทุก task ที่ปิดต้องมี Final Session Note ใน Kanban (ไม่ต้องแสดง Task Block / copy block ในแชทหลังปิด task และไม่ต้องสร้างไฟล์หลักฐานลง `deliverables/` หรือ `screenshots/`)
- ⚠️ **Manual Review Checklist:** task ที่เปลี่ยนสิ่งที่เห็นบนหน้าจอ (UI/prototype/logic/data ที่สะท้อนบนจอ) ต้องส่ง checklist ทดสอบ manual (เคส + ข้อมูลทดสอบ + ขั้นกด + ผลที่คาด) ให้ผู้ใช้ตรวจในแชทก่อนขอปิด — รีวิวต้องเกิดก่อน `move_task → done` ตามกฎการยืนยันผลลัพธ์เดิม
- **ถ้า task ที่ปิดเป็น task สุดท้ายของเป้าหมาย (Objective) ใน Mission** — ทุก task ของเป้าหมายนั้นเป็น done แล้ว → แจ้งผู้ใช้ว่าเป้าหมายครบ
- ลำดับบังคับ: Verify → `move_task → done` → อ่าน Final Task + Activity → อ่าน Actual Start/End/Final `hours_spent` → สร้าง Final Summary → `save_session_note` → แจ้งปิด task + เวลาสั้น ๆ → session handoff + prompt งานถัดไป หรือข้อเสนอแนะงานต่อไป (ตามขั้น 8)

---

## สถานการณ์ที่ 3: บันทึก session ก่อนขึ้น session ใหม่ (task ยังไม่จบ)

### เงื่อนไขเริ่ม
- ผู้ใช้ต้องการ pause task เพื่อไปทำต่อใน session ใหม่ (เช่น "บันทึก session", "ขอบันทึกก่อน", "เซฟ session", "จะทำต่อ session ใหม่")
- มี task อยู่ใน `in_progress` ที่ยังไม่เสร็จ

### ขั้นตอน

#### 1. ตรวจสอบ task ที่อยู่ใน `in_progress`
- เรียก `get_board` เพื่อดู task ที่อยู่ใน `in_progress`
- ถ้าไม่มี task ใน `in_progress` → แจ้งผู้ใช้ว่าไม่มี task ที่กำลังทำอยู่

#### 2. สร้าง Progress / Handoff Summary (เท่าที่ทำได้)

ดึงข้อมูลและสรุปตามขั้นตอนใน `references/rules-detail.md` § ขั้นตอนสรุปงาน:
- เรียก `get_time_summary` (status: `all` เพื่อรวม task in_progress) หรือ `get_board` เพื่อดู `hours_spent` ของ task ที่ยังทำอยู่
- รวม session context ของงานที่ทำใน task นี้ (เท่าที่ทำไปถึงตอนนี้)
- แสดง Progress/Handoff Summary โดยระบุชัดว่าเป็นข้อมูลระหว่างทำ ไม่ใช่ Final Work Summary และเวลายังไม่ใช่ Final Actual Time

#### 3. ถามยืนยันผู้ใช้

หลังแสดงสรุปต้องถามผู้ใช้ทุกครั้งว่า:
- พอใจกับสรุปหรือไม่
- ต้องการแก้ไข/เพิ่ม/ลดอะไรเพิ่มเติมหรือไม่
- ถ้าพอใจแล้ว ให้สั่ง "บันทึก" เพื่อบันทึก session note

#### 4. บันทึก session note ลง kanban

หลังผู้ใช้ยืนยันแล้ว เรียก `save_session_note` ด้วย Progress/Handoff Summary (signature + พารามิเตอร์: `references/rules-detail.md` §10)

**เนื้อหาที่ควรบันทึกใน `note` (กรณี pause):**
- สิ่งที่ทำเสร็จแล้วใน task นี้
- Current State (branch / commit / ผลเทสล่าสุด)
- สิ่งที่ตัดสินใจ (decisions) และเหตุผล (WHY)
- สิ่งที่ตรวจสอบแล้ว
- **Open Items — สำคัญ** เพื่อให้ session ใหม่รู้ว่าต้องทำอะไรต่อ
- Blockers (ถ้ามี)
- สิ่งที่ยังไม่ได้ทำ
- **Next Step — สำคัญ** เพื่อให้ session ใหม่รู้ว่าจะเริ่มจากตรงไหน
- ควรระบุชัดว่า "task ยังไม่จบ จะทำต่อใน session ใหม่"

#### 5. ⚠️ ห้ามย้าย task เป็น `done`

**สำคัญมาก:** ในสถานการณ์นี้ **ห้ามย้าย task เป็น `done`** — task ต้องอยู่ใน `in_progress` เพื่อ:
- ให้ระบบยังจับเวลาอยู่ (ถ้าผู้ใช้ทำต่อใน session ใหม่ทันที)
- ให้ `get_session_context` ใน session ใหม่เห็นว่า task นี้ยังทำอยู่
- ให้ผู้ใช้สามารถสั่ง "ทำต่อ" ใน session ใหม่ได้เลยโดยไม่ต้องเริ่มจับเวลาใหม่

#### 6. แจ้งผู้ใช้วิธีทำต่อใน session ใหม่

หลังบันทึก session note แล้ว แจ้งผู้ใช้ว่า:
- "บันทึก session note แล้ว task <ชื่อ task> ยังอยู่ใน in_progress"
- "ใน session ใหม่ สั่ง 'ทำต่อ' หรือ 'resume' ระบบจะดึง Project/Kanban context, task ปัจจุบัน และ Session Note ล่าสุด แล้วทำ task เดิมต่อจาก Next Step ได้เลย"

#### 7. Resume ใน session ใหม่

เมื่อเริ่ม session ใหม่เพื่อทำ task เดิมต่อ:
1. เรียก `get_session_context` เพื่อดึง Project/Kanban context
2. ดึง task ปัจจุบันด้วย `get_task` และยืนยันว่าเป็น task เดิม ไม่สร้าง task ใหม่เพียงเพราะเปลี่ยน session
3. อ่าน Session Note ล่าสุดของ task
4. ตรวจ Current State, Decisions, สิ่งที่ตรวจสอบแล้ว, Open Items, Blockers, สิ่งที่ยังไม่ได้ทำ และ Next Step
5. ทำ task เดิมต่อจากจุดที่ค้าง โดยคงสถานะ `in_progress`

#### กฎสำคัญ
- ⚠️ **ห้ามย้าย task เป็น `done`** — task ต้องอยู่ใน `in_progress`
- ⚠️ **ต้องถามผู้ใช้ยืนยันก่อนบันทึก session note** เสมอ
- session note ต้องระบุชัดว่า task ยังไม่จบ + ขั้นตอนถัดไป เพื่อให้ session ใหม่ทำต่อได้
- เวลาที่แสดงใน Progress/Handoff Summary เป็น running/snapshot time เท่านั้น ไม่ใช่ Final Actual Time
- ลำดับ: Progress/Handoff Summary → ถามยืนยัน → `save_session_note` → คง `in_progress` → End Session

---

## สถานการณ์ที่ 4: สรุป task เดี่ยว (per-task summary)

### เงื่อนไขเริ่ม
- ผู้ใช้สั่งสรุปเฉพาะ task หนึ่ง (เช่น "สรุป task นี้", "สรุปงาน task <task id>", "สรุป task <ชื่อ>", "ขอสรุป task ปัจจุบัน")
- ผู้ใช้ต้องการสรุปเฉพาะ task เพื่อก๊อปไปลงระบบอื่น — ไม่ได้ปิด task หรือบันทึก session note

### ขั้นตอน

#### 1. ระบุ task ที่ต้องการสรุป
- ถ้าผู้ใช้ระบุ task_id ชัดเจน → ใช้ task_id นั้น
- ถ้าผู้ใช้ระบุแค่ชื่อ/คำค้น → เรียก `get_board` หรือ `get_session_context` เพื่อหา task ที่ตรง
- ถ้าผู้ใช้บอก "task ปัจจุบัน" → ดู task ที่อยู่ใน `in_progress` ของผู้ใช้

#### 2. ดึงข้อมูล task + Activity timeline
- เรียก `get_task` เพื่อดึง title/description/status/hours_spent และ Activity timeline
- ดึงเวลาเริ่ม (start_time) จาก time event แรกหลัง task ถูกย้ายเข้า `in_progress`
- ดึงเวลาจบ (end_time):
  - task `done` → time event สุดท้าย
  - task `in_progress` → ใช้เวลาปัจจุบัน (now) และคำนวณ "เวลาที่ผ่านไป"

#### 2.1 Hard stop ก่อนตอบ per-task summary
ก่อนตอบสรุป task เดี่ยว ต้องตรวจว่ามีข้อมูลครบ 3 บรรทัดนี้แล้ว:
- `เวลาเริ่ม` จาก Activity timeline ของ `get_task`
- `เวลาจบ` หรือ `ปัจจุบัน` จาก Activity timeline ของ `get_task` หรือเวลาปัจจุบันเมื่อ task ยัง `in_progress`
- `เวลาทำงานจริง` หรือ `เวลาที่ผ่านไป` โดยใช้ `hours_spent` จาก kanban สำหรับ task ที่ `done`

ถ้ายังไม่ได้เรียก `get_task` หรือยังไม่มี 3 บรรทัดนี้ **ห้ามตอบเป็นสรุปสุดท้าย** ให้ดึงข้อมูลเพิ่มก่อนเสมอ ห้ามใช้ `get_time_summary` อย่างเดียวเพื่อสรุป task เดี่ยว เพราะ tool นั้นไม่มี Activity timeline เพียงพอสำหรับเวลาเริ่ม-จบจริง

#### 3. แสดง Task Block ราย task
- แสดง **Task Block** ตาม unified template ใน `references/templates.md` § รูปแบบผลลัพธ์ — block เดียวใช้ทั้งอ่านและก๊อปไปลงระบบอื่น

#### 4. ถามยืนยันผู้ใช้
- ถามผู้ใช้ว่าพอใจกับสรุปหรือไม่ ต้องการแก้ไขอะไรเพิ่มเติมหรือไม่
- ถ้าผู้ใช้พอใจ → จบสถานการณ์ (ไม่บันทึก session note ไม่ปิด task)

#### กฎสำคัญ
- ⚠️ **ห้ามบวก/ลด/ปรับชั่วโมงเอง** — ใช้ค่า `hours_spent` จากระบบเป็นค่าจริง
- ⚠️ **ห้ามส่ง log ไปยังระบบภายนอกใด ๆ**
- สถานการณ์นี้ **ไม่บันทึก session note และไม่ปิด task** — แค่แสดงสรุป + copy block
- สถานการณ์นี้ **ไม่บันทึก session note และไม่ปิด task** — แค่แสดงสรุป + Task Block

---

**Reminder:** ก่อนสร้าง output/copy block ทุกครั้ง ให้เปิด `references/templates.md` ตาม References Map ด้านบน — ห้ามสร้าง template จากความจำ
