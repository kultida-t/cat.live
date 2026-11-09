---
name: mission-planning
description: cat.live daily work workflow — วางแผน Mission รายวัน, สร้าง Mission Plan Summary และ Session Handoff หลังอนุมัติแผน, และสรุปผลหลังทำตามแผน พร้อมส่วนที่ก๊อปไปลงระบบอื่นได้เลย. Use เมื่อเริ่มวางแผนงานรายวัน, ปิด planning session หลังผู้ใช้อนุมัติ Mission Plan หรือสรุปผลหลังทำตามแผน
---

# cat.live Mission Planning Workflow

> ## ⚠️ Machine Guard — ตรวจสอบเครื่องก่อนทำงาน skill นี้ (จำเป็น)
>
> Skill นี้ผูกกับเครื่องเฉพาะ เพราะอ้างอิง path/workspace ของ cat.live บนเครื่องนี้เท่านั้น
>
> **เครื่องที่อนุญาต (ผ่านถ้าตรงชุดใดชุดหนึ่ง):**
>
> **เครื่อง A (เครื่องหลัก Admin):**
> - Platform: Windows
> - User: `Admin` หรือ account sandbox ที่ลงท้ายด้วย `\\codexsandboxoffline`
> - Home path: `C:\Users\Admin`
> - Workspace path ที่ต้องมีอยู่จริง: `C:\Users\Admin\Desktop\cat.live\` (หรือ `C:\Users\Admin\Desktop\TukDaeng\`)
>
> **เครื่อง B (เครื่อง mailt):**
> - Platform: Windows
> - User: `mailt`
> - Home path: `C:\Users\mailt`
> - Workspace path ที่ต้องมีอยู่จริง: `D:\cat.live\` (หรือ `D:\TukDaeng\`)
>
> **วิธีตรวจสอบก่อนเริ่ม skill:**
> 1. ตรวจ user ปัจจุบัน (เช่น `whoami`) — ต้องเป็น `Admin` / account sandbox ที่ลงท้ายด้วย `\\codexsandboxoffline` (เครื่อง A) หรือ `mailt` (เครื่อง B)
> 2. ตรวจว่า workspace path ของชุดนั้นมีอยู่จริง (`C:\Users\Admin\Desktop\cat.live\` สำหรับเครื่อง A, `D:\cat.live\` สำหรับเครื่อง B)
>
> **ถ้าไม่ใช่เครื่องที่อนุญาต:** หยุดทำงาน skill นี้ทันที ไม่เรียก MCP ใด ๆ แจ้งผู้ใช้ว่า skill นี้ใช้ได้เฉพาะเครื่องของ Admin หรือ mailt เท่านั้น

Workflow สำหรับ **วางแผนการทำงานรายวัน** และ **สรุปผลหลังทำตามแผน** ของโปรเจกต์ cat.live — แบ่งการทำงานเป็น 2 ส่วนที่แยกจากกันชัดเจน

> **หมายเหตุสำคัญ:** skill นี้ **ไม่ส่ง log เข้า Core Portal อัตโนมัติ** — ทุกสรุปที่ออกมาจะอยู่ในรูปแบบ **code block (copy block)** เพื่อให้ผู้ใช้ก๊อปข้อความไปวางในระบบอื่นได้เอง

## Checklist บังคับ (อ่านก่อนเสมอ — ทำครบทุกข้อตาม scenario ที่ตรง)

**0. Machine Guard ก่อนทุกอย่าง** — ตรวจเครื่องตามบล็อกด้านบน; เครื่องผิด = หยุดทันที

**ส่วนที่ 1 — วางแผน Mission รายวัน (ลำดับบังคับ):**

1. เรียก context จาก kanban MCP (`get_session_context`/`get_board`/`get_time_summary`/`get_mission`) → ดึง detail task DONE ที่เกี่ยวข้อง
2. (ถ้ามี standing workflow) สร้าง Planning Task + `move_task → in_progress` **ก่อน** เริ่มอ่าน context เชิงงาน
3. ออกแบบ Mission → Scope/AC → แยกเป้าหมาย + ประเมินเวลา → Dependency → Risk → แจกลง Feature → แสดง Detailed Mission Plan copy block ให้ผู้ใช้ review
4. **รอ approval ชัดเจนเท่านั้น** — ห้ามอนุมานจากการอ่าน/ขอแก้แผน
5. หลัง approve ทำตามลำดับนี้เท่านั้น: Mission Plan Summary Copy Block → `create_mission` + execution tasks (**ทุก task = `todo` เท่านั้น**) → สร้าง/อัปเดต Session Handoff → แสดงทั้งสอง artifact แยกกัน → `save_session_note` เก็บ summary verbatim ลง Planning Task/task แรก → จบ planning session
6. **ห้ามต่อเป็น execution ใน session เดียวกัน** — task แรกเริ่มใน session ใหม่เท่านั้น (เว้นแต่ผู้ใช้สั่งชัดเจน)

**ส่วนที่ 2 — สรุปผลหลังทำตามแผน:** ดูหัวข้อส่วนที่ 2 ด้านล่าง — ใช้ข้อมูลจริง (status/ชั่วโมง/activity/evidence) เท่านั้น

**กฎห้ามข้าม:**

1. ⚠️ Mission Plan = แผนล่วงหน้าเท่านั้น — ห้ามใส่ actuals (สถานะเสร็จ, ชั่วโมงจริง, evidence, bug, QA result)
2. ⚠️ Mission Plan Summary ≠ Session Handoff — 2 artifacts แยกกัน ห้ามใช้แทนกัน; Summary ห้ามมี Kanban UUID
3. ⚠️ ชื่อ Objective/Feature = label สั้นเท่านั้น — ห้ามยัด scope/behavior/AC ลงในชื่อ
4. ⚠️ ตอบโครงสร้าง Mission จาก record (`get_mission`/`get_task`) เท่านั้น ห้ามตอบจากความจำ
5. ⚠️ ห้ามลบ Objective/Feature หลังเริ่ม Mission — ใช้ Scope Change/ยกเลิกพร้อมเหตุผล
6. ⚠️ ห้ามส่ง log เข้าระบบภายนอกใด ๆ อัตโนมัติ — copy block เท่านั้น

**Self-check ก่อนส่ง output:** เทียบ output กับลำดับ + กฎข้างบน — ถ้าขาดข้อไหนให้ย้อนทำให้ครบก่อน

### การแยก Mission Plan, Approval Artifacts และ Work Summary

- **Mission Plan** คือแผนตั้งต้นก่อนเริ่มงาน ต้องเขียนเป็นสิ่งที่วางแผนจะส่งมอบ ไม่ใช่ผลลัพธ์ย้อนหลัง
- Mission Plan ต้องมี Objective, Feature ย่อย, Task ที่เกี่ยวข้อง, เวลาแผน, Dependency, Acceptance Criteria และ Risk
- Mission Plan ห้ามใส่สถานะ `เสร็จ`, ชั่วโมงที่ใช้จริง, Activity timeline, Evidence, bug ที่พบจริง, ผล QA ที่เกิดขึ้นแล้ว หรือ Scope Change ที่เกิดขึ้นภายหลัง
- **Mission Plan Summary Copy Block** คือสรุป Approved Mission Baseline สำหรับ Work Log และคนทั่วไปอ่านย้อนหลัง ต้องกระชับ แสดง Objective → Feature → Task ชัดเจน และห้ามมี Kanban UUID/internal ID
- **Session Handoff** คือ execution context สำหรับ Agent/session ถัดไป ต้องคง technical context, identifiers, dependency, current state และ next-step instructions ที่จำเป็น; สามารถมี Kanban UUID/internal ID ได้
- Mission Plan Summary กับ Session Handoff เป็นคนละ artifact ห้ามใช้แทนกัน ห้ามลดรายละเอียด Handoff เพราะมี Summary และห้ามบังคับให้ผู้ใช้ใช้ Summary เป็น execution context
- **Work Summary** คือสรุปหลังทำงาน ใช้สำหรับสถานะจริง, ชั่วโมงจริง, Activity timeline, ไฟล์ที่แก้, Evidence, bug/การแก้ไขจริง, Scope Change และ open items
- การวางแผนและการสร้าง task อาจมี planning record แยกได้ แต่ไม่ต้องนับ planning record เป็น Objective ของ Mission ที่ส่งมอบ เว้นแต่ผู้ใช้ระบุชัดว่าต้องการนับงานวางแผนเป็น deliverable
- หากผู้ใช้ขอ Mission Plan ใหม่ ให้สร้างจาก requirement และ scope ณ ก่อนเริ่มงาน โดยไม่ใช้ความรู้จากผลลัพธ์ภายหลังมาปรับถ้อยคำให้เหมือนงานเสร็จแล้ว

## References (อ่าน on-demand ตอนถึงขั้นตอนที่ต้องใช้ — ห้ามข้าม pointer)

- `references/rules-detail.md` — กติกา Mission→Objective→Feature→Task + Naming Rules + MCP Call Signatures + กฎ Feature ย่อย/Weight/ประเมินเวลา/ตารางเวลามาตรฐาน + Planning Task + Approval/Persistence/Handoff/Next Session detail + AI Review & Evidence (ส่วนที่ 2) + กฎเมื่อแผนเปลี่ยน + Copy Block rules + Checklist ละเอียด → **เปิดตอนถึงขั้นที่ต้องใช้กฎ**
- `references/templates.md` — template รูปแบบแสดง + copy block ทั้งหมด (Task DONE, หัวข้อ Mission, ขอบเขต Mission, โครงสร้างเป้าหมาย, สรุปแผน, Mapping table, Mission Plan Summary, Session Handoff, สรุปผลงานตามแผน, ตารางฟิลด์ copy block) → **เปิดก่อนสร้าง output ทุกครั้ง ห้ามสร้าง template จากความจำ**
- `references/examples.md` — ตัวอย่าง objectives/คำนวณเวลา/Feature ย่อย + Mock-up Create Mission เต็ม + ตัวอย่าง copy block ที่ดี → เปิดเมื่อต้องการเห็นตัวอย่าง

## ภาพรวม Workflow (2 ส่วน)

```
ส่วนที่ 1: วางแผน Mission รายวัน          ส่วนที่ 2: สรุปผลหลังทำตามแผน
─────────────────────────────           ─────────────────────────────
เรียก kanban-tukdaeng ดู context             เรียก kanban-tukdaeng ดูสถานะปัจจุบัน
(get_session_context + get_board         (get_board + get_task
 + get_task + get_time_summary           + get_time_summary)
 + mcp_list_tools)
↓                                        ↓
คิด Mission + จำนวนวัน (1-5 วัน)         สรุปว่าในแต่ละแผนทำอะไรบ้าง
↓                                        ↓
สรุปหัวข้อ Mission (ตามฟอร์ม Create      สรุปเป็นข้อ ๆ แยกตาม Service
Mission: Baseline, วันที่, ผู้รับผิดชอบ) + copy block
+ copy block
↓
วางแผนแยกเป้าหมาย (Objectives) พร้อม
น้ำหนัก% (รวม 100%) + Feature ย่อย
+ ประเมินเวลา (1 วัน = 8 ชม. รวมไม่เกิน
Baseline ของ Mission)
↓
แต่ละ Objective ต้องมี Feature ย่อยที่เป็น
ผลลัพธ์ย่อยของ Objective และ map กับ
Task ที่เกี่ยวข้องได้ 1 task หรือหลาย task
↓
ทุก Feature ย่อยต้องระบุแผน "ตรวจสอบ" + "แก้ไข"
เว้นแต่งานนั้นเป็น decision/meeting ที่ไม่มีการแก้ไฟล์
↓
สรุปแผนเป็นข้อ ๆ แยกตามเป้าหมาย + copy block
↓
ผู้ใช้ตรวจและอนุมัติ Mission Plan
↓
ล็อก Approved Mission Baseline
↓
สร้าง Mission Plan Summary Copy Block สำหรับ Work Log
+ สร้าง Mission + execution Tasks ใน Kanban (todo เท่านั้น)
+ สร้าง/อัปเดต Session Handoff สำหรับ Agent
↓
แสดงสอง artifact แยกกัน แล้วจบ Planning Session
(execution เริ่มใน session ใหม่เท่านั้น)
```

**กฎเหล็ก:**
- ทั้ง 2 ส่วนแยกจากกันชัดเจน — ห้ามข้ามส่วน
- ทุกสรุปที่สำคัญ (Mission, แผน, ผล) ต้องมี **copy block** ให้ผู้ใช้ก๊อปไปวางระบบอื่นได้เลย
- ห้ามส่ง log/อัปเดตระบบภายนอกใด ๆ อัตโนมัติ — แค่สรุปและแสดง copy block

---

## เครื่องมือ kanban-tukdaeng ที่ใช้

ก่อนเริ่ม skill ให้เรียก `mcp_list_tools` ของ `kanban-tukdaeng` เพื่อดูเครื่องมือทั้งหมดที่มี แล้วเลือกใช้ตามความเหมาะสม:

```
mcp_list_tools(server_name="kanban-tukdaeng")
```

เครื่องมือหลักที่ใช้ใน skill นี้:

| Tool | ใช้เมื่อไร | จุดประสงค์ |
|---|---|---|
| `mcp_list_tools` | เริ่ม skill (ทุกครั้ง) | ดูเครื่องมือ/ฟีเจอร์ทั้งหมดที่มี เพื่อเลือกใช้ให้ตรงงาน |
| `get_session_context` | เริ่มส่วนที่ 1 | ดู board ปัจจุบัน + session notes ล่าสุด เพื่อ resume context |
| `get_board` | ทั้ง 2 ส่วน | ดู task ทั้งหมดใน board จัดกลุ่มตาม column (เห็น in_progress/todo/done) |
| `get_time_summary` | ทั้ง 2 ส่วน | สรุปชั่วโมงทำงานของ task DONE ตามวัน/ช่วงเวลา + analysis flag ชั่วโมงต่ำผิดปกติ |
| `get_task` | ทุกครั้งที่ต้องสรุป Mission ที่มี task DONE หรือเมื่อต้องตรวจ task เฉพาะ | ดู title/description/status/hours และ Activity timeline (note, status และ time events) ตาม id |
| `list_groups` | เมื่อต้องจัดกลุ่ม/กรองงาน | ดู tag/label ทั้งหมดใน project (เช่น option-master, asset-management, bo-module, document, prototype) |

> **แนะนำ:** ในส่วนที่ 1 (วางแผน) ให้เรียก `get_session_context` ก่อนเสมอเพื่อ resume session แล้วค่อยเรียก `get_board`/`get_time_summary` เสริมตามต้องการ


> **Signatures:** MCP call signatures canonical อยู่ที่ `references/rules-detail.md` § MCP Call Signatures — ใช้ชุดเดียวกันทั้ง 2 ส่วน

---

## ส่วนที่ 1: วางแผน Mission รายวัน (Daily Planning)

### เป้าหมาย
- วางแผนการทำงานของวันนี้/ช่วงนี้ในระดับ **Mission** (ไม่ใช่ task เล็ก ๆ)
- แยกแผนออกตาม **Service** ที่เกี่ยวข้อง พร้อมประเมินเวลา
- ทุกแผนต้องมี "ตรวจสอบ" + "แก้ไข" แจกใส่ในแต่ละ Feature ย่อย (subtask)
- สรุปออกมาเป็นข้อ ๆ พร้อม copy block ให้ผู้ใช้ก๊อปไปลงระบบอื่นได้

### ขั้นตอน


#### 1. เรียกข้อมูลจาก kanban-tukdaeng MCP

เรียกตามลำดับนี้ (บางตัวเรียกขนานกันได้):

→ Call signatures (canonical): `references/rules-detail.md` § MCP Call Signatures

#### 2. ดึงรายละเอียดของ task ที่ทำเสร็จแล้ว

→ กฎการรวบรวม + กฎ Activity timeline: `references/rules-detail.md` § ขั้น 2 · รูปแบบแสดง + copy block: `references/templates.md` § Task DONE

เมื่อ `get_board` พบ task ที่อยู่ใน `done` และเกี่ยวข้องกับ Mission ที่กำลังวางแผน ต้องเรียก `get_task` แยกทุก task เพื่ออ่านรายละเอียดเต็ม:

- ชั่วโมงใน task ใช้เพื่อการวิเคราะห์ภายในเท่านั้น และห้ามใส่ใน Copy block

> **การใช้ task DONE ในส่วนวางแผน:** รายละเอียด task DONE ใช้เป็น context สำหรับเข้าใจงานเดิมและ dependency เท่านั้น ห้ามนำสถานะ, ผลลัพธ์, Evidence หรือ bug ที่พบจาก task DONE ไปเขียนปนใน Mission Plan ใหม่ เว้นแต่ผู้ใช้ขอให้สรุปเป็น Work Summary

#### 3. คิด Mission + จำนวนวัน + เป้าหมายย่อย

วิเคราะห์จากข้อมูล kanban + session context ปัจจุบัน แล้วคิด Mission:

- **Mission** = แผนงานระดับหนึ่ง (ไม่ใช่ task เล็ก ๆ 1 อัน)
- **จำนวนวัน:** ขั้นต่ำ **1 วัน** ไม่เกิน **5 วัน** ต่อ Mission
- ถ้างานดูจะเกิน 5 วัน → แบ่งเป็นหลาย Mission
- **เป้าหมายย่อย (Objectives):** แบ่ง Mission ออกเป็นเป้าหมายย่อย **1-5 ข้อตามความเหมาะสม** — Mission เล็กหรือส่งมอบผลลัพธ์เดียวมีเป้าหมายเดียวได้ ไม่ต้องฝืนแตกหลายข้อ; แยกเป้าหมายเมื่อ deliverable/ประเภทหลักฐานต่างกัน (ดู Continuous Evidence Planning) และอย่าแตกยิบย่อยเกินความจำเป็น แต่ละเป้าหมายเป็นผลลัพธ์หลักของ Mission และ map กับ Feature/Task ที่ใช้ลง work log ได้

→ กฎ Planning Task + เป้าหมายย่อย: `references/rules-detail.md` § ขั้น 3 · ตัวอย่าง: `references/examples.md` § ตัวอย่าง Objectives

#### 4. สรุปหัวข้อ Mission + copy block

หลังคิด Mission แล้ว ให้สรุปหัวข้อ Mission ตามฟิลด์เดียวกับฟอร์ม **สร้างแผนภารกิจใหม่ (Create Mission)** ของระบบ Core Portal เพื่อให้ผู้ใช้ก๊อปข้อมูลไปกรอกฟอร์มได้ตรงช่องทันที:

→ ฟิลด์ฟอร์ม Create Mission + รูปแบบแสดง + copy block: `references/templates.md` § หัวข้อ Mission

#### 5. กำหนด Scope และ Acceptance Criteria

ก่อนแยกแผนตาม Service ต้องกำหนดขอบเขตของ Mission ให้ชัดเจน เพื่อป้องกันงานขยายระหว่างทำ:

→ รูปแบบขอบเขต Mission: `references/templates.md` § ขอบเขต Mission

#### 6. วางแผนแยกเป้าหมาย + ประเมินเวลา

เมื่อได้ Mission, จำนวนวัน และเป้าหมายย่อยแล้ว ให้วางแผนงาน **แยกตามเป้าหมายย่อย (Objectives)** โดยแต่ละเป้าหมายระบุ Service ที่เกี่ยวข้องและ Kanban task ที่ map:

→ โครงสร้างเป้าหมาย (ตามฟอร์ม Create Mission): `references/templates.md` § โครงสร้างเป้าหมาย
→ กฎการกรอก Feature ย่อย / Weight / AI vs คน / ตารางเวลามาตรฐาน / Over-budget: `references/rules-detail.md` § ขั้น 6
→ ตัวอย่างการคำนวณเวลา: `references/examples.md` § ตัวอย่างการคำนวณเวลา

#### 7. วิเคราะห์ Dependency และลำดับงาน

→ รายละเอียด dependency + critical path: `references/rules-detail.md` § ขั้น 7-8

หากลำดับจริงแตกต่างจากนี้ ให้ระบุเหตุผลในแผน และห้ามนับงานที่ยังเริ่มไม่ได้เป็นงานที่ทำเสร็จแล้ว

#### 8. วิเคราะห์ Risk และแผนรับมือ

→ รายการตัวอย่าง risk + แนวทางรับมือ: `references/rules-detail.md` § ขั้น 7-8

แต่ละ Risk ต้องมีแนวทางรับมือสั้น ๆ และระบุว่าใครเป็นผู้ตรวจสอบ

#### 9. ตรวจสอบ/แก้ไข แจกใส่ในแต่ละ Feature ย่อย

**กฎบังคับ:** "ตรวจสอบ" และ "แก้ไข" ไม่ใช่ฟิลด์แยกที่ระดับเป้าหมาย — แจกใส่ในแต่ละ Feature ย่อย (subtask) แทน เพราะ work log เกิดจาก Task ที่ปิดพร้อมสรุปแล้ว แต่ละ subtask ต้องมี build + ตรวจสอบ + แก้ไข ครบในตัวเอง

→ รูปแบบ Feature ย่อย: `references/templates.md` § Feature ย่อย · บทบาท AI vs คน + เหตุผล: `references/rules-detail.md` § ขั้น 9

#### 10. สรุปแผนเป็นข้อ ๆ แยกตามเป้าหมาย + copy block

หลังวางแผนครบทุกเป้าหมายแล้ว ให้สรุปแผนออกมาเป็นข้อ ๆ จัดกลุ่มตามเป้าหมาย พร้อมเวลา แล้วแสดงเป็น copy block:

→ รูปแบบแสดง + copy block (Detailed Mission Plan สำหรับ review): `references/templates.md` § สรุปแผนงานใน Mission

#### 11. Mapping Objective, Feature และ Kanban Task

ต้องเชื่อม Objective กับ Feature และ Task ที่เกี่ยวข้องเพื่อให้ตรวจสอบย้อนกลับได้ โดยใช้โครงสร้าง:

→ รูปแบบตาราง mapping: `references/templates.md` § Mapping table · กฎการ map + work log: `references/rules-detail.md` § ขั้น 11

#### 12. ตัวอย่าง Mock-up ฟอร์ม Create Mission

→ ตัวอย่างเต็ม (mock-up + copy block): `references/examples.md` § Mock-up ฟอร์ม Create Mission

#### 13. Mission Approval / Session End Workflow

ส่วนนี้ใช้เมื่อ **Mission Planning เสร็จ** และผู้ใช้ **อนุมัติ Mission Plan อย่างชัดเจน** ห้ามอนุมาน approval จากการที่ผู้ใช้เพียงอ่านแผนหรือขอแก้ไขแผน หลัง approval ให้สร้าง Mission Plan Summary และ Session Handoff เป็นสอง artifact แยกกันก่อนเริ่ม implementation; หากผู้ใช้ต้องการจบ planning session ให้บันทึก Handoff และจบ session ตาม flow ด้านล่าง

```text
Mission Planning Complete
→ User Approval
→ Approved Mission Baseline
→ Generate Mission Plan Summary Copy Block
→ Create Mission + execution Tasks ใน Kanban (ทุก task = todo เท่านั้น)
→ Generate/Update Session Handoff
→ Display ทั้งสอง artifact แยกกัน
→ End Planning Session (execution เริ่มใน session ใหม่เท่านั้น)
```

→ กฎลำดับหลัง approval + รายละเอียดทั้งหมด: `references/rules-detail.md` § ขั้น 13

- ห้ามเริ่ม **Mission execution task**, ย้าย execution task เป็น `in_progress` หรือเริ่ม execution timer โดยอัตโนมัติ กฎนี้ไม่ย้อนกลับไปห้าม Planning Task ที่ต้องอยู่ `in_progress` ระหว่างทำงานวางแผน และ Planning Task ควรถูกปิดหลัง baseline ได้รับ approval
- ถ้าผู้ใช้ยังไม่อนุมัติ ให้แสดง Draft Mission Plan/ฉบับแก้ไขตาม workflow เดิม และยังไม่เรียก output ว่า Approved
- หลังได้รับ approval ให้ทำตามลำดับนี้เท่านั้น: สร้าง Mission Plan Summary Copy Block → สร้าง Mission + execution tasks ใน Kanban (ทุก task = `todo` เท่านั้น, Category/Planned ครบตามกฎ Task Description) → สร้าง/อัปเดต Session Handoff → แสดงทั้งสอง artifact แยกกัน → จบ planning session
- **Planning session ห้ามต่อเป็น execution ในตัว** — หลังจบ planning session การเริ่มทำ execution task ตัวแรก (`move_task` → `in_progress` + ลงมือจริง) ต้องเกิดใน **session ใหม่เท่านั้น** ไม่ทำต่อเนื่องใน session วางแผน เพื่อให้ session execute รับช่วงจาก Session Handoff/Kanban state ที่สะอาด เว้นแต่ผู้ใช้สั่งชัดเจนว่าให้ทำต่อใน session เดียวกัน
- เมื่อมีทั้งสอง artifact ในคำตอบเดียวกัน ต้องแยก heading และ code block ชัดเจน ห้ามรวมเนื้อหาเป็น block เดียว
- หากผู้ใช้ขอจบ session ให้บันทึก **Session Handoff** ผ่าน `save_session_note` เมื่อเครื่องมือพร้อม; การบันทึกนี้เป็น task/session context ภายใน Kanban ไม่ใช่การส่ง Work Log เข้า Core Portal


##### 13.1 Mission Plan Summary Copy Block — สำหรับ Work Log

→ ข้อมูลขั้นต่ำ + Task Display Rule + รูปแบบ + experience rules: `references/templates.md` § Mission Plan Summary Copy Block

##### 13.1.1 Baseline Persistence — บันทึก Approved Plan ให้เรียกย้อนได้ (บังคับ)

→ กฎ persistence 2 ชั้น + กฎแก้ label หลัง approve: `references/rules-detail.md` § 13.1.1

##### 13.2 Session Handoff — สำหรับ Agent / Session ถัดไป

Session Handoff เป็น execution context หลักสำหรับทำงานข้าม session และต้อง self-contained พอให้ Agent เริ่มจาก current state ได้อย่างปลอดภัย

→ field spec ที่ต้องคงไว้: `references/templates.md` § Session Handoff · กฎ Handoff: `references/rules-detail.md` § 13.2

##### 13.3 Next Session Workflow

Mission Plan Summary ไม่ใช่ execution context หลัก การเริ่ม Execute Mission ต้องอ้าง Session Handoff:

→ flow + กฎ Next Session: `references/rules-detail.md` § 13.3

### กฎสำคัญส่วนที่ 1

- ⚠️ **ห้ามส่ง log/อัปเดตระบบภายนอกใด ๆ** — แค่วางแผนและแสดง copy block
- **การวางแผน Mission ไม่ใช่ Objective บังคับ** — บันทึก planning record แยกได้ แต่ไม่ต้องนับเป็น Objective ของ Mission เว้นแต่ผู้ใช้ระบุว่าการวางแผนเป็น deliverable
- **รูปแบบ Objective/Feature/Task (บังคับ):**
  - Tasks เป็นลิสข้อ ๆ ลงมา ไม่ใช่ `,` หรือ `+` คั่นบรรทัดเดียว
  - รายละเอียดของ Objective ไม่ใส่ชั่วโมง — เวลารวมอยู่ใน Feature ย่อยแล้ว
  - Feature ย่อยต้องเป็นผลลัพธ์ย่อยของ Objective และเขียนเป็นภาษาที่เข้าใจง่าย
  - 1 Feature map กับ 1 task หรือหลาย task ได้ ถ้า Task เหล่านั้นทำเพื่อผลลัพธ์เดียวกัน
  - ไม่ต้องสร้าง Feature ใหม่เพียงเพราะมี Task เพิ่ม หากยังเป็นผลลัพธ์เดียวกัน
  - Feature เป็นหน่วยสำหรับ work log; เมื่อปิด Task ให้สร้าง/เตรียม log ของ Task นั้นโดยเลือก Objective และ Feature ที่ map ไว้
  - ตรวจสอบ/แก้ไขแจกใส่ในระดับ Feature ไม่ต้องเขียนซ้ำทุก Task และไม่ต้องสร้าง Task ตรวจสอบ/แก้ไขแยก เว้นแต่เป็นงานใหญ่ที่ต้องติดตามแยก
  - ตรวจสอบ/แก้ไขใช้ `()` ครอบเวลาในรายละเอียด Feature
  - Mission Plan ต้องใช้ภาษาของงานที่วางแผนจะทำ ห้ามใส่ bug หรือผล QA ที่เกิดขึ้นภายหลัง
- **ภาษาใน copy block (บังคับ):** ใช้ภาษาเข้าใจง่าย — เปลี่ยนคำโค้ด/เทคนิคที่คนทั่วไปไม่เข้าใจเป็นคำเข้าใจง่าย แต่คำเฉพาะ/ศัพท์ที่คุ้นเคย (เช่น breadcrumb, Alert, asset, spec, baseline, Kanban) เก็บไว้ได้ ไม่บังคับล้วนไทย — ห้ามใช้ชื่อฟังก์ชัน/ชื่อโค้ด (เช่น `renderWatchAlertList()`, `mock data`, `status badge`, `soft delete`, `cross-reference`, `viewport`) ใน copy block
- รวมเวลาทุกเป้าหมาย (Total Planned Hours) ประเมินตามความจริง (36, 38, 40 ฯลฯ) — **Baseline = Total เสมอ** ค่า "เหลือชั่วโมงให้วางแผน" = 0 เสมอ (Baseline อิงตาม Total ไม่ใช่ Days × 8 โดยตรง)
- น้ำหนัก (Weight) ของทุกเป้าหมายรวมกันต้องเท่ากับ 100% เสมอ
- จำนวนวันต่อ Mission: ขั้นต่ำ 1 วัน ไม่เกิน 5 วัน
- ถ้าแผนเกิน 5 วัน ให้แบ่งเป็น Mission ใหม่ ไม่ปรับลดเวลาโดยไม่มีเหตุผล
- ⚠️ **ห้ามแก้แผนหลัง start Mission โดยไม่มีเหตุผล** — เมื่อ Mission เริ่มดำเนินการแล้ว (มี task เป็น in_progress แล้ว) ห้ามแก้ไขเป้าหมาย/น้ำหนัก/ชั่วโมง ถ้าจำเป็นต้องแก้ ต้องระบุเหตุผลชัดเจน เช่น requirement เปลี่ยน / พบงานบล็อก / scope เปลี่ยน และต้องแจ้งผู้ใช้ก่อน
- **คะแนนความแม่นยำในการวางแผน (Planning Accuracy Score):** ระบบประเมินความแม่นยำของแผนเทียบกับการทำจริง — ถ้าทำตรงตามแผนทุกเป้าหมาย (เวลาจริง = เวลาที่วางแผน ไม่มี task เกิน/ต่ำกว่าแผน) จะได้ **100 คะแนนเต็ม** ถ้าเบี่ยงเบือนจากแผน (task เกินเวลา, งานนอกแผนเกิดขึ้น, ต้องแก้แผนระหว่างทำ) คะแนนจะถูกหัก คะแนนนี้มีผลต่อการประเมินเกรดการทำงาน ดังนั้นต้องวางแผนให้แม่นยำที่สุดตั้งแต่ต้น และพยายามทำตรงตามแผน
- ถ้าผู้ใช้ขอแก้ไข Mission/แผน → แก้ไขแล้วแสดง copy block ใหม่
- หลังผู้ใช้อนุมัติ Mission Plan → สร้าง **Mission Plan Summary Copy Block** → สร้าง Mission + execution tasks (`todo` เท่านั้น) → **Session Handoff** แยกกันตาม section 13 → persist Handoff แล้วจบ planning session; execution เริ่มใน session ใหม่เสมอ เว้นแต่ผู้ใช้สั่งให้ทำต่อชัดเจน
- Mission Plan Summary ใช้สำหรับ Work Log และห้ามมี Kanban UUID/internal ID; Session Handoff ใช้สำหรับ Agent และคง internal IDs/technical context ได้
- การสร้าง approval artifacts ไม่อนุญาตให้เริ่ม implementation, ย้าย **Mission execution task** เป็น `in_progress` หรือเริ่ม execution timer; Planning Task ที่ใช้จับเวลางานวางแผนต้องถูกเริ่มไว้ก่อนหน้าและปิดหลัง approval ตาม workflow ของ Planning Task
- ถ้ามีงานเพิ่มนอก Scope → แยกเป็นงานนอกขอบเขตและเสนอ Mission ใหม่
- ⚠️ **Protected screens:** ถ้าแผนมีโอกาสกระทบ protected screens (ตาม `AGENTS.md` และ `PROTECTED_SCREENS.md`) ต้องระบุในเป้าหมายว่าจะตรวจสอบอย่างไร และต้องหยุดขออนุมัติก่อนแก้ ห้ามแก้ protected screens โดยไม่ได้รับอนุมัติจากผู้ใช้
- **Kanban task style & Naming format:** ถ้าต้องสร้าง task ใหม่ในแผน (`create_task`) หรือแสดงใน Mission Plan / Summary / Kanban:
  - **ชื่อ Task ต้องอยู่ในรูปแบบ `<Task-Code> <Task Name>` เสมอ** เช่น `AIL-019 Design forgot/reset contract`, `RP-014 สร้าง flow ปิด Custom Role` โดยมีรหัส Task ที่คนอ่านเข้าใจง่ายนำหน้า ตามด้วยชื่อเนื้อหางานที่กระชับ
  - **ห้ามใช้เฉพาะ UUID / Internal ID ของระบบเป็นชื่อ Task เด็ดขาด** เพราะอ่านยากและไม่สื่อความหมาย
  - เขียนเนื้อหา Task เป็น complete execution brief ตามรูปแบบใน `AGENTS.md` (ภาษาไทย เก็บศัพท์เทคนิคภาษาอังกฤษ) และใช้ Kanban Completion Rule: ห้ามย้าย task ไป `done` จนกว่าผู้ใช้ยืนยันว่าผลลัพธ์ OK
  - **ก่อนออกเลข Task-Code ต้องเช็ครหัสที่ใช้ไปแล้วบนบอร์ดเสมอ (บังคับ)** — ดึงรายการ task ผ่าน `get_time_summary` (`status: "all"`, `from_date` ย้อนหลัง) แล้วหา prefix เดียวกัน เลือกเลขถัดไปที่ว่าง ห้ามใช้ code ซ้ำกับ task เดิมรวมถึงที่ done/backlog แล้ว (เหตุการณ์จริง: `PLN-005` ถูกสร้างซ้ำกับ planning task เดิมเมื่อ 2026-11-05)
  - **Task Description ต้องมีบรรทัด Planned เสมอทุกหมวด:** `Category: <หมวด> | Planned: <X> ชม. (Category Max <Y> ชม.)` โดย `Y` = เป้าหมายหมวดตามตารางมาตรฐาน ซึ่งเป็นเกณฑ์ Review โดยตรง; ห้ามใส่เฉพาะบางหมวด — `Planned` ใช้ประเมินแผน task และต้องสมจริง ห้ามตั้งต่ำกว่าความเป็นจริงหรือคูณ Category Max ด้วย 1.5
- **Objective และ Feature ไม่ใช่ Task:** Objective เป็นผลลัพธ์หลัก, Feature เป็นผลลัพธ์ย่อย และ Task เป็นงานที่ใช้ลงมือทำ/ลง log — 1 Objective map กับหลาย Feature ได้ และ 1 Feature map กับหลาย Task ได้
- **การตรวจสอบและแก้ไขอยู่ใน Feature:** วางแผนไว้ใน Feature เดียวกับงานหลัก ไม่ต้องสร้าง Task ตรวจสอบ/แก้ไขแยก เว้นแต่มีขนาดใหญ่หรือจำเป็นต้องติดตามเป็นงานอิสระ


---

## ส่วนที่ 2: สรุปผลหลังทำตามแผน (Work Summary)

### เป้าหมาย
- หลังทำตามแผนในส่วนที่ 1 แล้ว ให้สรุปว่า **ในแต่ละเป้าหมายได้ทำอะไรลงไปบ้าง**
- สรุปเป็นข้อ ๆ แยกตามเป้าหมาย พร้อม log การทำงานรวมจากทุก task ในเป้าหมาย

### ขั้นตอน

#### 1. เรียกข้อมูลจาก kanban-tukdaeng MCP

→ Call signatures: canonical ชุดเดียวกับส่วนที่ 1 — `references/rules-detail.md` § MCP Call Signatures

#### 2. ตรวจสอบงานที่ AI ทำและรวบรวม Evidence

→ AI Review checklist + Evidence + Submission Evidence ต่อเป้าหมาย: `references/rules-detail.md` § ส่วนที่ 2 ขั้น 2

#### 3. สรุปผลเป็นข้อ ๆ แยกตามเป้าหมาย + copy block

สรุปว่าในแต่ละเป้าหมาย (จากส่วนที่ 1) ได้ทำอะไรลงไปบ้าง — เปรียบเทียบกับแผนที่วางไว้ และรวม log การทำงานจากทุก task ในเป้าหมาย:

→ รูปแบบแสดง + copy block (น้ำหนัก/ชั่วโมง วางแผน vs ใช้จริง ครบ): `references/templates.md` § สรุปผลงานตามแผน

### กฎสำคัญส่วนที่ 2

- ⚠️ **ห้ามส่ง log/อัปเดตระบบภายนอกใด ๆ** — แค่สรุปและแสดง copy block
- สรุปตามเป้าหมายที่วางไว้ในส่วนที่ 1 — ถ้าไม่มีแผนเดิม ให้ถามผู้ใช้หรือสรุปจาก session context
- ใช้ภาษาเข้าใจง่าย เน้นสิ่งที่ทำและผลลัพธ์ ไม่ใช่วิธีทำละเอียด
- ระบุสถานะชัดเจน: เสร็จ / บางส่วน / ยังไม่ทำ / รอตรวจสอบ
- ต้องรายงานผลเทียบกับ Acceptance Criteria ไม่ใช่สรุปจากสถานะ Kanban อย่างเดียว
- งานที่ไม่มี Evidence เพียงพอ ห้ามสรุปเป็น "เสร็จ"
- **log การทำงานของเป้าหมาย** ต้องรวมจาก Activity timeline ของทุก task ที่ map กับเป้าหมายนั้น — แสดงตามลำดับเวลา ระบุ task id ที่เป็นเจ้าของ event

### กฎเมื่อแผนเปลี่ยนระหว่างทำ

→ ขั้นตอนเมื่อแผนเปลี่ยน (9 ข้อ): `references/rules-detail.md` § กฎเมื่อแผนเปลี่ยนระหว่างทำ

---

## รูปแบบ Copy Block

→ กฎทั่วไป 15 ข้อ: `references/rules-detail.md` § รูปแบบ Copy Block · ตารางฟิลด์ copy block แยกตามส่วน: `references/templates.md` § ตารางฟิลด์ copy block

---

## Services ที่เกี่ยวข้อง

| Service | คำอธิบาย | workspace |
|---|---|---|
| BackOffice (BO) | เอกสาร spec ของระบบ admin (markdown modules, baseline, version) | `BackOffice/` |
| FrontOffice (FO) | เอกสาร spec ของระบบผู้ใช้ (markdown modules, PRD, handoff) | `FrontOffice/` |
| Prototypes | prototype screen ของ BO (HTML, assets, mock data) | `Prototypes/` |

> **หมายเหตุ:** ถ้ามี Service อื่นที่เกี่ยวข้อง (เช่น SeedData, PRD, docs) สามารถเพิ่มได้ตามความเหมาะสม — แต่ทั้ง 3 ด้านบนเป็นหลัก

> **Protected screens:** งานที่เกี่ยวกับ Prototypes ต้องตรวจสอบกับ `AGENTS.md` และ `PROTECTED_SCREENS.md` เสมอ เพราะ prototype ส่วนใหญ่เป็น protected screen

---

**Reminder:** ก่อนสร้าง output/copy block ทุกครั้ง ให้เปิด `references/templates.md` ตาม References Map ด้านบน — ห้ามสร้าง template จากความจำ
