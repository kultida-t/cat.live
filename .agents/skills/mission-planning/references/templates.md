# mission-planning — Output Templates (references/templates.md)

> ไฟล์นี้เก็บ template รูปแบบแสดงผลและ copy block ทั้งหมดของ skill mission-planning — **เปิดก่อนสร้าง output ทุกครั้ง ห้ามสร้าง template จากความจำ**

## Task DONE — รูปแบบแสดง + Copy block (ส่วนที่ 1 ขั้น 2)

รูปแบบสรุปที่ต้องแสดงก่อนวางแผนงานที่เหลือ:

```
## Task ที่ทำเสร็จแล้วและรายละเอียดการทำงาน

### [<task id>] <ชื่อ task>
- Service/กลุ่ม: <ข้อมูล>
- สถานะ: Done
- รายละเอียดที่ทำ:
  - <รายการจาก Description>
- Activity timeline:
  - [<วันที่เวลา>] Note: <รายละเอียด>
  - [<วันที่เวลา>] Status: <รายละเอียด>
  - [<วันที่เวลา>] Time: <รายละเอียด>
- Dependency: <รายการ หรือ ไม่มี>
```

**Copy block รายละเอียด task ที่เสร็จแล้ว:**

```text
Task ที่ทำเสร็จแล้ว: <ชื่อ task>
Task ID: <task id>
Service/กลุ่ม: <ข้อมูล>
สถานะ: Done
รายละเอียดที่ทำ:
- <รายการจาก Description>
Activity timeline:
- [<วันที่เวลา>] Note: <รายละเอียด>
- [<วันที่เวลา>] Status: <รายละเอียด>
- [<วันที่เวลา>] Time: <รายละเอียด>
Dependency: <รายการ หรือ ไม่มี>
```

## หัวข้อ Mission (ฟอร์ม Create Mission) — ขั้น 4

> Copy block ในขั้นตอนนี้เป็น **Draft/Detailed Mission Plan ก่อนอนุมัติ** ไม่ใช่ Mission Plan Summary หลังอนุมัติ และไม่ใช่ Session Handoff

**ฟิลด์ที่ต้องระบุ (ตามฟอร์ม Create Mission):**
- **ชื่อแผนงาน (Mission Name)**
- **พนักงานผู้รับผิดชอบ** — ชื่อ/อีเมลผู้รับผิดชอบหลักของ Mission
- **โปรเจกต์ (Apps/Services ที่รับผิดชอบ)** — เลือกจาก Service ที่เกี่ยวข้อง (BackOffice / FrontOffice / Prototypes)
- **วันที่เริ่ม (Start Date)** และ **วันที่เสร็จ (End Date)**
- **จำนวนวันที่ตามแผน (Planned Days)** — ขั้นต่ำ 1 วัน ไม่เกิน 5 วัน
- **งบประมาณชั่วโมงตามแผน (Baseline)** = **จำนวนชั่วโมงทั้งหมดตามแผน (Total Planned Hours) เสมอ** — Baseline อิงตามชั่วโมงที่ใส่ ไม่ใช่ Days × 8 โดยตรง
- **จำนวนชั่วโมงทั้งหมดตามแผน (Total Planned Hours)** = ผลรวมชั่วโมงประเมินของทุกเป้าหมายย่อย (คำนวณอัตโนมัติจาก Objectives ในขั้นตอนที่ 6) — ปรับได้ตามการประเมินจริง (36, 38, 40 ฯลฯ)
  - **ถ้าผู้ใช้ใส่ Total เอง** → Total = ค่าที่ใส่, Baseline = Total
  - **ถ้าผู้ใช้ไม่ใส่ Total** → Total = Planned Days × 8 ชม. (วันละ 8 ชม. อัตโนมัติ), Baseline = Total
- **สถานะจัดสรรชั่วโมง (เหลือชั่วโมงให้วางแผน)** = Baseline − Total Planned Hours = **0 เสมอ** (เพราะ Baseline = Total)

**รูปแบบที่แสดงให้ผู้ใช้:**

```
## แผนงานที่วางแผน

**ชื่อแผนงาน:** <ชื่อ Mission ภาษาเข้าใจง่าย>
**พนักงานผู้รับผิดชอบ:** <ชื่อ/อีเมล>
**โปรเจกต์:** <BackOffice / FrontOffice / Prototypes / ผสม>
**วันที่เริ่ม:** <DD/MM/YYYY>
**วันที่เสร็จ:** <DD/MM/YYYY>
**จำนวนวันที่ตามแผน:** <N> วัน
**งบประมาณชั่วโมงตามแผน (Baseline):** <Total> ชม. (= Total Planned Hours — อิงตามชั่วโมงที่ใส่ ถ้าไม่ใส่ = <N> วัน x 8 ชม.)
**จำนวนชั่วโมงทั้งหมดตามแผน:** <รวมจาก Objectives> ชม. (ประเมินตามความจริง)
**เหลือชั่วโมงให้วางแผน:** 0 ชม. (Baseline = Total)
**ภาพรวม:** <1-2 บรรทัดอธิบายว่า Mission นี้ทำอะไร>
```

**Copy block (ก๊อปไปลงระบบอื่นได้เลย):**

```text
แผนงาน: <ชื่อ Mission>
พนักงานผู้รับผิดชอบ: <ชื่อ/อีเมล>
โปรเจกต์: <Service>
วันที่เริ่ม: <DD/MM/YYYY>
วันที่เสร็จ: <DD/MM/YYYY>
จำนวนวันที่ตามแผน: <N> วัน
งบประมาณชั่วโมงตามแผน (Baseline): <Total> ชม.
จำนวนชั่วโมงทั้งหมดตามแผน: <Total> ชม.
เหลือชั่วโมงให้วางแผน: 0 ชม.
ภาพรวม: <1-2 บรรทัด>
```

> ⚠️ ห้ามส่ง log/อัปเดตระบบใด ๆ ในขั้นนี้ — แค่แสดงสรุปและ copy block
> ℹ️ copy block ของหัวข้อ Mission **ให้ใส่ Baseline, จำนวนชั่วโมงทั้งหมดตามแผน และเหลือชั่วโมงให้วางแผน** ตามกฎรูปแบบ Copy Block (ดู [รูปแบบ Copy Block](#รูปแบบ-copy-block))

## ขอบเขต Mission (Scope + Acceptance Criteria) — ขั้น 5

ก่อนแยกแผนตาม Service ต้องกำหนดขอบเขตของ Mission ให้ชัดเจน เพื่อป้องกันงานขยายระหว่างทำ:

- **เป้าหมายหลัก:** Mission นี้ต้องการเปลี่ยนแปลงหรือส่งมอบอะไร
- **สิ่งที่ต้องส่งมอบ:** ผลลัพธ์ที่ต้องมีเมื่อจบ Mission
- **สิ่งที่ไม่รวม:** งานที่เกี่ยวข้องแต่ยังไม่อยู่ใน Mission นี้
- **Acceptance Criteria:** เงื่อนไขที่ใช้ตัดสินว่างานเสร็จจริง

รูปแบบสรุป:

```
## ขอบเขต Mission

เป้าหมาย:
- <เป้าหมายหลัก>

สิ่งที่ต้องส่งมอบ:
- <ผลลัพธ์ที่ต้องมี 1>
- <ผลลัพธ์ที่ต้องมี 2>

สิ่งที่ไม่รวม:
- <งานที่ยังไม่รวมใน Mission>

Acceptance Criteria:
- [ ] <เงื่อนไขตรวจสอบ 1>
- [ ] <เงื่อนไขตรวจสอบ 2>
```

Acceptance Criteria ควรตรวจสอบได้จริง เช่น เอกสารครบทุก section ตาม template, cross-reference ครบ, prototype แสดงข้อมูลถูกต้องตาม spec, QA checklist ผ่าน และ document version อัปเดต

## โครงสร้างเป้าหมาย (ตามฟอร์ม Create Mission) — ขั้น 6

**โครงสร้างของแต่ละเป้าหมาย (ตรงกับส่วน "เป้าหมายย่อย (Objectives)" ในฟอร์ม Create Mission):**

```
เป้าหมาย <N>: <ชื่อเป้าหมาย>
- Service: <BackOffice / FrontOffice / Prototypes / ผสม>
- Tasks:
  - <task id 1>
  - <task id 2>
- น้ำหนัก (Weight): <W>% (น้ำหนักความสำคัญของเป้าหมายนี้ เทียบกับเป้าหมายอื่นใน Mission)
- ชั่วโมงที่คาดการณ์ (Estimated Hours): <X> ชม.
- ผู้รับผิดชอบหลัก (Assignee): <ชื่อ/อีเมล หรือ ไม่ระบุ>
- รายละเอียด: <ทำอะไร>
- Feature ย่อย:
  - [<task id 1>] <รายละเอียด feature + ตรวจสอบ + แก้ไข> (<เวลา> ชม.)
  - [<task id 2>] <รายละเอียด feature + ตรวจสอบ + แก้ไข> (<เวลา> ชม.)
- Dependency: <หลังเป้าหมายใด>
- work log: เกิดหลังสรุปและปิด Task โดยเลือก Objective และ Feature ที่ map กับ Task นั้น
```

## Feature ย่อย — รูปแบบ (ขั้น 9)

**รูปแบบใน Feature ย่อย:**
```
- [<task id>] <งานหลัก> + ตรวจสอบ (<เวลาตรวจสอบ>) + แก้ไข (<เวลาแก้ไข>) (<เวลารวม> ชม.)
```

## สรุปแผนงานใน Mission — ขั้น 10

หลังวางแผนครบทุกเป้าหมายแล้ว ให้สรุปแผนออกมาเป็นข้อ ๆ จัดกลุ่มตามเป้าหมาย พร้อมเวลา แล้วแสดงเป็น copy block:

> Copy block ในขั้นตอนนี้เป็น **Detailed Mission Plan สำหรับ review ก่อน approval** จึงแสดงรายละเอียด planning ได้เต็มรูปแบบ; หลังผู้ใช้อนุมัติและต้องการจบ planning session ให้สร้าง artifact ใหม่ตาม section 13 แยกต่างหาก

**รูปแบบที่แสดงให้ผู้ใช้:**

```
## สรุปแผนงานใน Mission

### เป้าหมาย 1: <ชื่อเป้าหมาย> (น้ำหนัก <W1>% | รวม <X> ชม.)
- Service: <BackOffice / FrontOffice / Prototypes / ผสม>
- Tasks:
  - <task id 1>
  - <task id 2>
- ผู้รับผิดชอบหลัก: <ชื่อ/อีเมล หรือ ไม่ระบุ>
- รายละเอียด: <ทำอะไร>
- Feature ย่อย:
  - [<task id 1>] <รายละเอียด feature + ตรวจสอบ + แก้ไข> (<เวลา> ชม.)
  - [<task id 2>] <รายละเอียด feature + ตรวจสอบ + แก้ไข> (<เวลา> ชม.)
- Dependency: <หลังเป้าหมายใด>

### เป้าหมาย 2: <ชื่อเป้าหมาย> (น้ำหนัก <W2>% | รวม <Y> ชม.)
- ...

**น้ำหนักรวม:** <W1+W2+...> % (ต้อง = 100%)
**รวมเวลาทั้งหมด (Total Planned Hours):** <X+Y+Z> ชม. (= Baseline)
**เหลือชั่วโมงให้วางแผน:** 0 ชม. (Baseline = Total)
```

**Copy block (ก๊อปไปลงระบบอื่นได้เลย — ใส่น้ำหนัก/ชั่วโมงครบ):**

```text
แผนงาน Mission: <ชื่อ Mission>
วันที่เริ่ม: <YYYY-MM-DD>
วันที่สิ้นสุด: <YYYY-MM-DD>
ระยะเวลา: <N> วัน
งบประมาณชั่วโมงตามแผน (Baseline): <Total> ชม.
จำนวนชั่วโมงทั้งหมดตามแผน: <Total> ชม.
เหลือชั่วโมงให้วางแผน: 0 ชม.

[เป้าหมาย 1] <ชื่อเป้าหมาย> (น้ำหนัก <W1>% | <X> ชม.)
- Service: <Service>
- Tasks:
  - <task id 1>
  - <task id 2>
- ผู้รับผิดชอบหลัก: <ชื่อ/อีเมล หรือ ไม่ระบุ>
- รายละเอียด: <ทำอะไร>
- Feature ย่อย:
  - [<task id 1>] <รายละเอียด feature + ตรวจสอบ + แก้ไข> (<เวลา> ชม.)
  - [<task id 2>] <รายละเอียด feature + ตรวจสอบ + แก้ไข> (<เวลา> ชม.)
- Dependency: <หลังเป้าหมายใด>

[เป้าหมาย 2] <ชื่อเป้าหมาย> (น้ำหนัก <W2>% | <Y> ชม.)
- ...

น้ำหนักรวม: 100%
```

## Mapping table — ขั้น 11

ต้องเชื่อม Objective กับ Feature และ Task ที่เกี่ยวข้องเพื่อให้ตรวจสอบย้อนกลับได้ โดยใช้โครงสร้าง:

```text
Objective
└── Feature ย่อย
    └── Task ที่เกี่ยวข้อง 1 task หรือหลาย task
```

| Objective | Feature | Service | Kanban task ID | สถานะ |
|---|---|---|---|---|
| <เป้าหมาย 1> | <Feature 1> | <Service> | <task id 1>, <task id 2> | <todo/in_progress/done> |
| <เป้าหมาย 1> | <Feature 2> | <Service> | <task id 3> | <todo/in_progress/done> |
| <เป้าหมาย 2> | <Feature 3> | <Service> | <task id 4>, <task id 5> | <todo/in_progress/done> |

## Mission Plan Summary Copy Block — 13.1

Mission Plan Summary เป็นสรุปภาพรวม Approved Mission Baseline สำหรับคนทั่วไปอ่านย้อนหลัง ไม่ใช่ technical handoff และไม่ใช่ Work Summary หลัง implementation

**ข้อมูลขั้นต่ำที่ต้องมี:**
- Mission Name
- Planned Duration และ Planned Start/End ถ้ามี
- Total Planned Hours/Baseline
- Objective → Feature → Task Mapping
- Objective Weight และ Planned Hours ต่อ Objective
- Planned Hours ของแต่ละ Task
- Execution Sequence

**Task Display Rule (บังคับ):**
- แสดง Task ด้วย business-facing task code + ชื่อเต็ม + Planned Hours เช่น `AIL-002 กำหนด Invitation Lifecycle และ Security Contract — 1 ชม.`
- ห้ามแสดงรูปแบบ `AIL-002 [51ffcda4]`
- ห้ามแสดง Kanban UUID, partial UUID, database ID หรือ internal task/mission identifier อื่นใดใน Mission Plan Summary
- ถ้า Task ไม่มี business-facing code ให้ใช้ชื่อ Task อย่างเดียว ห้ามแทนด้วย UUID
- Feature ต้องอยู่ติดกับ Task ที่ map อยู่ใต้ Feature นั้น ห้ามแยก Feature และ Task เป็นคนละรายการจนมอง mapping ไม่ออก
- ชื่อ Objective และ Feature ใน Summary ต้องเป็นชื่อ label สั้นตาม Naming Rules — ห้ามต่อ scope/behavior/AC ยาว ๆ ไว้ในชื่อ ถ้าต้องอธิบาย Feature ให้ใช้ field แยก (เช่น `Scope: ...`)

**รูปแบบ Mission Plan Summary Copy Block:**

```text
Mission <number>: <Mission Name>

ระยะเวลาแผน: <human-readable date range> (<duration>)
เวลาตามแผนทั้งหมด: <total planned hours>

เป้าหมาย 1: <Objective Name>

เวลาตามแผน: <objective planned hours> (<objective weight>%)

Feature: <Feature Name>

- <TASK-CODE> <Task Name> — <task planned hours>

Feature: <Feature Name>

- <TASK-CODE> <Task Name> — <task planned hours>
- <TASK-CODE> <Task Name> — <task planned hours>

เป้าหมาย 2: <Objective Name>

ใช้ structure เดียวกันต่อจนครบทุก Objective

ลำดับการดำเนินงาน

<TASK> → <TASK> → <TASK>
```

**Mission Summary Copy Experience Rules:**
- หนึ่ง Mission Summary ต้องอยู่ใน `text` code block เดียว เพื่อให้กด Copy แล้วนำไปวางใน Google Docs ได้ทันที
- คง hierarchy ทางข้อมูล Mission → Objective → Feature → Task ด้วยลำดับข้อความและช่องว่าง โดยไม่ใช้ Markdown heading (`#`, `##`, `###`), bold, inline code หรือ horizontal rule
- Task ต้องอยู่ใต้ Feature ที่ map จริง และแสดงเป็น `<TASK-CODE> <Task Name> — <task planned hours>` โดยไม่ครอบ Task Code ด้วย backtick
- รายการทุกข้อใน Copy Block ต้องขึ้นต้นด้วย literal `- ` ภายใน `text` code block; ห้ามใช้ `*` หรือรูปแบบที่ UI render เป็น bullet symbol `•`
- วันที่ให้ใช้รูปแบบ human-readable เมื่อทำได้โดยไม่เปลี่ยนค่าจริง เช่น `21–23 ก.ย. 2026 (3 วัน)`
- แสดง Planned Time ครบ 3 ระดับ: Total Planned Hours ของ Mission, Planned Hours + Weight ของ Objective และ Planned Hours ของ Task แต่ละตัว
- ชั่วโมงใน Summary แสดงครั้งเดียวแบบอ่านง่าย: `30 นาที`, `<N> ชม.` หรือ `<N> ชม. <M> นาที`; ห้ามแสดง `1 ชม. 0 นาที`, decimal hours ภาษาอังกฤษ หรือค่าซ้ำแบบ `2 ชม. 30 นาที (2.5 ชม.)`
- ถ้า Task อยู่ stage เดียวกันหรือทำคู่ขนาน ให้คั่นด้วย `/` ในลำดับ เช่น `AIL-004 → AIL-005 / AIL-006 → AIL-007`
- ชื่อ Mission, Objective และ Feature ปรับ wording ให้เหมาะกับงานจริงได้ แต่ Mission Scope, Task Code/Task Name, mapping, Weight, Planned Hours, Duration และ Execution Sequence ต้องตรง Approved Mission Plan
- Mission Plan Summary เป็น Planning Log: ห้ามแสดง Actual Hours, Actual QA Result, Implementation Result หรือ Session Handoff technical context
- เนื้อหาสำคัญทั้งหมดต้องอยู่ใน Copy Block เดียว; ข้อความนอก Block มีได้เพียงคำอธิบายสั้น ๆ และห้ามแยกส่วนของ Summary ออกไปไว้ภายนอก
- ห้ามเพิ่ม technical handoff, Full/Partial Kanban UUID, Database ID หรือ Internal Identifier ลงใน Summary

Summary ต้องเป็น forward-looking Approved Plan เท่านั้น ห้ามใส่ actual hours, Activity timeline, Evidence, ผล QA หรือรายละเอียด implementation ที่เกิดขึ้นภายหลัง

## Session Handoff — field spec — 13.2

##### 13.2 Session Handoff — สำหรับ Agent / Session ถัดไป

Session Handoff เป็น execution context หลักสำหรับทำงานข้าม session และต้อง self-contained พอให้ Agent เริ่มจาก current state ได้อย่างปลอดภัย

**ข้อมูลที่ต้องคงไว้ตามความเกี่ยวข้อง:**
- Mission/Requirement identifiers และ planning status
- Approved Business Baseline
- Scope, Out of Scope, Deliverables และ Mission Boundaries
- Objectives, Features, Tasks และ internal Kanban IDs เมื่อจำเป็น
- Dependencies และ approved execution order
- Acceptance Criteria
- Risks และ Open Items
- Protected Scope และ approval constraints
- Requirement Traceability
- Duplicate/Existing Work considerations
- Current Kanban State รวม task status และ active timer
- Next executable Task
- Next Session instructions รวม tool/context ที่ต้องโหลดและเงื่อนไขก่อน `move_task → in_progress`

## สรุปผลงานตามแผน — ส่วนที่ 2 ขั้น 3

สรุปว่าในแต่ละเป้าหมาย (จากส่วนที่ 1) ได้ทำอะไรลงไปบ้าง — เปรียบเทียบกับแผนที่วางไว้ และรวม log การทำงานจากทุก task ในเป้าหมาย:

**รูปแบบที่แสดงให้ผู้ใช้:**

```
## สรุปผลงานตามแผน

### เป้าหมาย 1: <ชื่อเป้าหมาย>
- Service: <BackOffice / FrontOffice / Prototypes / ผสม>
- Tasks:
  - <task id 1>
  - <task id 2>
- รายละเอียดที่ทำ:
  - <สิ่งที่ทำจริง>
  - <ผลลัพธ์ที่ได้>
- log การทำงาน (รวมจากทุก task):
  - [<task id 1>] [<วันที่เวลา>] Note: <รายละเอียด>
  - [<task id 1>] [<วันที่เวลา>] Status: <รายละเอียด>
  - [<task id 2>] [<วันที่เวลา>] Note: <รายละเอียด>
- หลักฐาน: <ไฟล์/section/prototype/QA checklist ที่เกี่ยวข้อง>

### เป้าหมาย 2: <ชื่อเป้าหมาย>
- ...

**เปรียบเทียบกับแผน:**
- เวลาที่วางแผน: <X> ชม. | ใช้จริง: <Y> ชม. (จาก get_time_summary)
- เป้าหมายที่เสร็จตามแผน: <N>/<ทั้งหมด>
- เป้าหมายที่ยังค้าง: <รายการ>

**ผล Acceptance Criteria:**
- [ผ่าน/ไม่ผ่าน/รอตรวจ] <เงื่อนไขที่ 1>
- [ผ่าน/ไม่ผ่าน/รอตรวจ] <เงื่อนไขที่ 2>

**Evidence:**
- ไฟล์/ส่วนสำคัญที่แก้: <รายการ>
- Section/prototype ที่ตรวจ: <รายการ>
- ผล QA checklist/cross-reference: <ผลลัพธ์>
- Protected screens ที่กระทบ: <ไม่มี / ระบุ>
```

**Copy block (ก๊อปไปลงระบบอื่นได้เลย — ใส่น้ำหนัก/ชั่วโมง วางแผน vs ใช้จริง ครบ):**

```text
สรุปผล Mission: <ชื่อ Mission>
วันที่: <YYYY-MM-DD> - <YYYY-MM-DD>
งบประมาณชั่วโมงตามแผน (Baseline): <N×8> ชม.
จำนวนชั่วโมงทั้งหมดตามแผน: <X+Y+Z> ชม.
ใช้จริงรวม: <Y> ชม. (จาก get_time_summary)

[เป้าหมาย 1] <ชื่อเป้าหมาย> (น้ำหนัก <W1>% | วางแผน <X> ชม. | ใช้จริง <Y> ชม.)
- Service: <Service>
- Tasks:
  - <task id 1>
  - <task id 2>
- สถานะ: <เสร็จ / บางส่วน / ยังไม่ทำ / รอตรวจสอบ>
- รายละเอียดที่ทำ:
  - <สิ่งที่ทำจริง>
  - <ผลลัพธ์ที่ได้>
- log การทำงาน:
  - [<task id 1>] [<วันที่เวลา>] <ประเภท>: <รายละเอียด>
  - [<task id 2>] [<วันที่เวลา>] <ประเภท>: <รายละเอียด>
- หลักฐาน: <ไฟล์/section/prototype/QA checklist ที่เกี่ยวข้อง>

[เป้าหมาย 2] <ชื่อเป้าหมาย> (น้ำหนัก <W2>% | วางแผน <Y> ชม. | ใช้จริง <Z> ชม.)
- Service: <Service>
- Tasks:
  - <task id 3>
- สถานะ: <เสร็จ / บางส่วน / ยังไม่ทำ / รอตรวจสอบ>
- รายละเอียดที่ทำ:
  - <สิ่งที่ทำจริง>
  - <ผลลัพธ์ที่ได้>
- log การทำงาน:
  - [<task id 3>] [<วันที่เวลา>] <ประเภท>: <รายละเอียด>
- หลักฐาน: <ไฟล์/section/prototype/QA checklist ที่เกี่ยวข้อง>

น้ำหนักรวม: 100%
เสร็จตามแผน: <N>/<ทั้งหมด>
ค้าง: <รายการ>
```

## ตารางฟิลด์ copy block (แยกตามส่วน)

**กฎการใส่น้ำหนัก/ชั่วโมงใน copy block (แยกตามส่วน):**

| ส่วน | ฟิลด์ที่ต้องใส่ใน copy block |
|---|---|
| **ส่วนที่ 1 — หัวข้อ Mission** | Baseline (ชม.), จำนวนชั่วโมงทั้งหมดตามแผน, เหลือชั่วโมงให้วางแผน |
| **ส่วนที่ 1 — แต่ละเป้าหมาย** | น้ำหนัก (Weight %), ชั่วโมงที่คาดการณ์ของเป้าหมาย, ชั่วโมงแยกในแต่ละ Feature ย่อย (รวม ตรวจสอบ/แก้ไข ใน feature) |
| **Approved Mission Plan Summary** | Planned Duration, Mission Total Planned Hours, Objective Weight/Hours, Feature → Task mapping, Planned Hours ของแต่ละ Task และ Execution Sequence; ห้ามมี UUID |
| **Session Handoff** | Approved baseline, technical identifiers/context, scope/boundary, dependency, acceptance, risk/open items, protected scope, current state และ next-session instructions |
| **ส่วนที่ 2 — แต่ละเป้าหมาย** | น้ำหนัก (Weight %), เวลาที่วางแผน, ใช้จริง (จาก get_time_summary) |
| **ส่วนที่ 2 — ท้ายสรุป** | รวมเวลาวางแผน vs ใช้จริงทั้ง Mission |

> **ข้อยกเว้น:** copy block ของรายละเอียด task DONE (รายการ Activity timeline ของ task เดี่ยว ๆ ในขั้นตอนที่ 2 ของส่วนที่ 1) ยังคง **ไม่ใส่จำนวนชั่วโมง** เพราะชั่วโมงใน task นั้นเป็นข้อมูลวิเคราะห์ภายในจาก Kanban ไม่ใช่ชั่วโมงประเมินของแผน
