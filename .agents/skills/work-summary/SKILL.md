---
name: work-summary
description: สรุปงานและจับเวลาการทำ task สำหรับ cat.live — รองรับทั้ง Progress/Handoff Summary สำหรับงานที่ยังไม่จบ และ Final Work Summary หลังปิด task โดยใช้เวลาจริงจาก Kanban
---

# cat.live Work Summary

Workflow สำหรับจับเวลาและสรุปงานที่ทำใน task — ครอบคลุมทั้งวงจรตั้งแต่ **เริ่มทำ task**, **ส่งต่องานที่ยังไม่จบข้าม session**, และ **ปิด task ก่อนสร้าง Final Work Summary** โดยใช้ kanban-tukdaeng MCP เป็นแหล่งข้อมูลและบันทึกหลัก **ไม่มีการส่ง log ไปยังระบบภายนอก**

## Checklist บังคับ (อ่านก่อนเสมอ — ทำครบทุกข้อตาม scenario ที่ตรง)

**ลำดับบังคับต่อ scenario:**

- **เริ่มทำ task:** `get_session_context` → `move_task → in_progress` (ผ่าน confirmation flow) → เริ่มงาน
- **ทำเสร็จ (ผู้ใช้อนุญาตปิดแล้ว):** Verify → `move_task → done` → อ่าน Final Task + Activity → อ่าน Actual Start/End + Final `hours_spent` → สร้าง Final Summary → รวม Task Evidence Bundle → `save_session_note` → แสดง Task Block → handoff prompt งานถัดไป (หรือเสนอทางเลือกถ้าไม่มีงานต่อ)
- **Pause ข้าม session (task ยังไม่จบ):** `get_board` → Progress/Handoff Summary (ระบุชัดว่า**ไม่ใช่** Final + เวลายังไม่ใช่ Final Actual Time) → ถามยืนยัน → `save_session_note`
- **สรุป task เดี่ยว:** อ่าน task + `hours_spent` จริงจาก Kanban → Task Block ราย task

**กฎห้ามข้าม:**

1. ⚠️ **Close First** — ห้ามสร้าง/แสดง Final Work Summary ก่อน `move_task → done`
2. ⚠️ **เวลาต้องมาจาก Kanban เท่านั้น** — ห้ามเดา, ห้ามใช้ elapsed/snapshot ตอน `in_progress` เป็น Final Actual Time
3. ⚠️ **ห้าม `log_time` ใน completion workflow** และห้ามแก้ `hours_spent` เอง — ค่าผิดปกติให้แจ้งผู้ใช้ ทำ correction workflow แยกเมื่อผู้ใช้สั่ง
4. ⚠️ **Task Evidence Bundle บังคับ** ทุก task ที่ปิด (checklist ผลตรวจ / test + raw output / ภาพ / ไฟล์+commit) — ระบุ path ใน Final Session Note
5. ⚠️ **Manual Review Checklist** — งานที่เปลี่ยนสิ่งที่เห็นบนจอต้องส่ง checklist ให้ผู้ใช้ตรวจ **ก่อน** ขอปิด
6. ⚠️ ทุก task ที่ปิดต้องมี Final Session Note + Task Block
7. ⚠️ เวลารอผู้ใช้รีวิวหน้าจอ = เวลาทำงานจริง ห้ามตัดออกจาก `hours_spent`

**Self-check ก่อนส่ง output:** เทียบ output กับลำดับบังคับ + กฎข้างบน — ถ้าขาดข้อไหนให้ย้อนทำให้ครบก่อน ห้ามส่ง output ที่ข้ามขั้น

รายละเอียดเชิงลึกของแต่ละขั้นอยู่ในหัวข้อด้านล่าง และใน `references/` (ดู References Map ด้านล่าง)

## When to Trigger

**เริ่มทำ task:**
- User พูดว่า: "เริ่มทำ task ...", "เริ่ม task ...", "ขอเริ่ม ...", "ทำ task ... นี้"
- ผู้ใช้สั่งให้เริ่มงานใหม่ → ย้าย task เข้า `in_progress` เพื่อเริ่มจับเวลา

**ทำ task เสร็จ:**
- User พูดว่า: "เสร็จแล้ว", "ทำเสร็จแล้ว", "ปิด task นี้", "จบ task แล้ว"
- ผู้ใช้ยืนยันผลลัพธ์และอนุญาตให้ปิด task → Verify → ย้ายเข้า `done` → อ่าน Final Actual Time → สร้างและบันทึก Final Work Summary → แสดง Task Block

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

- `references/rules-detail.md` — ขั้นตอนดึงข้อมูลจาก kanban + MCP call signatures + ตารางเวลาตามหมวด + validation + over-budget + Manual Review Checklist + Continuous Evidence Capture + Auto Timer + Checklist self-check ละเอียด → **เปิดตอนดึงข้อมูล / ตรวจเวลา / เก็บหลักฐาน**
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
(ผลลัพธ์เห็นบนจอ:                    ↓
 capture Before ก่อนแก้โค้ด)         สร้าง Final Work Summary ชุดเดียว
                                     ↓
                                     รวมหลักฐานประจำ Task
                                     ↓
                                     save_session_note (Final Summary)
                                     ↓
                                     แสดง Task Block
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
- กรณีที่ 2: **ต้องปิด task ก่อนสร้าง Final Work Summary** และต้องบันทึก Final Session Note + แสดง Task Block จาก Final Summary ชุดเดียวกัน
- กรณีที่ 3 (handoff): **ห้ามย้าย task เป็น `done`** — task ต้องอยู่ใน `in_progress` เพื่อทำต่อใน session ใหม่
- Progress/Handoff Summary ไม่ใช่ Final Work Summary และห้ามใช้เวลาที่ยังวิ่งอยู่เป็น Final Actual Time
- สำหรับ `progress/handoff` และ `report-only` ให้แสดงทั้งสรุปรวมและ Task Block ราย task ในผลลัพธ์เดียวกัน; `final` แสดง Task Block ตาม unified template จาก canonical Final Summary ชุดเดียวกับ Final Session Note

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
- ตรวจว่า task map กับ Mission/Objective ใน approved plan แล้ว — ต้องรู้หมายเลข `mission-<N>-objective-<M>` ก่อนเริ่มจับเวลา เพราะใช้ตั้งชื่อโฟลเดอร์หลักฐาน (`screenshots/`, `deliverables/`); ถ้ายังไม่ map ให้ยืนยัน mapping กับผู้ใช้ก่อน; **ถ้าเป็น task ที่ไม่มี mission จริง (standalone/maintenance/ad-hoc — ยืนยันกับผู้ใช้แล้ว) หลักฐานยังต้องเก็บตามปกติทุกขั้น** โดยใช้โฟลเดอร์ `screenshots/task-<TASK-CODE>/` และ `deliverables/task-<TASK-CODE>/` แทน `mission-<N>-objective-<M>` ทุกจุดใน skill นี้

#### 2. ตรวจสอบ task อื่นที่อยู่ใน `in_progress` (สำคัญ)

ก่อนย้าย task ใหม่เข้า `in_progress` ต้องตรวจสอบก่อนว่ามี task อื่นของผู้ใช้คนเดียวกันที่อยู่ใน `in_progress` อยู่แล้วหรือไม่ (เพราะควรทำ task เดียวในแต่ละเวลา):

- เรียก `get_board` เพื่อดู task ทั้งหมด
- ถ้ามี task อื่นอยู่ใน `in_progress` → แจ้งผู้ใช้และถามว่า:
  - ต้องการ pause task เดิมก่อน (ย้ายออกจาก `in_progress` ชั่วคราว) แล้วเริ่ม task ใหม่?
  - หรือทำ task เดิมให้จบก่อน?
- ถ้าผู้ใช้เลือก pause task เดิม → ย้าย task เดิมออกจาก `in_progress` (เช่น ไป `todo` หรือ `backlog`) ก่อน

#### 3. ย้าย task เข้า `in_progress` (เริ่มจับเวลา)

เรียก `move_task` → `in_progress` (signature + ตัวอย่าง call: `references/rules-detail.md` § MCP Call Signatures)

**หลังย้ายแล้ว:**
- ระบบเริ่มจับเวลาอัตโนมัติ
- แจ้งผู้ใช้ว่า "เริ่มจับเวลา task <ชื่อ task> แล้ว"
- เริ่มทำงานใน task นั้นตามที่ผู้ใช้สั่ง

#### 4. ถ้า task มีผลลัพธ์ที่เห็นบนหน้าจอ — เก็บภาพ Before ก่อนแตะโค้ด (บังคับ)

ใช้กับ task ที่ผลลัพธ์สะท้อนบนหน้าจอ — ครอบคลุมทั้งการแก้ prototype/UI โดยตรง **และ** การแก้ logic, data, mock data, flow หรือ behavior ที่ผู้ใช้เห็นบนจอ (เช่น แก้เงื่อนไขที่เปลี่ยนสิ่งที่แสดง, mock data ที่เปลี่ยน list, logic ที่เปลี่ยนผลการคำนวณ) — ให้ตรวจสภาพหน้าจอเดิมและแคปภาพ Before เก็บไว้ใน `screenshots/mission-<N>-objective-<M>/before/` ทั้ง Desktop (1440px) และ Mobile (390px) **ก่อนเริ่มแก้โค้ด** เพื่อให้มีภาพเทียบกับ After ตอนปิด task/ส่งตรวจ (รายละเอียดตาม Continuous Evidence Capture ใน `references/rules-detail.md`) — ถ้าไม่มีภาพ Before จะไม่มีหลักฐานเทียบการเปลี่ยนแปลง

> เมื่อไม่แน่ใจว่า task อยู่ในเกณฑ์หรือไม่ ให้ถามว่า "ผู้ตรวจจะเห็นความต่างบนหน้าจอไหม" — ถ้าใช่ ต้อง capture Before; งานเอกสาร/อ่านอย่างเดียวที่ไม่เปลี่ยนสิ่งที่เห็นบนจอไม่ต้อง capture แต่ยังต้องเก็บหลักฐานประเภทอื่นตามขั้น 6 ของสถานการณ์ที่ 2

#### กฎสำคัญ
- ⚠️ **ควรมี task ใน `in_progress` เพียง 1 task ต่อผู้ใช้ในแต่ละเวลา** — ถ้ามี task เดิมค้างอยู่ ให้ pause ก่อน
- ห้ามข้ามขั้นตอนการตรวจสอบ task อื่นใน `in_progress`
- หลังย้ายเข้า `in_progress` แล้ว ให้เริ่มทำงานได้เลย ไม่ต้องรอยืนยันเพิ่ม
- ⚠️ task ที่ผลลัพธ์เห็นบนหน้าจอ (แก้ UI โดยตรงหรือ logic/data ที่สะท้อนบนจอ) ต้องแคปภาพ Before (Desktop 1440 + Mobile 390) ก่อนแก้โค้ดตามขั้น 4 — ห้ามข้าม เพราะ After ที่ไม่มี Before เทียบไม่ใช่หลักฐานที่สมบูรณ์

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
→ รูปแบบเคส + ข้อมูลทดสอบ + ขั้นกด + ผลที่คาด + กฎบันทึก checklist/ภาพเป็นหลักฐานทันที: `references/rules-detail.md` § Manual Review Checklist — **ต้องส่ง checklist ให้ผู้ใช้ตรวจก่อนขอปิด ห้ามถามแค่ "รีวิวหน้าจอหน่อย"**

#### 2.2 Continuous Evidence Capture (เก็บหลักฐาน real-time ระหว่างทำ Task — บังคับ 6 รูปแบบงาน)
→ Before/After capture, test output + triage note, checklist card, a11y assertion: `references/rules-detail.md` § Continuous Evidence Capture

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

#### 6. รวมและบันทึกหลักฐานประจำ Task (Task Evidence Bundle — บังคับ)

หลังสร้าง Final Summary แล้ว ต้องรวมหลักฐานของ task นั้นให้ครบและแนบไว้กับ task/note ว่าทำอะไรไปบ้าง เพื่อให้ trace ย้อนกลับได้เสมอ:

- **task ที่ผลลัพธ์เห็นบนหน้าจอ (UI/prototype/logic/data ที่สะท้อนบนจอ):** Manual Review Checklist ที่ผู้ใช้ตรวจจริงพร้อมผลรายเคส (ผ่าน / ไม่ผ่าน / พบอะไร + ผลแก้ไข) บันทึกเป็นไฟล์หลักฐาน + ภาพผลลัพธ์ที่ตรวจ + ภาพ Before/After (1440 + 390) ตาม 2.2
- **task ที่มี test:** สรุป test list ออกมาเป็นไฟล์ — `.spec.js` ที่รัน, เคสที่เทสอะไรบ้าง, ผ่าน/ไม่ผ่าน, จำนวน passed/failed/skipped ตามผลจริง + raw runner output (`test-results.txt`) + ภาพ HTML report dashboard หรือภาพ/screencast พฤติกรรม UI ที่ test ตรวจ (จาก 2.2) + triage note ของเคส skipped/blocked
- **task เอกสาร/อื่น ๆ:** รายการไฟล์ที่แก้จริง + commit hash (ถ้ามี)
- ทุก task ต้อง trace ได้ว่า "ทำอะไรไปบ้าง" — ระบุ path หลักฐานทั้งหมดไว้ใน Final Session Note/Task Block ของ task นั้น และตั้งชื่อไฟล์หลักฐานให้ trace กลับถึง task ได้ (เช่น `<task-code>-checklist.txt`, `<task-code>-test-results.txt`) เพราะหลาย task แชร์โฟลเดอร์ `mission-<N>-objective-<M>/` เดียวกัน
- ถ้าหลักฐานขาด (เช่น ลืมแคป Before) ให้แจ้งผู้ใช้และบันทึก evidence gap ตรง ๆ ห้ามสร้างหลักฐานย้อนหลังแบบเสแสร้ง

#### 7. บันทึก Final Session Note ลง Kanban

เรียก `save_session_note` หลังสร้าง Final Summary แล้ว แม้ task จะเป็น `done` เพื่อเก็บ Persistent Task History — signature + พารามิเตอร์: `references/rules-detail.md` §10

การบันทึก Final Session Note ไม่ใช่การเพิ่มเวลา และห้ามเรียก `log_time`

#### 8. แสดง Task Block

- หลัง `save_session_note` สำเร็จ ให้แสดง **Task Block** ตาม unified template ใน `references/templates.md` § รูปแบบผลลัพธ์ ทุกครั้ง
- Task Block ต้องสร้างจาก canonical Final Summary ชุดเดียวกับที่บันทึกใน note
- ใช้ Human-readable `text` Task Block เดียวตาม template ใน `references/templates.md` § Task Block โดยตรวจ Mission Mapping ก่อน แล้วแสดง Objective/Feature เมื่อมี mapping จริง ตามด้วย Task Code + Task Name, Category, เวลาเริ่ม/เวลาจบ/Final Actual Time, เป้าหมาย/ผลลัพธ์ที่คาดหวัง, ภาพรวม, ไฟล์ที่แก้ไข และรายละเอียดงานที่ทำ
- Actual Start/End จาก Activity Timeline ใช้เป็นบรรทัด เวลาเริ่ม/เวลาจบ ใน Task Block; Decisions, Issues/Fixes, Next Step และ workflow metadata อื่นคงอยู่ใน canonical Final Summary / Final Session Note
- แจ้งผู้ใช้ว่า task ถูกปิดแล้วและแสดงเวลาในรูปแบบ `D.D ชม.` (ทศนิยม 1 ตำแหน่ง)

#### 9. ปิดท้ายด้วย Session Handoff + Prompt งานถัดไป หรือข้อเสนอแนะงานต่อไป (บังคับทุกครั้งหลัง Task Block)

หลังแสดง Task Block แล้ว ต้องทำขั้นนี้เสมอก่อนจบ turn — ห้ามจบแค่ Task Block:

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
- ทุก task ที่ปิดต้องมี Final Session Note และ Task Block
- ⚠️ **Task Evidence Bundle บังคับ:** ทุก task ที่ปิดต้องรวมหลักฐานประจำ task (checklist ผลตรวจ / test list + raw output / ภาพ Before-After / ไฟล์+commit ที่แก้) ทันทีหลังปิด และระบุ path ใน Final Session Note
- ⚠️ **Manual Review Checklist:** task ที่เปลี่ยนสิ่งที่เห็นบนหน้าจอ (UI/prototype/logic/data ที่สะท้อนบนจอ) ต้องส่ง checklist ทดสอบ manual (เคส + ข้อมูลทดสอบ + ขั้นกด + ผลที่คาด) ให้ผู้ใช้ตรวจก่อนขอปิด — รีวิวต้องเกิดก่อน `move_task → done` ตามกฎการยืนยันผลลัพธ์เดิม
- **ถ้า task ที่ปิดเป็น task สุดท้ายของเป้าหมาย (Objective) ใน Mission** — ทุก task ของเป้าหมายนั้นเป็น done แล้ว → แจ้งผู้ใช้ว่าเป้าหมายครบ
- ลำดับบังคับ: Verify → `move_task → done` → อ่าน Final Task + Activity → อ่าน Actual Start/End/Final `hours_spent` → สร้าง Final Summary → รวมหลักฐานประจำ Task → `save_session_note` → แสดง Task Block → session handoff + prompt งานถัดไป หรือข้อเสนอแนะงานต่อไป (ตามขั้น 9)

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
- **หลักฐานที่เก็บไว้แล้วระหว่างทำ** — path ภาพ Before/After, checklist, test output ที่ capture/บันทึกแล้ว เพื่อให้ session ใหม่ไม่ capture ซ้ำและรู้ว่าหลักฐานยังขาดอะไร
- Current State
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
