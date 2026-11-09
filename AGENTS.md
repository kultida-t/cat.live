# Agent Instructions — cat.live

## ข้อมูลผู้ใช้และสไตล์การสื่อสาร (Response Style)

- ผู้ใช้ที่สั่งงานคือ **พี่มาเต็ม (Matem)** — เรียกว่า **"พี่มาเต็ม"** เสมอ
- ตอบพี่มาเต็มเป็นภาษาไทยแบบอ่านเข้าใจง่าย ใช้ประโยคสั้น ภาษาคนคุยกัน เลี่ยงศัพท์เทคนิคหรือศัพท์ยุ่งยากเท่าที่ทำได้ ถ้าจำเป็นต้องใช้ศัพท์เทคนิคให้แปะคำอธิบายสั้น ๆ ในวงเล็บเสมอ
- เวลาสรุปแผนหรือสรุปงาน ให้แยกหัวข้อสั้น ๆ อธิบายชัดเจนว่า **"ทำอะไร เพื่ออะไร และผลกับผู้ใช้/หน้าจอเป็นยังไง"** ไม่ใช่แค่ลิสต์รายการทางเทคนิค
- หากไม่แน่ใจในความต้องการ ให้ถามเพื่อความชัดเจนก่อนลงมือทำ แทนการเดาไปเอง

## แนวทางการทำงานแบบ Solo Developer + AI

โปรเจกต์ `cat.live` พัฒนาโดยพี่มาเต็มคนเดียวคู่กับ AI ดังนั้น AI ต้องทำหน้าที่เป็นคู่หูที่ช่วยดูแลความเรียบร้อยและลดความเสี่ยงในทุกขั้นตอน:

1. **ค่อย ๆ เดินงานทีละสเต็ป (Step-by-step & Vertical Slice):**
   - อย่าสร้างหรือแก้โค้ดก้อนใหญ่ทีเดียวโดยไม่ตกลงแผนก่อน
   - ลำดับการทำงานมาตรฐาน:
     1. คุยขอบเขตงานและหน้าจอให้ชัด (Requirement / Prototype)
     2. วางโครงสร้างข้อมูล (Database Schema / State) แล้วอธิบายให้พี่มาเต็มเห็นภาพก่อน
     3. ทำทีละฟีเจอร์ให้จบตั้งแต่หน้าบ้าน → หลังบ้าน → ทดสอบใช้งานได้จริง
2. **ช่วยคิดเผื่อเคสแปลก ๆ (Edge Cases & Security):**
   - นอกจากทางเดินปกติ (Happy Path) ต้องช่วยดักเคสที่อาจหลุด เช่น ข้อมูลว่าง (Empty State), กำลังโหลด (Loading State), เน็ตหลุด/ระบบพัง (Error State), การกดปุ่มซ้ำรัว ๆ และการเช็กสิทธิ์เข้าถึงข้อมูล
3. **ดูแลไม่ให้ของเก่าพัง (Protected Screens / Features):**
   - ฟีเจอร์หรือหน้าจอที่พี่มาเต็มตรวจรับและยืนยันล็อกแล้ว จะถูกบันทึกไว้ในไฟล์ `PROTECTED_SCREENS.md` และหมวด `Protected Screens / Features` ด้านล่าง ห้ามแก้ไขหรือทำให้กระทบโดยไม่ถามพี่มาเต็มก่อน
   - เตือนและช่วยเซฟงานลง Git (`commit` / `push`) เป็นระยะเมื่อจบแต่ละก้าวสำคัญ เพื่อให้อย้อนกลับได้ง่ายหากเกิดปัญหา
4. **ส่งรายการทดสอบ (Manual Review Checklist) ทุกครั้งที่แตะหน้าจอหรือระบบ:**
   - เมื่อทำหรือแก้ฟีเจอร์เสร็จ ต้องส่งลิสต์วิธีทดสอบเป็นข้อ ๆ ก่อนถามว่าปิดงานได้ไหม โดยระบุ:
     - เลขเคส + ชื่อเคส
     - ข้อมูลตัวอย่างที่ใช้กรอก/กดได้เลย
     - ขั้นตอนการกดตามลำดับ
     - ผลลัพธ์ที่ต้องเห็นบนหน้าจอ

## มาตรฐานภาษาในโค้ดและหน้าจอ (Language Conventions)

- ข้อความบนหน้าจอ (ปุ่ม, หัวข้อ, แจ้งเตือน, ข้อความเมื่อไม่มีข้อมูล) ใช้ภาษาไทยเป็นหลัก ยกเว้นส่วนที่ตกลงกันว่าใช้ภาษาอังกฤษ
- Comment ในโค้ดให้อธิบายเจตนาของโค้ดด้วยภาษาที่เข้าใจง่าย (ห้ามใส่เลข task ชั่วคราวใน comment)

---

## โครงสร้างการทำงานและ Skills ประจำโปรเจกต์ (`.agents/skills/`)

โปรเจกต์นี้ติดตั้ง Skills มาตรฐานสำหรับบริหารจัดการงานและหลักฐานส่งตรวจไว้ใน `.agents/skills/` ดังนี้:

1. **`mission-planning` (`.agents/skills/mission-planning/SKILL.md`):**
   - ใช้เมื่อเริ่มวางแผนภารกิจรายวัน (Mission), แยกเป้าหมาย (Objective / Feature / Task), สร้าง Mission Plan Summary และ Session Handoff หลังพี่มาเต็มอนุมัติแผน รวมถึงสรุปผลหลังทำตามแผน
2. **`work-summary` (`.agents/skills/work-summary/SKILL.md`):**
   - ใช้จับเวลาและสรุปงานราย Task (เริ่มทำ Task → เก็บภาพ Before → ส่ง Manual Review Checklist → ปิด Task → สร้าง Final Work Summary และ Session Handoff)
3. **`submission-evidence` (`.agents/skills/submission-evidence/SKILL.md`):**
   - ใช้เตรียมชุดหลักฐานส่งตรวจรับต่อเป้าหมาย (Objective) ตามเกณฑ์ AI Worklog QA Auditor (ไฟล์แนบ, ภาพหน้าจอ Desktop 1440px + Mobile 390px, Checklist Card, `external_url` และคำอธิบาย)
4. **`ai-conversation-daily-log` (`.agents/skills/ai-conversation-daily-log/SKILL.md`):**
   - ใช้สร้างไฟล์สรุปประวัติการสนทนากับ AI รายวัน (`YYYY-MM-DD_ai-log.json`) โดยดึงข้อมูลจริงจาก IDE Transcript Store

### โครงสร้างโฟลเดอร์หลักฐานและสคริปต์ช่วยงาน
- `screenshots/` — เก็บภาพหน้าจอ Before/After และ Checklist Card แยกตาม `mission-<N>-objective-<M>/`
- `deliverables/` — เก็บชุดไฟล์หลักฐานและผลรันการทดสอบสำหรับส่งตรวจ
- `docs/` — เก็บเอกสารสเปกและโครงสร้างระบบของโปรเจกต์
- `scripts/` — เก็บสคริปต์ช่วยสร้างหลักฐาน (`render-checklist-card.js`, `render-test-checklist.js`, `render-test-output.js`) และสคริปต์แคปหน้าจอ

---

## โครงสร้างสายงาน Git (Git Branching Strategy)

- **`master`** — สายงานหลักสำหรับเก็บโค้ดและเอกสารที่ตรวจรับผ่านแล้ว (Production / Locked Baseline)
- **`dev`** — สายงานรวมโค้ดที่กำลังพัฒนาและทดสอบร่วมกันก่อนส่งขึ้น `master`
- **Working Branches (เช่น `chore/project-setup`, `feat/...`, `fix/...`)** — สายงานย่อยที่แตกออกจาก `dev` เพื่อทำงานแต่ละเรื่องแยกกัน เมื่อเสร็จและตรวจรับผ่านแล้วจึงรวม (Merge) กลับเข้า `dev`

---

## สถานะปัจจุบันของโปรเจกต์ (Session Context / Handoff)

- **Repository:** `https://github.com/kultida-t/cat.live.git`
- **Local Path:** `D:\cat.live`
- **สถานะล่าสุด (2026-11-09):**
  - ติดตั้ง Skills ทั้ง 4 ตัว (`mission-planning`, `work-summary`, `submission-evidence`, `ai-conversation-daily-log`) ใน `.agents/skills/` และปรับที่อยู่โฟลเดอร์/GitHub URL ให้ตรงกับ `cat.live` แล้ว
  - สร้างโครงสร้างโฟลเดอร์มาตรฐาน (`screenshots/`, `deliverables/`, `docs/`, `scripts/`), `.gitignore` และ `PROTECTED_SCREENS.md` เรียบร้อยแล้ว
  - จัดตั้ง Git Branches (`master`, `dev`, และ `chore/project-setup`) พร้อมใช้งาน

## Protected Screens / Features

*(ยังไม่มีหน้าจอที่ล็อก — ดูรายละเอียดเพิ่มเติมที่ `PROTECTED_SCREENS.md`)*
