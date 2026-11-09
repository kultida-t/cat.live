# mission-planning — Rules & Data Detail (references/rules-detail.md)

> ไฟล์นี้เก็บกฎและรายละเอียดเชิงลึกของ skill mission-planning — อ่านตาม pointer จาก SKILL.md เมื่อถึงขั้นตอนที่เกี่ยวข้อง

### กติกา Mission → Objective → Feature → Task และ Work Log (บังคับ)

- **ตอบคำถามโครงสร้าง Mission จาก record เท่านั้น** — เมื่อผู้ใช้ถามว่า Mission มีเป้าหมาย/Feature/Task อะไรบ้าง ให้เรียก `get_mission` (หรือ `get_task`) แล้วตอบตาม baseline จริง โดยแสดงชื่อ Objective/Feature เป็น label ตามที่ล็อกไว้ (เช่น `Feature: My Account`) ห้ามตอบจากความจำ/context หรือเขียนเป็นคำอธิบายพฤติกรรมแทนชื่อ Feature
- **Mission** คือภาพรวมและ baseline ของงานทั้งก้อน
- **Objective** คือผลลัพธ์หลักของ Mission
- **Feature** คือผลลัพธ์ย่อยที่อยู่ใต้ Objective ใช้เป็นหน่วยเลือกตอนลง work log และต้องคงอยู่เพื่อวัด Planning Accuracy
- **Task** คือหน่วยงานปฏิบัติที่แตกละเอียดเพื่อทำจริง ผู้ใช้สั่งทำทีละ Task และทุก Task ต้อง map กับ Objective และ Feature ที่จะใช้ลง work log
- หนึ่ง Feature map กับหลาย Task ได้ และหนึ่ง Feature มี work log ได้หลายรายการ โดยแต่ละ log เกิดจาก Task ที่ปิดพร้อมสรุปแล้ว ไม่ใช่ log ความคืบหน้าย่อยระหว่างทำ Task เดียว
- Workflow: วาง Mission และ Feature → แตก Task ที่ต้องทำจริง → ทำทีละ Task → สรุปและปิด Task → เตรียม work log ของ Task โดยเลือก Objective และ Feature ที่ map ไว้
- **วางเป้าหมายให้ตรงกับ "หนึ่งชุดหลักฐานส่งตรวจ" (Continuous Evidence Planning)** — ฟอร์มส่งตรวจรับคิดหลักฐานต่อ 1 เป้าหมาย (ไฟล์แนบ + คำอธิบาย) ดังนั้นเป้าหมายที่ผลิตหลักฐานคนละประเภท (เอกสาร spec vs ภาพหน้าจอ UI vs test/verification) ควรเป็นเป้าหมายแยกกัน; และต้องกำหนด **Evidence Plan** ประจำแต่ละ Objective ตั้งแต่ตอนวางแผน เพื่อให้ระหว่างทำแต่ละ Task สามารถเก็บหลักฐานคู่ขนานแบบ Real-time ได้ทันที:
  - *เป้าหมาย UI/Prototype:* วางแผนแคปภาพ Before (1440/390px) ก่อนแก้โค้ด และภาพ After (1440/390px) หลังแก้โค้ดที่ผู้ใช้ยืนยันคอนเฟิร์มว่าโอเคผ่านเรียบร้อย
  - *เป้าหมาย Test/Verification:* วางแผนไฟล์ `.spec.js` เป้าหมาย และกำหนดชื่อไฟล์บันทึก Raw runner output ดิบ (`test-results.txt`) จาก runner engine จริง + **วางแผนหลักฐานภาพตั้งแต่ต้น** — เก็บ `playwright-report/` และแคปภาพ HTML report dashboard หลังรัน, ระบุ flow dynamic (countdown, error live, focus trap) ที่ต้องแคปภาพ/screencast ระหว่างเทสต์, เตรียม triage note สำหรับเคส skipped/blocked และตัดสินใจ scope accessibility ในแผน (ถ้าครอบ contrast/focus/aria ต้องวาง direct assertion เช่น axe-core ไว้ตั้งแต่ต้น)
  - *เป้าหมาย Document/Acceptance:* วางแผน checklist file `.txt`, เรนเดอร์ Checklist Card PNG และ Git commit hashes ของเอกสารที่แก้
  - เป้าหมายล้วน UI ให้แยกตามฝั่งผู้ใช้/flow (เช่น ฝั่ง admin กับฝั่งผู้รับ) ไม่ใช่รวมทุกจอไว้เป้าหมายเดียว; และอย่าแตกเป้าหมายยิบย่อยจน submission กระจายเป็นรายการที่บอกอะไรไม่ได้ — 1 เป้าหมายมี 1 Task ได้ถ้า deliverable เป็นคนละชนิด
- หลังเริ่ม Mission ห้ามลบ Objective หรือ Feature จาก baseline หาก Task ไม่จำเป็นต้องทำแล้ว ให้บันทึกเป็น Scope Change/ยกเลิกพร้อมเหตุผล และคง Feature ไว้เพื่อให้ความแม่นยำของแผนไม่หายไป
- หลีกเลี่ยงการลบ Task หลังเริ่มทำ ให้ใช้สถานะยกเลิกหรือบันทึกเหตุผลแทน ทั้งนี้ Task ที่ยกเลิกไม่ลบ Feature หรือ work log ที่เกี่ยวข้อง
- ประเมินเวลาตามเวลา AI ทำงานเป็นหลัก รวมเวลา AI วิเคราะห์ สร้าง แก้ และตรวจรับตามขอบเขตงาน
- **วางแผนให้ตอบโจทย์การประเมินผลงาน (Evaluation Alignment):** ทุกหน่วยงานต้อง map เป็น Kanban task ที่จับเวลาได้ — ชั่วโมงถูกนับในระบบประเมินเฉพาะงานที่อยู่ใน task ที่ `in_progress` (งานนอก task = ชั่วโมงไม่เข้าระบบ); task size ต้องอยู่ในเกณฑ์หมวดเพื่อรักษา Planning Accuracy; และทุกเป้าหมายต้องออกแบบให้ผลิต "ชุดหลักฐานที่ reviewer ตรวจได้" (ภาพ/ไฟล์/log ตาม `submission-evidence`) — เป้าหมายที่ทำเสร็จแต่ไม่มีหลักฐานพร้อมตรวจจะค้างรอ review
- ใช้ copy block เฉพาะ Mission Plan, Mission Plan Summary, Session Handoff, Work Summary และ Task Summary ที่ผู้ใช้ต้องนำไปวางระบบอื่น; คำตอบคุยงานทั่วไปตอบตามปกติ

### กฎการตั้งชื่อ Objective และ Feature (Naming Rules — บังคับ)

- **ชื่อ Objective/Feature คือ label ไม่ใช่ description** — ต้องสั้น กระชับ อ่านแล้วรู้ว่าเป็น work area / capability / outcome area อะไร และเหมาะกับการแสดงใน Mission Plan, Kanban และ Work Log
- **ห้ามยัดเนื้อหาเชิงอธิบายลงในชื่อ** — ห้ามใส่ scope, behavior list, business rules, validation, implementation details, technical steps, Acceptance Criteria, Definition of Done, dependencies หรือ security rules ในชื่อ Objective/Feature; เนื้อหาเหล่านั้นต้องอยู่ใน Description, Scope, Requirement, Acceptance Criteria, DoD หรือ Notes
- **เลือกภาษาตามความชัดเจน ไม่บังคับล้วนไทย** — ใช้ไทยหรืออังกฤษตามคำที่เข้าใจง่ายกว่า เป็น terminology ที่ทีมใช้จริง สั้นและชัดกว่า; คำมาตรฐานเช่น `My Account`, `Change Password`, `Active Sessions`, `Logout All Devices`, `Session Expired`, `Forgot Password`, `Reset Password`, `Password Recovery`, `Regression`, `Accessibility`, `Final Acceptance` ใช้ภาษาอังกฤษโดยตรงได้ ห้ามแปลเป็นไทยเพียงเพื่อให้ชื่อเป็นไทยทั้งหมดจนแปลก ยาว หรือเข้าใจยากกว่า
- **Objective = ชื่อของ goal / workstream / outcome area** — เช่น `Credential Security Contract`, `My Account & Self-Service`, `Targeted Verification`; ข้อความยาวเช่น `สร้างหน้า My Account ให้แก้ชื่อ เปลี่ยนรหัสผ่าน ดู sessions และออกจากทุกอุปกรณ์ได้` เป็น Description/Scope ไม่ใช่ชื่อ Objective
- **Feature = ชื่อของ capability / screen / flow / functional area / contract area / verification area** — เช่น `My Account`, `Change Password`, `Logout All Devices`, `Scoped Regression`; ห้ามต่อ scope ต่อท้ายชื่อ เช่น `Logout All Devices (confirmation + revoke ทุก session รวม current + audit + กลับ Login)` ให้ใช้เพียง `Logout All Devices` แล้วเก็บรายละเอียดไว้ใน Scope/AC
- **Feature ไม่ใช่ Task** — Feature คือ grouping ของ capability/work area ส่วน Task คือ execution unit; 1 Feature map กับหลาย Task ได้ (เช่น Feature `Scoped Regression` → `AIL-029a` + `AIL-029b`) และห้าม merge Task เพียงเพื่อให้ตรงกับ Feature
- **Naming cleanup ห้ามกระทบ decomposition** — การปรับชื่อ Objective/Feature ห้าม merge หรือ split Task, เปลี่ยน Task Code, Task Name, Category, Planned Hours, dependencies, execution order, Scope หรือ Acceptance Criteria และห้ามเปลี่ยนจำนวน planned tasks
- **Mission Plan Summary ใช้ชื่อ label เท่านั้น** — แสดง `Objective: <short name>` และ `Feature: <short name>` แล้วตามด้วย Tasks ใต้ Feature นั้น; ห้ามเขียน `Feature: <name> (<scope/behavior ยาว ๆ>)` — ถ้าต้องอธิบาย Feature ให้ใช้ field แยก เช่น `Scope: ...`

## MCP Call Signatures (canonical — ใช้ตัวเดียวกันทั้ง 2 ส่วน)

```
# ดูเครื่องมือทั้งหมดก่อน (ทุกครั้ง)
mcp_list_tools(server_name="kanban-tukdaeng")

# resume context ของ session (ส่วนที่ 1 เรียกก่อนเสมอ)
mcp_call_tool(server_name="kanban-tukdaeng", tool_name="get_session_context", arguments={})

# ดู board ปัจจุบัน (task ที่อยู่ใน todo/in_progress/done)
mcp_call_tool(server_name="kanban-tukdaeng", tool_name="get_board", arguments={})

# สรุปชั่วโมงทำงานของ task DONE วันนี้/ช่วงที่ต้องการ
mcp_call_tool(
  server_name="kanban-tukdaeng",
  tool_name="get_time_summary",
  arguments={
    "date": "<YYYY-MM-DD>",   # วันที่ต้องการสรุป (default: วันนี้ tz Asia/Bangkok)
    "tz": "Asia/Bangkok",
    "status": "done"
  }
)

# ดึงรายละเอียดเต็ม + Activity timeline ของ task เฉพาะ
mcp_call_tool(
  server_name="kanban-tukdaeng",
  tool_name="get_task",
  arguments={"task_id": "<task id>"}
)
```

**ใช้ข้อมูลที่ได้เพื่อ:**
- เข้าใจงานที่ค้างไว้ (todo/in_progress) จาก `get_board`
- เข้าใจประวัติ/session ก่อน ๆ จาก `get_session_context`
- เข้าใจชั่วโมงที่ใช้ไปแล้วจาก `get_time_summary` (เพื่อประเมินเวลาที่เหลือในวัน/สัปดาห์)

> **แนะนำ:** ในส่วนที่ 1 (วางแผน) ให้เรียก `get_session_context` ก่อนเสมอเพื่อ resume session แล้วค่อยเรียก `get_board`/`get_time_summary` เสริมตามต้องการ

**ส่วนที่ 2 ใช้ signature ชุดเดียวกัน** (ตัด `get_session_context` ได้ถ้า context session ปัจจุบันพอแล้ว) — ใช้ข้อมูลที่ได้เพื่อ:

- เห็น task ที่ทำเสร็จ (DONE) และยังค้าง (in_progress/todo) จาก `get_board`
- เห็นชั่วโมงที่ใช้จริงจาก `get_time_summary` (เปรียบเทียบกับแผนในส่วนที่ 1)
- ถ้ามีส่วน `analysis` ใน `get_time_summary` flag task ที่ชั่วโมงต่ำเกินไป → แสดงให้ผู้ใช้เห็น
- เปรียบเทียบ task จริงกับ Scope, Acceptance Criteria และ Mapping ที่วางไว้
- ใช้ Description และ Activity timeline จาก `get_task` เป็นแหล่งข้อมูลหลักในการสรุปว่าทำอะไรลงไปจริง

### ขั้น 2: ดึงรายละเอียดของ task ที่ทำเสร็จแล้ว — กฎการรวบรวม

เมื่อ `get_board` พบ task ที่อยู่ใน `done` และเกี่ยวข้องกับ Mission ที่กำลังวางแผน ต้องเรียก `get_task` แยกทุก task เพื่ออ่านรายละเอียดเต็ม:

```
mcp_call_tool(
  server_name="kanban-tukdaeng",
  tool_name="get_task",
  arguments={"task_id": "<task id>"}
)
```

จากผลลัพธ์ `get_task` ให้รวบรวมและแสดง:
- ชื่อ task, task ID, Service/กลุ่ม และสถานะ
- รายละเอียดงานจาก `Description` ว่าทำอะไรลงไปบ้าง
- Activity timeline ทุกเหตุการณ์ที่ระบบส่งกลับมา โดยแยกประเภทเป็น `note`, `status` และ `time`
- วันที่/เวลาที่เกี่ยวข้องกับการทำงาน
- Dependency หรือ task ก่อนหน้าที่ task นี้อ้างถึง

**กฎการแสดง Activity timeline:**
- แสดงตามลำดับเวลาจากเก่าไปใหม่ เพื่อให้เห็นลำดับการทำงาน
- แยกเป็นรายการย่อย อ่านง่าย และคงข้อความจากระบบตามจริง
- ห้ามสรุปเกินข้อมูลที่ `get_task` ส่งกลับมา
- ถ้าไม่มี Activity timeline หรือมีเฉพาะ time event ให้ระบุว่าไม่มี note/status event เพิ่มเติม
- ชั่วโมงใน task ใช้เพื่อการวิเคราะห์ภายในเท่านั้น และห้ามใส่ใน Copy block

> หากมี task DONE หลายรายการ ให้แสดงรายละเอียดแยกทุก task และรวมไว้ใน Copy block เดียวหรือแยกตาม Service ได้ โดยไม่ใส่จำนวนชั่วโมง
>
> **การใช้ task DONE ในส่วนวางแผน:** รายละเอียด task DONE ใช้เป็น context สำหรับเข้าใจงานเดิมและ dependency เท่านั้น ห้ามนำสถานะ, ผลลัพธ์, Evidence หรือ bug ที่พบจาก task DONE ไปเขียนปนใน Mission Plan ใหม่ เว้นแต่ผู้ใช้ขอให้สรุปเป็น Work Summary

### ขั้น 3: คิด Mission + จำนวนวัน + เป้าหมายย่อย — กฎ

วิเคราะห์จากข้อมูล kanban + session context ปัจจุบัน แล้วคิด Mission:

- **Mission** = แผนงานระดับหนึ่ง (ไม่ใช่ task เล็ก ๆ 1 อัน)
- **จำนวนวัน:** ขั้นต่ำ **1 วัน** ไม่เกิน **5 วัน** ต่อ Mission
- ถ้างานดูจะเกิน 5 วัน → แบ่งเป็นหลาย Mission
- **เป้าหมายย่อย (Objectives):** แบ่ง Mission ออกเป็นเป้าหมายย่อย **1-5 ข้อตามความเหมาะสม** — Mission เล็กหรือส่งมอบผลลัพธ์เดียวมีเป้าหมายเดียวได้ ไม่ต้องฝืนแตกหลายข้อ; แยกเป้าหมายเมื่อ deliverable/ประเภทหลักฐานต่างกัน (ดู Continuous Evidence Planning) และอย่าแตกยิบย่อยเกินความจำเป็น แต่ละเป้าหมายเป็นผลลัพธ์หลักของ Mission และ map กับ Feature/Task ที่ใช้ลง work log ได้

> **การวางแผน Mission เป็นขั้นตอนก่อนสร้าง Mission ไม่ใช่ Objective บังคับของทุก Mission:**
> ให้คุยความต้องการ กำหนด scope, Acceptance Criteria และ mapping กับ Kanban ก่อนสร้างแผนได้ แต่ไม่ต้องสร้าง Objective ชื่อ "เป้าหมายการวางแผน mission"
>
> **Planning Task กับ Mission Objective เป็นคนละเรื่อง:** ถ้าผู้ใช้กำหนดให้วางแผนผ่าน Planning Task (เช่น `M3P-001`) หรือมี standing workflow ให้เก็บเวลางานวางแผน ต้องสร้าง Planning Task **ก่อนเริ่มอ่าน context เชิงงาน/วิเคราะห์/ร่างแผน** แล้วใช้ workflow ปกติ `create_task → move_task(in_progress) → วางแผน → รอผู้ใช้อนุมัติ baseline → move_task(done)` Planning Task ไม่ถูกนับเป็น Objective/Feature/execution task ของ Mission แต่ยังเป็นงานจริงที่ต้องจับเวลาด้วย auto-timer
>
> **ห้ามปิด Planning Task จาก `todo → done` โดยตรง** เว้นแต่ผู้ใช้สั่งชัดเจนว่าไม่ต้องจับเวลา Planning Task กรณีพบคำสั่งว่า “ห้ามเริ่ม timer / ห้ามย้าย Task เป็น in_progress ก่อน approval” ให้ตีความว่าใช้กับ **Mission execution task** เท่านั้น ไม่ใช้กับ Planning Task ที่มีไว้รองรับงานวางแผนรอบนั้น หากถ้อยคำยังคลุมเครือ ให้แยกคำว่า Planning Task กับ execution task ให้ชัดก่อนลงมือ ห้ามปล่อยให้งานวางแผนเกิดนอก `in_progress`
>
> Objective ของ Mission ต้องเป็นผลลัพธ์ที่ส่งมอบจริง เช่น ปรับหน้ารายการ, สร้าง detail, เพิ่ม filter, sync spec หรือ QA ไม่ใช่งานบริหารแผนที่เกิดขึ้นก่อนเริ่ม Mission

### ขั้น 6: กฎการกรอก Feature ย่อย / Weight / ประเมินเวลา

> **หมายเหตุ:** Objective และ Feature ใน Mission Plan ต้องเขียนเป็นงานที่วางแผนจะทำและผลลัพธ์ที่คาดหวัง ห้ามเขียนสถานะหรือผลการตรวจที่เกิดขึ้นแล้ว การวางแผน Mission เป็นขั้นตอนเตรียมแผนและไม่ต้องนับเป็น Objective แยก เว้นแต่ผู้ใช้ระบุเป็น deliverable

Services ที่ใช้ใน TukDaeng:
- **BackOffice (BO)** — เอกสาร spec ของระบบ admin (markdown modules, baseline, version)
- **FrontOffice (FO)** — เอกสาร spec ของระบบผู้ใช้ (markdown modules, PRD, handoff)
- **Prototypes** — prototype screen ของ BO (HTML, assets, mock data)


**กฎการกรอก Feature ย่อย (บังคับ):**

1. **Tasks เป็นลิสข้อ ๆ ลงมา** — ไม่ใช่ `,` หรือ `+` คั่นบรรทัดเดียว
2. **รายละเอียดของ Objective ไม่ใส่ชั่วโมง** — เวลารวมอยู่ใน Feature ย่อยแล้ว
3. **Feature ย่อยต้องเป็นผลลัพธ์ย่อยของ Objective** — เขียนเป็นภาษาที่เข้าใจง่ายและไม่แตกละเอียดเกินความจำเป็น
4. **หนึ่ง Feature สามารถ map กับหลาย Task ได้** — รวม Task ที่ทำเพื่อผลลัพธ์เดียวกันไว้ใต้ Feature เดียวกันได้
5. **Feature เป็นหน่วยสำหรับ work log** — เมื่อปิด Task ให้สร้าง/เตรียม log ของ Task นั้นโดยเลือก Objective และ Feature ที่ map ไว้; Feature เดียวมี log จากหลาย Task ได้
6. **ไม่ต้องสร้าง Feature ให้เท่ากับจำนวน Task (ป้องกัน No-Log Feature)** — **ห้ามแตก Feature ยิบย่อยแบบ 1 Feature : 1 Micro-task** เพราะหาก Task นั้นถูกยกเลิกภายหลัง (เช่น โค้ดเดิมรองรับอยู่แล้ว หรือมีมติตัด Scope) จะทำให้ Feature นั้นค้างอยู่ในระบบโดยไม่มี Task มาลง Work Log ให้แตก Feature เป็นกลุ่มผลลัพธ์/Capability Area ที่ครอบคลุมแทน
7. **ถ้า Objective มี 1 Task และ 1 log** → ใช้ Feature เดียวได้
8. **ถ้า Objective มีหลาย Task ที่ทำเพื่อผลลัพธ์เดียวกัน** → รวมไว้ใน Feature เดียว แล้วแสดง Task ที่เกี่ยวข้องเป็นรายการย่อย
9. **การจัดการเมื่อ Task ถูกยกเลิก หรือ Feature ไม่มีงานต้องทำจริง (Scope Change Protocol):**
   - หาก Task ใดไม่จำเป็นต้องทำแล้ว ไม่ต้องลบ Feature ออกจาก Approved Baseline เพื่อรักษาความถูกต้องของแผน
   - ให้บันทึกเป็น **Scope Change / Decision Log** ใน Work Summary ระบุว่า:
     `[Scope Change] Feature <ชื่อ Feature>: ยกเลิก Task <Task Code> เนื่องจาก <เหตุผล เช่น โค้ดเดิมรองรับอยู่แล้ว / ตัด Scope ออกตามมติ> — ไม่มีชั่วโมง Work Log บันทึก`
   - วิธีนี้ช่วยรักษา Planning Accuracy และทำให้ผู้ตรวจเข้าใจว่าทำไม Feature นี้จึงไม่มี Task/ชั่วโมงลง
10. **ตรวจสอบ/แก้ไขให้ใส่ในระดับ Feature** — ไม่ต้องเขียนซ้ำทุก Task และไม่ต้องสร้าง Task ตรวจสอบ/แก้ไขแยก เว้นแต่เป็นงานใหญ่ที่ต้องติดตามแยก
11. **ตรวจสอบ/แก้ไขใช้ `()` ครอบเวลา** เช่น `สร้างตาราง + ตรวจสอบ (0.25) + แก้ไขตามผลตรวจ (0.25) (2.5 ชม.)`
12. **รวมเวลา Objective = ผลรวมเวลาของ Feature ย่อย** — ผลรวมทุก Feature ต้องเท่ากับชั่วโมงที่คาดการณ์ของ Objective
13. **ห้ามเขียนผลลัพธ์ย้อนหลังใน Mission Plan** — ใช้คำว่า `วางแผนตรวจสอบ` และ `แก้ไขตามผลตรวจ` แทนการระบุ bug หรือผล QA ที่ยังไม่เกิด

**กฎเรื่องน้ำหนัก (Weight) — ตามฟอร์ม Create Mission:**
- น้ำหนักของทุกเป้าหมายรวมกัน **ต้องเท่ากับ 100%** เสมอ (ระบบเฉลี่ยอัตโนมัติถ้าไม่กำหนด แต่แนะนำให้กำหนดเองตามความสำคัญ/ปริมาณงานจริง)
- เป้าหมายที่ใช้เวลา/มีผลกระทบมากกว่าควรได้น้ำหนักสูงกว่า — ใช้สัดส่วน **ชั่วโมงที่คาดการณ์ของเป้าหมาย ÷ Total Planned Hours** เป็นฐานในการคำนวณน้ำหนัก แล้วปรับตามความสำคัญเชิงธุรกิจได้
- ถ้าปรับน้ำหนักเป้าหมายใดหลังตั้งค่าแล้ว ต้องปรับเป้าหมายอื่นให้ผลรวมยังคง 100%
- แสดงน้ำหนักในสรุปทุกครั้งที่มีเป้าหมายมากกว่า 1 ข้อ

**Feature ย่อย (Feature Detail) — ใช้แตกเป้าหมายใหญ่เป็นงานย่อยที่ทำได้จริง:**
- แต่ละเป้าหมายสามารถมี Feature ย่อยได้หลายรายการ (เช่น "ออกแบบฐานข้อมูล", "เขียน API", "สร้าง UI Table")
- Feature ย่อยคือรายละเอียดงานภายในเป้าหมาย ไม่ใช่ Kanban task แยก — ใช้เพื่อกระจายงานใหญ่ให้เห็นภาพรวมและช่วยประเมินเวลาได้แม่นยำขึ้น
- ถ้า Feature ย่อยรายการใดมีขนาดใหญ่พอที่จะติดตามแยก ให้พิจารณา map เป็น Kanban task ของตัวเองภายใต้เป้าหมายเดียวกัน

**บทบาท AI vs คน (สำคัญ — มีผลต่อการประเมินเวลา):**

การทำงานในทีม TukDaeng ปัจจุบัน **เน้นใช้ AI ทำงานเป็นหลัก** มนุษย์มีบทบาทเป็นผู้ตรวจสอบและทดสอบ ไม่ใช่ผู้ทำงานหลัก:

| บทบาท | ผู้ทำ | หน้าที่ |
|---|---|---|
| เขียนเอกสาร / แก้เอกสาร spec / แก้ prototype | **AI** | สร้าง/แก้ไขเอกสารหรือ prototype ตามแผน |
| ออกแบบ / วิเคราะห์ / วางแผน | **AI** (เสนอ) + มนุษย์ (ตัดสินใจ) | AI เสนอทาง มนุษย์ยืนยัน |
| ตรวจสอบเอกสาร (review spec) | **มนุษย์** | อ่าน/ตรวจผลลัพธ์ที่ AI ทำ |
| ตรวจสอบ prototype (review UI, เทียบกับ spec) | **มนุษย์** (เป็นหลัก) + AI (ช่วยเตรียม) | มนุษย์ตรวจจริง AI เตรียม checklist |
| แก้ไข / แก้บั๊ก prototype | **AI** (ทำ) + มนุษย์ (ยืนยัน) | AI แก้ มนุษย์ตรวจว่าแก้ถูก |

**ผลต่อการประเมินเวลา:**
- อย่าประเมินเวลาแบบ "คนทำเองทั้งหมด" — จะต่ำเกินไปหรือสูงเกินไปไม่สมจริง
- **งานที่ AI ทำ** (เขียน/แก้เอกสาร, แก้ prototype, สร้างไฟล์) → ประเมินเวลา **น้อยกว่าคนทำเอง** เพราะ AI เร็วกว่า
- **งานที่มนุษย์ทำ** (review spec, ตรวจ prototype, เทียบ spec กับ prototype) → ประเมินตามเวลาจริงของมนุษย์ ไม่ลด
- **งานตรวจสอบ/แก้ไข** → ส่วนใหญ่มนุษย์ตรวจ + AI แก้ → ประเมินรวมทั้ง 2 ส่วน

**กฎการประเมินเวลา:**
- **1 วัน = 8 ชั่วโมงทำงาน** (เวลาทำงานจริงของมนุษย์ในการตรวจสอบ + ทดสอบ + ดูแล AI)
- **งบประมาณชั่วโมงตามแผน (Baseline) = Total Planned Hours เสมอ** — Baseline อิงตามชั่วโมงที่ใส่ ไม่ใช่ Days × 8 โดยตรง
  - ถ้าผู้ใช้ใส่ Total เอง → Total = ค่าที่ใส่, Baseline = Total
  - ถ้าผู้ใช้ไม่ใส่ Total → Total = จำนวนวันใน Mission × 8 ชม. (วันละ 8 ชม. อัตโนมัติ), Baseline = Total
- รวมเวลาของทุกเป้าหมาย (Total Planned Hours) ประเมินตามความจริง (36, 38, 40 ฯลฯ) — Baseline จะปรับตาม Total เสมอ
- **เหลือชั่วโมงให้วางแผน = Baseline − Total = 0 เสมอ** (เพราะ Baseline = Total)
- ประเมินเวลาแต่ละเป้าหมายเป็นชั่วโมง (ทศนิยมได้ เช่น 1.5, 2.25)
- **Planned ต้องประเมินจาก workflow ที่ใช้ AI ทำงานจริง** — รวมเวลาทำงานของ AI และเวลาที่คนใช้ตรวจ/ทดสอบ/ตัดสินใจจริงตาม scope; ไม่ประเมินเสมือนคนทำ implementation เองทั้งหมด และไม่บวก buffer หรือเวลาว่างที่ไม่ได้เป็นงานจริง (เวลารอผู้ใช้ตรวจตาม review gate ให้นับตามกฎใน work-summary)
- `Planned` ต้องเป็นการประเมินตาม scope จริง ไม่บวก buffer หรือกด/เพิ่มตัวเลขเพื่อหลบ Review; หลังทำงานให้สรุปเวลาจริงจาก `hours_spent` ใน Kanban เท่านั้น ห้ามเติมเวลาเอง

**ตารางเวลามาตรฐานตามหมวดหมู่งาน (บังคับ):**

ตัวเลขในตารางนี้เป็น **เพดานอ้างอิงต่อ task สำหรับประเมิน scope และป้องกันการติด Review ไม่ใช่เวลาที่ต้องใส่ให้ครบ**: ประเมิน Planned ตามงานจริง โดยใช้เวลาทำงาน AI และเวลาตรวจ/ตัดสินใจของคนเฉพาะที่เกิดขึ้นจริง; ถ้างานใช้เวลาน้อยกว่าเพดานให้ใช้ค่าที่ต่ำกว่าตามจริง ไม่เติมให้ถึงเป้าหมาย หากประเมินว่า task จะถึงหรือเกินเพดาน ให้แบ่งเป็น task ย่อยที่มี scope/ผลส่งมอบจริงก่อนเริ่มงาน ส่วน Time Ratio > 1.5 ให้ยึดสถานะที่ระบบรายงาน และห้ามคูณเป้าหมายในตารางเพิ่ม:

| หมวดหมู่งาน | เป้าหมาย / เกณฑ์ Review โดยตรง | กฎการแตก subtask |
|---|---|---|
| Requirement | 2 ชม. | ถ้า Planned ถึงหรือเกิน 2 ชม. → ทบทวน scope และแตกเป็น subtask |
| Design | 1.5 ชม. | ถ้า Planned ถึงหรือเกิน 1.5 ชม. → ทบทวน scope และแตกเป็น subtask |
| Feature | 2 ชม. | ถ้า Planned ถึงหรือเกิน 2 ชม. → ทบทวน scope และแตกเป็น subtask |
| Bug Fix | 2 ชม. | ถ้า Planned ถึงหรือเกิน 2 ชม. → ทบทวน scope และแตกเป็น subtask |
| Testing | 1 ชม. | ถ้า Planned ถึงหรือเกิน 1 ชม. → ทบทวน scope และแตกเป็น subtask |
| Refactor | 1.5 ชม. | ถ้า Planned ถึงหรือเกิน 1.5 ชม. → ทบทวน scope และแตกเป็น subtask |
| Documentation | 2 ชม. | ถ้า Planned ถึงหรือเกิน 2 ชม. → ทบทวน scope และแตกเป็น subtask |
| Deploy / DevOps | 1 ชม. | ถ้า Planned ถึงหรือเกิน 1 ชม. → ทบทวน scope และแตกเป็น subtask |
| Meeting | 2 ชม. | ถ้า Planned ถึงหรือเกิน 2 ชม. → ทบทวน scope และแตกเป็น subtask |

**กฎการใช้ตาราง:**
- ระบุหมวดหมู่งานของแต่ละ task ก่อนประเมินเวลา (เลือกจากตาราง 9 หมวดใน work-summary skill)
- ประเมินเวลา task ตามหมวดหมู่ — ถ้า task มีหลายหมวดผสมกัน ให้ใช้หมวดที่ครอบคลุมงานหลัก
- **ถ้า Planned ของ task ถึงหรือเกินเพดานหมวด → ทบทวน scope และแตกเป็น subtask ที่มีผลส่งมอบแยกจริงก่อนเริ่มงาน** โดยไม่ลด Planned ให้ต่ำกว่าความจริง; ถ้า scope ใช้เวลาน้อยกว่าเพดานให้ใส่ Planned ตามจริง ไม่ต้องตั้งให้เท่าค่าเป้าหมาย
- หลังปิด task ให้ใช้ Final `hours_spent` จาก Kanban ตามจริง; หากถึงหรือเกินเพดานให้แจ้งตามข้อมูลจริงและสถานะ Review ของระบบ ห้ามตัดหรือย้ายชั่วโมงย้อนหลังเพื่อให้ไม่เกิน; หากระบบแสดง Time Ratio > 1.5 ให้รายงานสถานะตามระบบ และห้ามใช้ ratio นี้คูณเพิ่มเป้าหมายในตาราง
- เวลาของ task รวมทั้ง "ทำ" และ "ตรวจสอบ" — ถ้าตรวจสอบเพิ่มเติมทำให้เกิน ต้องแตก subtask ตรวจสอบแยก
- เวลาของ parent task อาจเป็นยอดรวมที่ระบบบันทึกจาก subtask หรือเป็นเวลาของ parent เอง ต้องตรวจ Description/Activity timeline ก่อนใช้
- ห้ามบวกชั่วโมงของ parent กับ subtask ซ้ำกันใน Mission หรือ Work Summary — ให้เลือกยอด parent หรือรวมเฉพาะ subtask อย่างใดอย่างหนึ่ง

**การประเมินชั่วโมงตามความจริง (Baseline = Total เสมอ):**
- **Total Planned Hours = ชั่วโมงที่ประเมินว่างานจริงใช้** — ปรับได้ตามความเป็นจริง (36, 38, 40 ฯลฯ)
- **Baseline = Total เสมอ** — Baseline อิงตามชั่วโมงที่ใส่ ไม่ใช่ Days × 8 โดยตรง
- ตัวอย่าง: งานประเมินจริง 4.5 วัน = 36 ชม. → ใส่ Total = 36 → Baseline = 36, เหลือ = 0
- ตัวอย่าง: ไม่ใส่ Total, Days = 5 → Total = 40 (5 × 8), Baseline = 40, เหลือ = 0
- ถ้าหลังแบ่งเป้าหมายแล้ว Total เกิน Days × 8 → ต้องลดเวลาเป้าหมาย หรือรวมเป้าหมายเล็กเข้าด้วยกัน หรือเพิ่มจำนวนวัน หรือแบ่งเป็น Mission ใหม่
- **คะแนนความแม่นยำในการวางแผน** เทียบ **Total Planned Hours กับชั่วโมงจริงที่ใช้** — ถ้าทำตรงตาม Total Planned Hours จะได้คะแนนเต็ม 100 ถ้าเบี่ยงเบือน (task เกินเวลา, งานนอกแผน) คะแนนจะถูกหัก
- **แนวทางป้องกันงานเกินเวลา (Improvement & Over-Budget Prevention):**
  1. **วิเคราะห์ความซับซ้อนของ Logic ตั้งแต่ต้น (Complexity Discovery):** หากงานมีเงื่อนไขหลายชั้น (เช่น Cooldown, Rolling Quota, Stale Revision, Denial Reasons หลายแบบ หรือ Rollback ข้ามหลาย Store) **ห้ามวางเป็น 1 Task ใหญ่เด็ดขาด** ต้องแตกเป็น Subtask ตามหมวดงาน โดย Planned ของแต่ละ task ไม่ควรถึงหรือเกินเป้าหมายหมวด และวางแผนสร้างฟังก์ชันตรวจเงื่อนไขตรงกลางตั้งแต่แรก
  2. **รองรับความผันผวนของความเร็ว AI (AI Latency & Large Context Overhead):** ในช่วงที่ AI ประมวลผลช้าหรือโปรเจกต์มี Context ขนาดใหญ่ Task ขนาดใหญ่จะมีความเสี่ยงสูงที่จะเกินเวลา การแตก Task ให้เล็กและโฟกัสทีละจุด จะช่วยให้ AI ประมวลผลได้แม่นยำ ไม่หลุด Scope และเสร็จตามเวลาที่วางแผนไว้
  3. **ความเสี่ยง:** ถ้า task ใดเกินเวลา รวมจะเกิน Total Planned Hours ทันที — กรณีนี้ให้ใช้กฎ "ชี้แจงเวลาเกินงบ" ใน work-summary skill (แตกรายละเอียดงานเป็นส่วนย่อย + บล็อกชี้แจง) แทนการกัน buffer ไว้ล่วงหน้า

### ขั้น 7-8: Dependency / Risk

#### 7. วิเคราะห์ Dependency และลำดับงาน

สำหรับแต่ละแผนให้ระบุ:
- งานที่ต้องทำก่อน
- งานที่รอ Service หรือ API อื่น
- งานที่ทำขนานกันได้
- งานที่อยู่บน critical path และมีผลต่อวันเสร็จของ Mission

ลำดับทั่วไปที่ควรพิจารณา:

```
PRD / ความต้องการ → Module spec (BO/FO) → Prototype → Review/QA → Handoff/Baseline update
```

หากลำดับจริงแตกต่างจากนี้ ให้ระบุเหตุผลในแผน และห้ามนับงานที่ยังเริ่มไม่ได้เป็นงานที่ทำเสร็จแล้ว

#### 8. วิเคราะห์ Risk และแผนรับมือ

อย่างน้อยต้องระบุความเสี่ยงที่สำคัญ 2-3 รายการ เช่น:
- การแก้ prototype กระทบ protected screens (ต้องหยุดและขออนุมัติก่อนแก้)
- เอกสาร spec กับ prototype ไม่ตรงกันหลังแก้
- Cross-reference ระหว่าง module BO/FO ขาดหายหลังเพิ่ม/ลบ section
- Document version/baseline ไม่ได้อัปเดทตามการเปลี่ยนแปลง
- AI เขียนเอกสารไม่ตรง format/convention ของ module ที่มีอยู่

แต่ละ Risk ต้องมีแนวทางรับมือสั้น ๆ และระบุว่าใครเป็นผู้ตรวจสอบ

### ขั้น 9: ตรวจสอบ/แก้ไขใน Feature ย่อย — กฎ

#### 9. ตรวจสอบ/แก้ไข แจกใส่ในแต่ละ Feature ย่อย

**กฎบังคับ:** "ตรวจสอบ" และ "แก้ไข" ไม่ใช่ฟิลด์แยกที่ระดับเป้าหมาย — แจกใส่ในแต่ละ Feature ย่อย (subtask) แทน เพราะ work log เกิดจาก Task ที่ปิดพร้อมสรุปแล้ว แต่ละ subtask ต้องมี build + ตรวจสอบ + แก้ไข ครบในตัวเอง


**บทบาท AI vs คน ในตรวจสอบ/แก้ไข:**
- **ตรวจสอบ:** มนุษย์เป็นหลัก (review เอกสารจริง, ตรวจ prototype จริง, เทียบ spec กับ prototype) — AI ช่วยเตรียม checklist ได้ แต่ผลการตรวจต้องมาจากมนุษย์
- **แก้ไข:** AI เป็นหลักในการแก้เอกสาร/prototype — มนุษย์ตรวจว่าแก้ถูกและไม่ทำลายของเดิม (regression)
- เวลาตรวจสอบ = เวลา AI เตรียม ตรวจทาน และรองรับการตรวจรับตามขอบเขต Task/Feature
- เวลาแก้ไข = เวลา AI แก้ตามผลตรวจและตรวจซ้ำจนพร้อมส่งมอบ

> **เหตุผล:** การตรวจสอบและแก้ไขเป็นส่วนหนึ่งของงานเสมอ ไม่ใช่งานเสริม — ต้องวางแผนไว้ตั้งแต่ต้น และรวมอยู่ในเวลา AI ทำงานของ Task/Feature นั้น

ถ้าเป้าหมายใดไม่มีงานตรวจสอบ/แก้ไขจริง (เช่น เป็นงาน decision/ประสานกับ Product ล้วน ไม่มีการแก้ไฟล์) ให้ระบุเหตุผลไว้ใน Feature ย่อย ชัดเจนว่าทำไมไม่มี

### ขั้น 11: Mapping — กฎการ map

กฎการ map:
- 1 Objective map กับ 1 หรือหลาย Feature
- 1 Feature map กับ 1 task หรือหลาย task ได้ ถ้า Task เหล่านั้นทำเพื่อผลลัพธ์เดียวกัน
- ไม่ต้องสร้าง Feature ใหม่เพียงเพราะมี Task เพิ่ม หากยังเป็นผลลัพธ์เดียวกัน
- ถ้า Feature ยังไม่มี Task รองรับ ให้ระบุว่า **ยังไม่มี task รองรับ** และห้ามสรุป Feature นั้นว่าเสร็จ
- Parent task ที่รวม subtask ต้องแสดงความสัมพันธ์ให้ชัด และห้ามบวกชั่วโมงของ parent กับ subtask ซ้ำกัน

**work log:** เกิดจาก Task ที่สรุปและปิดแล้ว โดยเลือก Objective และ Feature ที่ map กับ Task นั้น; เมื่อสรุปผลให้รวม log ของทุก Task ภายใต้ Feature เดียวกัน

### ขั้น 13: Mission Approval / Session End — รายละเอียด

#### 13. Mission Approval / Session End Workflow

ส่วนนี้ใช้เมื่อ **Mission Planning เสร็จ** และผู้ใช้ **อนุมัติ Mission Plan อย่างชัดเจน** ห้ามอนุมาน approval จากการที่ผู้ใช้เพียงอ่านแผนหรือขอแก้ไขแผน หลัง approval ให้สร้าง Mission Plan Summary และ Session Handoff เป็นสอง artifact แยกกันก่อนเริ่ม implementation; หากผู้ใช้ต้องการจบ planning session ให้บันทึก Handoff และจบ session ตาม flow ด้านล่าง

- ห้ามเริ่ม **Mission execution task**, ย้าย execution task เป็น `in_progress` หรือเริ่ม execution timer โดยอัตโนมัติ กฎนี้ไม่ย้อนกลับไปห้าม Planning Task ที่ต้องอยู่ `in_progress` ระหว่างทำงานวางแผน และ Planning Task ควรถูกปิดหลัง baseline ได้รับ approval
- ถ้าผู้ใช้ยังไม่อนุมัติ ให้แสดง Draft Mission Plan/ฉบับแก้ไขตาม workflow เดิม และยังไม่เรียก output ว่า Approved
- หลังได้รับ approval ให้ทำตามลำดับนี้เท่านั้น: สร้าง Mission Plan Summary Copy Block → สร้าง Mission + execution tasks ใน Kanban (ทุก task = `todo` เท่านั้น, Category/Planned ครบตามกฎ Task Description) → สร้าง/อัปเดต Session Handoff → แสดงทั้งสอง artifact แยกกัน → จบ planning session
- **Planning session ห้ามต่อเป็น execution ในตัว** — หลังจบ planning session การเริ่มทำ execution task ตัวแรก (`move_task` → `in_progress` + ลงมือจริง) ต้องเกิดใน **session ใหม่เท่านั้น** ไม่ทำต่อเนื่องใน session วางแผน เพื่อให้ session execute รับช่วงจาก Session Handoff/Kanban state ที่สะอาด เว้นแต่ผู้ใช้สั่งชัดเจนว่าให้ทำต่อใน session เดียวกัน
- เมื่อมีทั้งสอง artifact ในคำตอบเดียวกัน ต้องแยก heading และ code block ชัดเจน ห้ามรวมเนื้อหาเป็น block เดียว
- หากผู้ใช้ขอจบ session ให้บันทึก **Session Handoff** ผ่าน `save_session_note` เมื่อเครื่องมือพร้อม; การบันทึกนี้เป็น task/session context ภายใน Kanban ไม่ใช่การส่ง Work Log เข้า Core Portal


#### 13.1.1 Baseline Persistence — บันทึก Approved Plan ให้เรียกย้อนได้ (บังคับ)

ปัญหาที่กฎนี้แก้: ถ้า Objective/Feature labels ของ approved plan อยู่แค่ใน chat (copy block ที่แสดงให้ผู้ใช้) เวลาสรุปงานทีหลังจะดึงชื่อ label ที่ถูกต้องจากระบบไม่ได้ ทำให้ work log ต้องเดา Feature เองจนข้อมูลเพี้ยน — ทุก Mission ที่ได้รับ approval ต้อง persist baseline ทั้ง 2 ชั้นนี้เสมอ:

1. **Mission description ต้องมี Objective → Feature → Task labels ครบ** — ห้ามเขียน description ที่มีแค่ `Objective — TASK-CODE` ล้วน ๆ ให้ใส่ Feature name ใต้แต่ละ Objective ด้วย เพราะ `get_mission` คือแหล่ง verbatim สุดท้ายที่ work-summary ใช้อ้าง (เช่น `1. Requirements Intake Pipeline (19% | 1.5 ชม.) — Features: Requirements Snapshot & Register → REQ-001, REQ-002`)
2. **`save_session_note` เก็บ Mission Plan Summary verbatim ลง Planning Task หรือ task แรกของ mission** — note ต้องมี Mission Name, Objectives, Feature labels และ Task mapping ตามที่ approve ตรง ๆ เพื่อให้ session ใด ๆ ดึง `get_task` แล้วเห็น baseline เดิม

**กฎการแก้ label หลัง approve:** ถ้ามีการ rename Objective/Feature หลัง plan เริ่มแล้ว (เช่น ตัดเงื่อนไขกระบวนการออกจาก label) ให้อัปเดต mission description ด้วย `update_mission` และบันทึก correction note ลงทุก task ที่ได้รับผลกระทบ — ห้ามปล่อยให้ label ในระบบกับ label ที่ใช้ลง work log คนละชุด

#### 13.2 Session Handoff — กฎ

**กฎ Handoff:**
- Handoff สามารถมี Kanban UUID/internal IDs ได้ เพราะใช้ให้ Agent resolve entity ถูกต้อง
- ห้ามตัด technical/internal context ออกจาก Handoff เพียงเพราะข้อมูลบางส่วนมีใน Mission Plan Summary แล้ว
- ระบุชัดว่า Task ถัดไปคืออะไร, Task ใดห้ามเริ่ม และ implementation เริ่มได้เมื่อไร
- ถ้ายังไม่มี Task เริ่ม ให้ยืนยัน `in_progress = 0`, ไม่มี timer ทำงาน และ implementation ยังไม่เริ่ม
- ถ้าผู้ใช้กำหนด task-by-task approval gate ให้เก็บ gate นั้นไว้ใน Handoff

#### 13.3 Next Session Workflow

Mission Plan Summary ไม่ใช่ execution context หลัก การเริ่ม Execute Mission ต้องอ้าง Session Handoff:

```text
Session Handoff
+ User Start Task Prompt
→ Load Project/Kanban Context
→ Load Mission / Requirement / Next Task
→ Verify current state, Scope, Acceptance Criteria และ Dependencies
→ move_task → in_progress เพื่อเริ่ม auto-timer เมื่อได้รับอนุญาต
→ Execute เฉพาะ Task ตาม approved order
```

- ห้ามกำหนดให้ผู้ใช้ต้องนำ Mission Plan Summary Copy Block มาใช้แทน Session Handoff
- ห้ามเริ่ม Task ถัดไปอัตโนมัติหลังสร้าง Summary/Handoff หรือหลังจบ planning session — execution ต้องเริ่มใน session ใหม่เสมอ (ผู้ใช้เปิด session ใหม่ + start task prompt) ไม่ทำต่อเนื่องใน session วางแผน เว้นแต่ผู้ใช้สั่งชัดเจน

### ส่วนที่ 2 ขั้น 2: ตรวจสอบงานที่ AI ทำและรวบรวม Evidence

ก่อนสรุปว่างานเสร็จ ต้องตรวจสอบอย่างน้อย:

- AI แก้ไฟล์และ format ตรงกับ module spec ที่มีอยู่
- ไม่มีการแก้ข้ามขอบเขตโดยไม่แจ้ง โดยเฉพาะ protected screens
- cross-reference ระหว่าง module ยังครบ ไม่ขาดหาย
- document version/baseline อัปเดตตามการเปลี่ยนแปลง
- ถ้าเกี่ยวกับ prototype ต้องตรวจว่าไม่กระทบ protected screens
- ผลตรวจต้องมาจากการตรวจจริงของมนุษย์ ไม่ใช่คำกล่าวอ้างของ AI

**Evidence ที่ควรบันทึกในสรุป:**
- ไฟล์หรือ section สำคัญที่แก้
- prototype screen หรือ flow ที่ตรวจ
- ผล QA checklist และ cross-reference check
- ผลเทียบ spec กับ prototype (ถ้าเกี่ยวข้อง)
- protected screens ที่กระทบ (ถ้ามี)
- งานที่ยังไม่มีหลักฐานหรือยังต้องตรวจเพิ่ม

ถ้าไม่มี Evidence เพียงพอ ให้ใช้สถานะ **บางส่วน** หรือ **รอตรวจสอบ** แทน **เสร็จ**

**Submission Evidence ต่อเป้าหมาย (บังคับเมื่อเป้าหมายเสร็จ):**
- เมื่อเป้าหมายใดทำครบทุก Task แล้ว (สถานะ `เสร็จ`) ให้เตรียม **หลักฐานส่งตรวจรับด้วย AI** ของเป้าหมายนั้นตาม skill `submission-evidence` — ครอบการเลือกไฟล์แนบ/ภาพหน้าจอ, นโยบายช่อง URL, คำอธิบายภาษาเข้าใจง่าย และ copy block สำหรับฟอร์มส่งตรวจ
- ใส่ชื่อไฟล์แนบ/แพ็กเกจหลักฐานไว้ในหัวข้อ "หลักฐาน" ของเป้าหมายนั้นในสรุปผล ด้วย — เพื่อให้ log มีหลักฐานพร้อมส่งครบทุกเป้าหมาย
- เป้าหมายที่ยังไม่ครบห้ามสร้างหลักฐานแบบ "เสร็จ" — ระบุสถานะ `บางส่วน`/`รอตรวจสอบ` และบอกว่าหลักฐานจะจัดเมื่อเป้าหมายครบ

### กฎเมื่อแผนเปลี่ยนระหว่างทำ

หากพบงานเพิ่ม งานลด ความเสี่ยง หรือเวลาจริงต่างจากแผน:

1. ระบุว่าแผนเดิมข้อใดได้รับผลกระทบ
2. อธิบายสาเหตุที่เปลี่ยน
3. แยกงานที่เพิ่มเป็น **งานนอก Scope** หรือระบุงานที่ถูกตัด/เลื่อน
4. ห้ามแก้ Mission Plan ตั้งต้นย้อนหลังโดยไม่เก็บฉบับเดิมไว้
5. หากผู้ใช้อนุมัติให้ปรับแผน ให้แสดง copy block ของแผนฉบับปรับปรุงแยกจากแผนเดิม
6. คำนวณเวลาใหม่และตรวจว่ายังไม่เกินงบ Mission หรือเสนอแยกเป็น Mission ใหม่
7. ถ้าเกิน 5 วัน ให้เสนอแยกเป็น Mission ใหม่
8. ห้ามปรับแผนหรือสถานะเป็นเสร็จเงียบ ๆ โดยไม่แจ้งผู้ใช้
9. ใน Work Summary ต้องแยกให้เห็นว่าอะไรทำตามแผน อะไรทำเพิ่ม อะไรถูกตัด และอะไรถูกเลื่อน

## รูปแบบ Copy Block — กฎทั่วไป (15 ข้อ)

**กฎสำหรับ copy block ทุกอัน:**
1. ใช้ code block ที่ระบุภาษาเป็น `text` (เช่น ` ```text `) เพื่อให้ก๊อปง่าย
2. เนื้อหาใน copy block ต้องเป็นข้อความล้วน ไม่มี Markdown heading, bold, inline code, ตาราง หรือ horizontal rule
3. ใช้ literal `- ` นำหน้าแต่ละรายการภายใน `text` code block เพื่อให้ Copy ออกไปเป็นเครื่องหมาย `-` ไม่ใช่ rendered bullet symbol `•`
4. Copy block ของ **Work Summary ต้องระบุ `สถานะ` และ `รายละเอียดที่ทำ` อย่างชัดเจน** สำหรับทุก task/แผนที่สรุป รวมถึงผลลัพธ์และหลักฐานเมื่อมี
5. สถานะต้องใช้คำที่ตรวจสอบได้: `เสร็จ`, `บางส่วน`, `ยังไม่ทำ` หรือ `รอตรวจสอบ`
6. **ให้ใส่น้ำหนัก (Weight %) และชั่วโมงใน copy block** เพื่อให้ข้อมูลครบสำหรับระบบปลายทางที่ต้องการข้อมูลครบ — รายละเอียดตามกฎด้านล่าง
7. ภาษาไทยเข้าใจง่าย เน้นสิ่งที่ทำ/ผลลัพธ์ ไม่ใช่คำศัพท์เทคนิค
8. **ภาษาใน copy block (บังคับ):** ใช้ภาษาเข้าใจง่าย — เปลี่ยนคำโค้ด/เทคนิคที่คนทั่วไปไม่เข้าใจเป็นคำเข้าใจง่าย แต่คำเฉพาะ/ศัพท์ที่คุ้นเคย (เช่น breadcrumb, Alert, asset, spec, baseline, Kanban) เก็บไว้ได้ ไม่บังคับล้วนไทย — ห้ามใช้ชื่อฟังก์ชัน/ชื่อโค้ด (เช่น `renderWatchAlertList()`, `mock data`, `status badge`, `soft delete`, `cross-reference`, `viewport`) ใน copy block
9. **Tasks เป็นลิสข้อ ๆ ลงมา** — ไม่ใช่ `,` หรือ `+` คั่นบรรทัดเดียว
10. **Feature ย่อยเป็นผลลัพธ์ย่อยของ Objective** — หนึ่ง Feature map กับหนึ่งหรือหลาย Task ได้ และไม่ต้องแตก Feature ให้เท่ากับจำนวน Task
11. **รายละเอียดของ Objective ไม่ใส่ชั่วโมง** — เวลารวมอยู่ใน Feature ย่อยแล้ว
12. **ตรวจสอบ/แก้ไขอยู่ในระดับ Feature** — ใส่เป็นแผนที่วางไว้ก่อนเริ่มงาน ใช้ `()` ครอบเวลา และไม่ต้องสร้าง Task ตรวจสอบ/แก้ไขแยก เว้นแต่เป็นงานที่ต้องติดตามอิสระ
13. **Mission Plan ห้ามใช้ผลลัพธ์ย้อนหลัง** — ห้ามใส่สถานะเสร็จ, ชั่วโมงจริง, Evidence, bug ที่พบจริง หรือผล QA ที่เกิดขึ้นแล้วใน copy block ของแผนตั้งต้น
14. **แยก approval artifacts ตามผู้ใช้ปลายทาง:** Mission Plan Summary สำหรับคนอ่าน Work Log; Session Handoff สำหรับ Agent/session ถัดไป ห้ามรวมสองแบบเป็น artifact เดียว
15. **Identifier rule:** Mission Plan Summary ห้ามมี Kanban UUID/internal ID และใช้ `<TASK-CODE> <Task Name> — <task planned hours>`; Session Handoff และ Work Summary เชิงเทคนิคใช้ internal IDs ได้เมื่อจำเป็นต่อ traceability

## Checklist

### ส่วนที่ 1: วางแผน Mission
- [ ] ถ้าผู้ใช้กำหนด Planning Task หรือ workflow ต้องจับเวลางานวางแผน: สร้าง Planning Task ก่อนเริ่มอ่าน context เชิงงาน/วิเคราะห์/ร่างแผน
- [ ] ย้าย Planning Task เข้า `in_progress` เพื่อเริ่ม auto-timer ก่อนลงมือวางแผน และห้ามปิดจาก `todo → done` โดยตรง
- [ ] แยก Planning Task ออกจาก Mission execution task ให้ชัด: ข้อห้ามเริ่ม task/timer ก่อน approval ใช้กับ execution task เท่านั้น
- [ ] หลังผู้ใช้อนุมัติ baseline จึงปิด Planning Task; ห้ามใช้ `log_time` และให้ยึดเวลาจาก auto-timer
- [ ] เรียก `mcp_list_tools` ของ `kanban-tukdaeng` เพื่อดูเครื่องมือทั้งหมด
- [ ] เรียก `get_session_context` เพื่อ resume session
- [ ] เรียก `get_board` เพื่อดู task ที่ค้าง/ทำอยู่
- [ ] เรียก `get_task` สำหรับทุก task DONE ที่เกี่ยวข้องกับ Mission
- [ ] แสดง Description และ Activity timeline ของ task DONE เป็นรายการ (note/status/time)
- [ ] เรียก `get_time_summary` เพื่อดูชั่วโมงที่ใช้ไป (ถ้าจำเป็น)
- [ ] คิด Mission + จำนวนวัน (1-5 วัน) + แบ่งเป็นเป้าหมายย่อย 2-5 ข้อ
- [ ] การวางแผน Mission เสร็จก่อนสร้าง Mission และไม่ถูกนับเป็น Objective เว้นแต่ผู้ใช้ระบุว่าเป็น deliverable
- [ ] กำหนดเป้าหมาย, สิ่งที่ต้องส่งมอบ และสิ่งที่ไม่รวมใน Scope
- [ ] กำหนด Acceptance Criteria ที่ตรวจสอบได้จริง
- [ ] สรุปหัวข้อ Mission ตามฟิลด์ฟอร์ม Create Mission (ชื่อแผนงาน, พนักงานผู้รับผิดชอบ, โปรเจกต์, วันที่เริ่ม/เสร็จ, Planned Days, Baseline) + **copy block ที่มี Baseline/จำนวนชั่วโมงทั้งหมด/เหลือชั่วโมง**
- [ ] คำนวณ Baseline = Total Planned Hours เสมอ (ถ้าผู้ใช้ใส่ Total = ค่าที่ใส่, ถ้าไม่ใส่ = Planned Days × 8 ชม.) และแสดง **เหลือชั่วโมงให้วางแผน = 0** (Baseline = Total)
- [ ] วางแผนแยก Objective (แต่ละ Objective ระบุ Service, Tasks, น้ำหนัก%, ชั่วโมงที่คาดการณ์, ผู้รับผิดชอบหลัก, รายละเอียด, Feature ย่อย และ Dependency)
- [ ] ตรวจว่าแต่ละ Feature เป็นผลลัพธ์ย่อยที่ชัดเจน และ map กับ Task ได้ 1 task หรือหลาย task
- [ ] ตรวจว่า Feature ไม่ได้ถูกแตกตามจำนวน Task โดยไม่จำเป็น และไม่บังคับให้ Feature หนึ่งมี Task เดียว
- [ ] ตรวจว่าชื่อ Objective และ Feature เป็นชื่อ label สั้นตาม Naming Rules — ไม่มี scope/behavior/AC ยัดอยู่ในชื่อ และใช้ terminology ที่ทีมเข้าใจจริง
- [ ] ตรวจว่าน้ำหนัก (Weight) ของทุกเป้าหมายรวมกัน **เท่ากับ 100%**
- [ ] ระบุ Dependency, ลำดับงาน และ critical path ระหว่างเป้าหมาย
- [ ] กำหนด **Evidence Plan** ต่อ Objective ตาม Continuous Evidence Planning — เป้าหมาย test ต้องวางไว้ตั้งแต่ต้น: raw output + HTML report capture + ภาพ/screencast flow dynamic + triage note เคส skipped + ตัดสินใจ scope accessibility
- [ ] ประเมินเวลาแต่ละเป้าหมาย (1 วัน = 8 ชม.) — **เวลา = เวลา AI ทำงานเป็นหลัก** รวมการวิเคราะห์ สร้าง แก้ และตรวจรับตามขอบเขต
- [ ] ระบุหมวดหมู่งานของแต่ละ task และประเมินเวลาตามเป้าหมายหมวดในตารางเวลามาตรฐาน
- [ ] ตรวจว่า `Category Max` เท่ากับเป้าหมายหมวดโดยตรง และถ้า Planned ถึงหรือเกินค่านี้ให้ทบทวน scope/แตก subtask โดยไม่ตั้ง Planned ต่ำกว่าความจริง
- [ ] ยืนยันว่าเวลาจริงถึงหรือเกินเป้าหมายหมวดเป็นเกณฑ์ Review; หากระบบรายงาน Time Ratio > 1.5 ให้ยึดสถานะจากระบบ และห้ามคูณเป้าหมายหมวดเพิ่ม
- [ ] ⚠️ **Total Planned Hours ประเมินตามความจริง** — Baseline = Total เสมอ, เหลือชั่วโมงให้วางแผน = 0 เสมอ (Baseline อิงตาม Total ไม่ใช่ Days × 8 โดยตรง)
- [ ] ⚠️ **ห้ามแก้แผนหลัง start Mission โดยไม่มีเหตุผล** — ถ้าจำเป็นต้องแก้ ต้องระบุเหตุผลและแจ้งผู้ใช้ก่อน (มีผลต่อคะแนนความแม่นยำในการวางแผน)
- [ ] ระบุ Risk พร้อมแนวทางรับมือ (ถ้า task เกินเวลา รวมจะเกิน Total Planned Hours ทันที ให้ใช้กฎชี้แจงเวลาเกินงบใน work-summary)
- [ ] ตรวจสอบ/แก้ไข แจกใส่ในแต่ละ Feature ย่อย (ไม่มีฟิลด์ ตรวจสอบ/แก้ไข แยกที่ระดับเป้าหมาย) ใช้ `()` ครอบเวลา
- [ ] ตรวจว่าแผนกระทบ protected screens หรือไม่ (อ้าง `AGENTS.md` / `PROTECTED_SCREENS.md`)
- [ ] แยก Mission Plan ออกจาก Work Summary — Mission Plan ไม่มีสถานะจริง, ชั่วโมงจริง, Activity log, Evidence หรือ bug ที่พบภายหลัง
- [ ] Mapping Objective → Feature → Kanban task (1 Objective = หลาย Feature, 1 Feature = 1 หรือหลาย task)
- [ ] สรุปแผนเป็นข้อ ๆ แยกตามเป้าหมาย พร้อมน้ำหนัก% และ Feature ย่อย + **copy block ที่มีน้ำหนัก/ชั่วโมงครบ**
- [ ] ถ้าผู้ใช้อนุมัติ Mission Plan แล้ว ให้ล็อก Approved Mission Baseline ก่อนสร้าง approval artifacts
- [ ] สร้าง Mission Plan Summary สำหรับ Work Log เป็น Human-readable `text` Copy Block เดียว โดยคง hierarchy ทางข้อมูล Mission → Objective → Feature → Task พร้อม Planned Duration, Total Planned Hours, Objective Hours/Weight, Task Planned Hours และ Execution Sequence ครบ
- [ ] ตรวจ Mission Plan Summary ว่า Task ใช้ `<TASK-CODE> <Task Name> — <task planned hours>` และไม่มี Kanban UUID/internal ID ทุกชนิด
- [ ] ตรวจ Planned Time ครบ 3 ระดับ: Mission, Objective และ Task ทุกตัว
- [ ] ตรวจรูปแบบชั่วโมงใน Mission Plan Summary ว่าอ่านง่ายและไม่แสดงค่าซ้ำ เช่นใช้ `8 ชม.` หรือ `2 ชม. 30 นาที`
- [ ] ตรวจวันที่ใน Mission Plan Summary ว่าเป็น human-readable date range เมื่อทำได้โดยไม่เปลี่ยนค่าจริง
- [ ] ตรวจว่ารายการใน Mission Plan Summary ใช้ literal `- ` ภายใน `text` code block และไม่มี `*` หรือ rendered bullet `•`
- [ ] หลัง approval สร้าง Mission + execution tasks ใน Kanban ด้วย status `todo` ทั้งหมด (Category/Planned ครบ) ก่อนสร้าง Session Handoff
- [ ] สร้างหรืออัปเดต Session Handoff แยกอีก artifact โดยคง identifiers, technical context, current state, next task และ next-session instructions ครบ
- [ ] บันทึก Session Handoff ด้วย `save_session_note` เมื่อเครื่องมือพร้อม และแสดง Summary/Handoff เป็นคนละ code block
- [ ] จบ planning session หลังสร้าง Summary + tasks + Handoff ครบ — ห้ามเริ่ม execution ใน session เดียวกัน (execution เริ่ม session ใหม่เท่านั้น เว้นแต่ผู้ใช้สั่งชัดเจน)
- [ ] ตรวจว่าไม่ได้เริ่ม implementation, ไม่ย้าย Mission execution task เป็น `in_progress` และไม่เริ่ม execution timer จาก approval workflow; Planning Task ถูกปิดหลัง approval ตาม workflow แล้ว
- [ ] ⚠️ **ภาษาใน copy block** — ใช้ภาษาเข้าใจง่าย เปลี่ยนคำโค้ด/เทคนิคเป็นคำเข้าใจง่าย แต่คำเฉพาะ/ศัพท์ที่คุ้นเคย (breadcrumb, Alert, asset, spec, baseline, Kanban) เก็บไว้ได้ ไม่บังคับล้วนไทย ห้ามใช้ชื่อฟังก์ชัน/โค้ด
- [ ] ⚠️ ห้ามส่ง log/อัปเดตระบบภายนอกใด ๆ

### ส่วนที่ 2: สรุปผลหลังทำตามแผน
- [ ] เรียก `mcp_list_tools` ของ `kanban-tukdaeng`
- [ ] เรียก `get_board` เพื่อดู task ที่ทำเสร็จ/ยังค้าง
- [ ] เรียก `get_task` สำหรับทุก task DONE ที่เกี่ยวข้อง
- [ ] แสดงรายละเอียดงานและ Activity timeline ของแต่ละ task ที่เสร็จแล้ว
- [ ] เรียก `get_time_summary` เพื่อดูชั่วโมงที่ใช้จริง
- [ ] ตรวจสอบงานที่ AI ทำตาม AI Review Checklist
- [ ] รวบรวม Evidence: ไฟล์, section, prototype, QA checklist, cross-reference และผลตรวจ
- [ ] ตรวจว่าแก้ protected screens หรือไม่ (ถ้าแก้ ต้องมีอนุมัติจากผู้ใช้)
- [ ] ตรวจ Acceptance Criteria ครบทุกข้อ
- [ ] สรุปผลเป็นข้อ ๆ แยกตามเป้าหมาย (เปรียบเทียบกับแผนในส่วนที่ 1)
- [ ] รวม log การทำงานของแต่ละเป้าหมายจาก Activity timeline ของทุก task ในเป้าหมาย
- [ ] ระบุสถานะชัดเจน: เสร็จ / บางส่วน / ยังไม่ทำ / รอตรวจสอบ
- [ ] แสดงเปรียบเทียบเวลา: วางแผน vs ใช้จริง (แสดงทั้งในสรุปด้านนอกและใน copy block ตามเป้าหมาย)
- [ ] แยกงานที่ทำตามแผน, งานนอก Scope และงานที่ถูกเลื่อน
- [ ] สรุปงานที่ยังค้าง
- [ ] สร้าง **copy block** ของสรุปผลที่มีน้ำหนัก%, เวลาวางแผน vs ใช้จริง ต่อเป้าหมาย และรวมทั้ง Mission
- [ ] ตรวจว่า Copy block ของ Work Summary มี **สถานะ**, **รายละเอียดที่ทำ** และ **log การทำงาน** ครบทุกเป้าหมาย (Tasks เป็นลิสข้อ ๆ ไม่มีฟิลด์ ตรวจสอบ/แก้ไข แยก)
- [ ] ⚠️ ห้ามส่ง log/อัปเดตระบบภายนอกใด ๆ
