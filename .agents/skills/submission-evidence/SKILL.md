---
name: submission-evidence
description: เตรียมหลักฐานส่งตรวจรับต่อเป้าหมาย (Objective) ของ Mission สำหรับ cat.live — มุ่งเพิ่มโอกาสผ่านเกณฑ์ AI Worklog QA Auditor (Gemini Multimodal) โดยตรวจความครบถ้วนของ artifact, external_url, เวลา, รอบส่ง และคุณภาพหลักฐาน พร้อม copy block ฟอร์มส่งตรวจและ compact Mission Objective–Feature–Task; ไม่รับประกันคะแนนหรือ verdict. Use เมื่อเป้าหมายใน Mission ทำครบทุก Task แล้วต้องเตรียมหลักฐานส่งตรวจ หรือผู้ใช้ขอ "หลักฐานส่งตรวจ" / "evidence เป้าหมาย" / "เตรียมไฟล์ส่งงาน" / "capture หน้าจอผลงาน"
---

# cat.live Submission Evidence (หลักฐานส่งตรวจต่อเป้าหมาย)

> ## ⚠️ Machine Guard — ตรวจสอบเครื่องก่อนทำงาน skill นี้ (จำเป็น)
>
> Skill นี้ผูกกับเครื่องเฉพาะ เพราะอ้างอิง path/workspace ของ cat.live บนเครื่องนี้เท่านั้น
>
> **เครื่องที่อนุญาต (ผ่านถ้าตรงชุดใดชุดหนึ่ง):**
>
> **เครื่อง A (เครื่องหลัก Admin):**
> - Platform: Windows
> - User: `Admin` หรือ account sandbox ที่ลงท้ายด้วย `\\codexsandboxoffline`
> - Workspace path ที่ต้องมีอยู่จริง: `C:\Users\Admin\Desktop\cat.live\` (หรือ `C:\Users\Admin\Desktop\TukDaeng\`)
>
> **เครื่อง B (เครื่อง mailt):**
> - Platform: Windows
> - User: `mailt`
> - Workspace path ที่ต้องมีอยู่จริง: `D:\cat.live\` (หรือ `D:\TukDaeng\`)
>
> **ถ้าไม่ใช่เครื่องที่อนุญาต:** หยุดทำงาน skill นี้ทันที แจ้งผู้ใช้ว่า skill นี้ใช้ได้เฉพาะเครื่องของ Admin หรือ mailt เท่านั้น

Workflow สำหรับจัด **ชุดหลักฐานส่งตรวจรับงานด้วย AI** ของแต่ละ **เป้าหมาย (Objective)** ใน Mission — มุ่งเพิ่มโอกาสให้หลักฐานครบและตรวจสอบย้อนกลับได้ตามเกณฑ์ **AI Worklog QA Auditor (Gemini Multimodal)**; คะแนน 9.8–10.0 หรือสถานะ APPROVED เป็นเป้าหมาย ไม่ใช่ผลที่รับประกัน ผลลัพธ์คือ "ของที่ต้องแนบ + คำอธิบายที่ต้องวาง + ช่อง external_url ที่ถูกต้อง" พร้อม copy block ให้ก๊อปลงฟอร์มส่งตรวจได้ทันที **ไม่ส่งข้อมูลไปยังระบบภายนอกใด ๆ อัตโนมัติ**

## Checklist บังคับ (อ่านก่อนเสมอ — ทำครบทุกข้อก่อนส่งชุดหลักฐาน)

**0. Machine Guard ก่อนทุกอย่าง** — ตรวจเครื่องตามบล็อกด้านบน; เครื่องผิด = หยุดทันที

**ลำดับบังคับ:**

1. ยืนยันเป้าหมายเสร็จจริง — ทุก task ของเป้าหมายเป็น `done` แล้ว อ่าน task notes/description เพื่อรู้ artifact จริง **ห้ามเดา**
2. จำแนกประเภทผลงาน (6 รูปแบบ) — แยก **Work Artifact** (ไฟล์ที่เป้าหมายผลิต) ออกจาก **Preview Packaging** (ไฟล์ที่สร้างเพื่อทำหลักฐาน)
3. จัด artifact ตาม convention repo — งานที่มี test ต้อง**รันจริง + raw runner output ดิบ**, flow dynamic ต้องมี screencast/ภาพลำดับ, scope accessibility ต้องมี direct assertion จริง
4. คัดชุดไฟล์แนบ — เฉพาะหลักฐานงานจริงราย task; **ห้ามแนบ packaging ลอย / ไฟล์ภาพรวมเป้าหมาย / เนื้อเดียวกัน 2 รูปแบบ**
5. **Evidence Reconciliation Gate** — `.spec.js` ทุกไฟล์ที่รันจริงต้องมี raw output ตรงกัน; เคส skipped/blocked ทุกเคสต้องมี triage note; ห้ามสร้าง raw output ย้อนหลัง; ห้าม claim zero issues ในส่วนที่ไม่มีหลักฐาน
6. `external_url` — เฉพาะงานจริงที่ commit; **blacklist เด็ดขาด: `deliverables/`, `screenshots/`, commit เดียวกันซ้ำทุกเป้าหมาย, commit ที่สร้างไฟล์หลักฐาน** — trace ไม่ได้ให้เว้นว่าง + ชี้แจงในคำอธิบาย
7. ส่งออก: copy block ฟอร์มส่งตรวจ + compact Mission Objective–Feature–Task + คำอธิบายที่เปิดเผย gap/limitation จริง

**Self-check ก่อนส่ง:** เทียบชุดหลักฐานกับ checklist นี้ — ถ้าขาดข้อไหนห้ามส่ง ให้ย้อนทำให้ครบก่อน

---

## เกณฑ์การประเมินของ AI Worklog QA Auditor (Gemini Multimodal)

ระบบประเมินผลงานผ่าน AI Worklog QA Auditor ใช้โมเดลแบบ Multimodal ที่ตรวจสอบทั้งข้อความ รูปภาพหน้าจอ โค้ด และ Metadata โดยให้คะแนน 4 ด้านรวม 10.0 คะแนน และออกสถานะการประเมิน:

| มิติการประเมิน | คะแนนเต็ม | สิ่งที่ระบบตรวจ & เงื่อนไขคะแนนเต็ม | จุดเสี่ยงที่ทำให้คะแนนตก / โดนหัก |
|---|---|---|---|
| **1. ความครบถ้วนหลักฐาน (Evidence Completeness)** | 3.0 | • มีภาพ/ไฟล์แนบพิสูจน์ผลงานครบทุก flow<br>• **ระบุช่อง `external_url` ชัดเจน** (เช่น ลิงก์ GitHub Commit หรือ Pull Request)<br>• มี Checklist Card นำหน้างานเอกสาร/test | • **ไม่ระบุ `external_url` (โดนหัก -0.5 ถึง -1.4 ทันที และตกเป็น PASS WITH COMMENTS)**<br>• แนบแต่ไฟล์ text ล้วน ไม่มีภาพ preview<br>• ขาดภาพขั้นตอนสำคัญหรือขาดจอ Mobile |
| **2. ความสมเหตุสมผลเวลา (Time Reasonableness)** | 3.0 | • เวลาที่ใช้สัมพันธ์กับขอบเขตงานจริง<br>• หากเวลากระชับ/สั้น (เช่น 0.5-1.0 ชม.) มีคำอธิบาย **Methodology** ชัดเจน (เช่น Template-based, Spec sync, Automated script) | • งานขนาดใหญ่แต่เคลมเวลาน้อยเกินจริงโดยไม่อธิบายวิธีทำ (AI จะมองว่า manual เป็นไปไม่ได้)<br>• เวลาบวมเกินเกณฑ์โดยไม่มีเหตุผลทางเทคนิครองรับ |
| **3. การส่งมอบและรอบส่ง (Delivery & Submission Round)** | 2.0 | • ส่งรอบแรก (#1) ผ่านทันที<br>• ส่งตรงเวลา ขอบเขตและชื่องานชัดเจน สอดคล้องกับ Kanban Task/Objective | • ส่งงานซ้ำหลายรอบเนื่องจากแก้บั๊กไม่จบ<br>• ขอบเขตงานคลุมเครือไม่ตรงกับชื่องาน |
| **4. คุณภาพและความละเอียด (Quality & Thoroughness)** | 2.0 | • **Zero Issues Found** ในภาพและตัวงาน<br>• รองรับ Desktop (1440px) และ Mobile (390px) สมบูรณ์<br>• UI Edge Cases ผ่าน (Empty State, Overflow, Spacing, Masking, Error states)<br>• ไม่มีคำสะกดผิด (Typo) ใน Mock Data | • AI ตรวจพบ Bug ในภาพ (เช่น Pagination แสดง 1/1 ในหน้า Empty, จอ mobile เบียด/ล้น)<br>• มี Typo ในข้อมูล (เช่น 'Admin manament')<br>• มี Technical Debt หลุดโดยไม่อธิบาย |

### กฎสำคัญ: การได้สถานะ "APPROVED" vs "PASS WITH COMMENTS"
- **APPROVED (เป้าหมาย 9.8 - 10.0):** ในกล่องสีแดง `Bug หรือจุดผิดปกติที่สังเกตพบในภาพ/หลักฐาน (Issues Found)` ต้องขึ้นว่า **"ไม่พบ Bug หรือจุดผิดปกติในหลักฐานที่ส่งมา"** เท่านั้น
- **PASS WITH COMMENTS (8.3 - 9.5):** เกิดขึ้นทันทีเมื่อมีข้อความในกล่อง Issues Found แม้เพียง 1 ข้อ (โดยเฉพาะการลืมใส่ `external_url` หรือมีจุดบกพร่องเล็กน้อยในรูปภาพ)

---

## When to Trigger

- เป้าหมายใน Mission ทำครบทุก Task แล้ว (ปลายทางของ workflow ปิด task) → เสนอ/สร้างหลักฐานส่งตรวจของเป้าหมายนั้น
- ผู้ใช้ขอโดยตรง: "เตรียมหลักฐานส่งตรวจเป้าหมาย N", "capture หน้าจอผลงาน", "ทำ evidence package", "สรุปผลการส่งมอบงาน"
- ผู้ใช้ถามว่า "เป้าหมาย N ต้องส่งหลักฐานอะไร" หรือ "เตรียมส่งงาน AI Auditor"

**ข้อแยกกับ skill อื่น:**
- `mission-planning` — วางแผนและสรุปผลระดับ Mission (มีหมวด Evidence แบบกว้าง); skill นี้ทำ **submission package จริง** ต่อเป้าหมาย
- `work-summary` — สรุประดับ Task เมื่อปิด task; skill นี้ทำงาน **ระดับเป้าหมาย** (รวมหลาย Task)
- `eval-qa-assistant` — ตอบคำถามประเมินผลงาน; skill นี้จัด **ไฟล์และข้อความสำหรับฟอร์มส่งตรวจ**

---

## ขั้นตอนการเตรียมหลักฐาน

### 1. ยืนยันว่าเป้าหมายเสร็จจริง

- ดึง mapping Objective → Task จาก Mission Plan / Kanban (`get_board`, `get_task`)
- ทุก Task ของเป้าหมายต้องเป็น `done` — ถ้ายังมี task ค้าง ให้แจ้งว่าเป้าหมายยังไม่ครบ อย่าสร้างหลักฐานแบบ "เสร็จ"
- อ่าน task notes/description เพื่อรู้ว่าเป้าหมายผลิต artifact อะไรจริง — **ห้ามเดา**
- **ดึงหลักฐานจากราย task ที่บันทึกไว้ตอนปิด task** (task evidence bundle ตาม workflow `work-summary`: ภาพ Before/After, checklist ที่ตรวจแล้วพร้อมผลรายเคส, raw test output + test list, รายการไฟล์/commit) มาคัดเลือกและรวมเป็นชุดส่งตรวจของเป้าหมาย — ขั้นตอนนี้คือการ "รวมและคัด" หลักฐานราย task ที่มีอยู่แล้ว ไม่ใช่สร้างหลักฐานใหม่ย้อนหลัง

### 2. จำแนกประเภทผลงานของเป้าหมาย (6 รูปแบบงาน)

| รูปแบบงาน | หลักฐานที่ถูกต้อง | ตัวอย่างที่ได้ 10.0 APPROVED |
|---|---|---|
| **1. แก้ไข UI / Prototype (Bug Fix / Refactor)** | **ภาพหน้าจอ Before & After** (คู่ Desktop 1440 + Mobile 390) แคป Before ก่อนแตะโค้ด และ After ณ จุดที่ผู้ใช้ยืนยันคอนเฟิร์มว่าผ่าน | ภาพ Before/After แก้ Filter dropdown clipping, Modal button order, Focus trap |
| **2. สร้าง UI ใหม่ (New Feature / New Screen)** | **ภาพหน้าจอทุก State สำคัญ** (Empty, Default, Modal, Result, Mobile 390) ครบทุก flow | precedent 10/10: "สร้าง Audit Log List และ Detail Modal" (4 รูป = list+detail × desktop+mobile), "เพิ่ม Search, Filter, Sort และ Date Range" (7 รูป) |
| **3. Automated Test / QA / Regression** | **ไฟล์ `.spec.js` จริง** + **ผลรันจริงเป็น raw runner output** (`test-results.txt` ดิบจาก Playwright) + **ภาพ Checklist Card PNG** แยกตาม spec + **ภาพ Playwright HTML Report (dashboard) หรือภาพ/screencast พฤติกรรม UI สำคัญที่ test ตรวจ** — raw log + checklist อย่างเดียวไม่พอ auditor เคยหักเพราะขาดหลักฐานภาพหน้าจอ | precedent 10/10: "QA, Regression และ Protected Screen" (5 รูป checklist `qa-bo-014a/b/c/d` + raw output `1822 passed / 55 skipped`) |
| **4. Manual QA / Inspection (ไม่มีโค้ดแก้)** | **Checklist แยกราย task** (file + Checklist Card PNG คู่กัน 1 task = 1 ชุด) แสดงทุกเคส/viewport ที่ตรวจ + ภาพหน้าจอ findings (ถ้ามี) — **ต้องจด/บันทึก checklist ตั้งแต่ตอนตรวจจริง ไม่ reconstruct ทีหลังจาก log** | precedent 10/10: "BOA-017 Manual QA Checklist" (Checklist Card 18 รายการตรวจครบทุกจอ) |
| **5. เอกสาร / Spec Sync / Baseline Lock** | **ไฟล์ `.md` จริง** ที่แก้ + **Git Commit Hash** ใน note + **ภาพ Checklist Card PNG** สรุปรายการไฟล์และเกณฑ์ | precedent 10/10: "Sync Audit Log Spec" แนบ `08_AUDIT_LOG_MODULE.md` + ภาพ checklist สรุป 5 Acceptance Criteria |
| **6. Final Acceptance / Mission Closure** | **รายงาน Final Acceptance Review (.txt)** + **ภาพ Checklist Card PNG** สรุป Traceability, Verification Gates และ Verdict PASS | precedent 10/10: "Final Mission Acceptance" (Checklist Card สรุปทุก Gate ผ่าน 100%) |

**หลักการเลือกประเภทหลักฐาน:** ส่ง "สิ่งที่ reviewer ตรวจได้จริงและเห็นได้ทันที" — ภาพ preview ในฟอร์มแข็งแรงที่สุด; เอกสาร/test แนบไฟล์จริงประกอบ แต่ต้องมีภาพสรุปนำหน้า; งาน UI ต้อง capture ครบทั้ง desktop และ mobile

**หลักการ 2 ชั้น (Work Artifact vs Preview Packaging):**
- **Work Artifact (ชั้นพิสูจน์จริง):** ไฟล์ที่เป้าหมายผลิตขึ้นจากการทำงาน — `.spec.js`, ผลรันดิบของ runner, เอกสารที่แก้, โค้ดที่ commit — ชั้นนี้เท่านั้นที่ใช้เป็น **เป้าหมายของ `external_url`** และเป็น proof-of-work
- **Preview Packaging (ชั้นนำหน้า):** ไฟล์ที่สร้างขึ้นเพื่อทำหลักฐาน — checklist card PNG, terminal-style PNG จาก `render-test-output.js`, ภาพใน `screenshots/`, ชุดไฟล์ใน `deliverables/`, capture/render scripts — ชั้นนี้**แนบประกอบเพื่อให้ preview ได้เท่านั้น ห้ามนับเป็น proof-of-work และห้ามใช้ commit ที่สร้างมันเป็น `external_url`**
- `test-results.txt` ต้องเป็น **raw runner output ที่เครื่องมือเขียนเอง** (บันทึกการทำงานจริง) ไม่ใช่ summary ที่เขียนขึ้นเพื่อส่ง — summary ที่เขียนเองจัดเป็น packaging ซ้ำหน้าที่ checklist card และอ่อนกว่า raw output

---

### 3. จัด Artifact ตาม convention ของ repo

> **หมายเหตุสำคัญ:** หลักฐานหลักควรถูกเก็บไว้แล้วระหว่างทำและตอนปิดแต่ละ task (task evidence bundle ตาม `work-summary`) — ขั้นตอนนี้ใช้สำหรับ **ตรวจความครบของหลักฐานที่มี + เติมเฉพาะจุดที่ขาด** เท่านั้น ไม่ใช่ capture/สร้างหลักฐานทั้งชุดใหม่ย้อนหลัง; ถ้าพบหลักฐานขาด (เช่น ไม่มีภาพ Before, raw output หาย) ให้บันทึกเป็น evidence gap ตรง ๆ หรือ capture เติมเฉพาะจุดนั้นเมื่ออยู่ใน scope และได้รับอนุมัติ

**งาน UI — capture ภาพหน้าจอ Before & After (ต้องครบ flow × 2 จอ):**
- **Continuous Capture Workflow:**
  - **Before (ก่อนเริ่มแตะโค้ด):** แคปภาพสภาพเดิมก่อนเริ่มแก้โค้ดลง `screenshots/mission-<N>-objective-<M>/before/` ทั้ง Desktop (1440) และ Mobile (390)
  - **After (Auto-Trigger เมื่อผู้ใช้บอกโอเค/สั่งปิด task):** เมื่อผู้ใช้ตรวจผลงานแล้วพูดว่า *"โอเค"*, *"ผ่าน"*, *"ปิด task ได้เลย"*, *"เสร็จแล้ว"* ให้ระบบถือเป็นคำอนุมัติ (Approval) และรันแคปภาพผลลัพธ์ปัจจุบันใน `screenshots/mission-<N>-objective-<M>/after/` (1440 + 390) อัตโนมัติทันทีก่อนย้าย task เข้า `done` โดยไม่ต้องถามซ้ำซ้อน; หากมีการปรับแก้หลายรอบ ให้แคปเฉพาะสภาพสุดท้ายที่ผู้ใช้คอนเฟิร์มผ่าน
- เขียน/ใช้ capture script ใน `scripts/` ตั้งชื่อ `capture-m<N>-obj<M>-<scope>.js`
- ผลภาพลง `screenshots/mission-<N>-objective-<M>/`
- รัน local server ก่อน capture: `python -m http.server 8080` จากโฟลเดอร์ `Prototypes` แล้ว capture จาก `http://localhost:8080/bo-prototype.html` — ปิด server เมื่อเสร็จ
- **capture ครบทุกขั้นตอน flow ของเป้าหมาย** — เขียนรายการ state/flow จาก task log ก่อน แล้ว capture ทีละขั้น (เปิด modal → กรอก → submit → ผลลัพธ์ → error/edge)
- **ทุกขั้นตอน capture ทั้ง desktop (1440) และ mobile (390) คู่กัน**
- ตั้งชื่อภาพบอก state ชัด (เช่น `filter_date_desktop.png`, `detail_pill_reference_mobile.png`)

**Multimodal Quality Inspection — ตรวจสอบภาพก่อนส่งเพื่อป้องกัน AI หักคะแนน:**
1. **blur ก่อนแคปทุกครั้ง** (`document.activeElement?.blur()`) ป้องกัน focus ring ติดในภาพ
2. **element shot ต้องเว้นขอบ** ใช้ clip ขยาย ~20px รอบ element
3. **auth screens บน mobile ห้ามใช้ `fullPage` ตรง ๆ** ให้คำนวณ `scrollHeight` แล้วขยาย viewport
4. **ตรวจ Empty State:** ตรวจสอบว่าหากเป็นหน้าไม่มีข้อมูล (0 records) แถบ Pagination ต้องซ่อนหรือปิดการใช้งาน (ไม่แสดงปุ่ม "1" หรือ "1/1" ค้าง)
5. **ตรวจ Typo ในข้อมูล Mockup:** ระวังคำผิดภาษาอังกฤษ (เช่น 'management' ห้ามพิมพ์ผิดเป็น 'manament') เพราะ Gemini Multimodal OCR อ่านข้อความในภาพ
6. **ตรวจ Mobile Spacing:** ในจอ 390px ตรวจสอบว่าหัว Modal หรือปุ่ม Action ไม่ชิดขอบจอเกินไป และไม่มี element ซ้อนทับกัน

**งานเอกสาร/test — จัด package ไฟล์จริง + ภาพสรุป:**
- คัดลอกไฟล์จริงไป `deliverables/mission-<N>-obj<M>-<topic>/` แล้ว zip เป็น `deliverables/mission-<N>-obj<M>-<topic>.zip` — สำหรับเป้าหมาย test **ต้องคัดลอก `.spec.js` ที่รันจริงเข้า package ด้วย**
- งานที่มี test **ต้องรัน test จริงก่อน zip** แล้วเก็บ **raw runner output ดิบ** ลง `test-results.txt` ใน package — ห้ามเขียน summary เองแทน; ถ้าอยากได้ภาพผลรันให้ render ด้วย `scripts/render-test-output.js`
- **เป้าหมาย test/QA: สร้าง checklist card แยกตาม spec** ด้วย `scripts/render-test-checklist.js`
- **เป้าหมายเอกสาร/acceptance: สร้าง checklist card สรุป** ด้วย `scripts/render-checklist-card.js`
- ภาพ checklist card ต้องพอดีตัว card ไม่เหลือพื้นว่างด้านล่าง
- **เนื้อหา checklist card เอาแค่ title + ขั้นตอนตรวจ + รายการเคสที่ check** — ห้ามใส่ meta/work log/ผลตรวจรับ/ข้อมูลอ้างอิงภายนอกลงใน card (หลักฐานคือผลตรวจจริงเท่านั้น)

**Automation Run ต้องมีหลักฐานภาพประกอบเสมอ (Visual Companion Evidence):**
- **Raw log อย่างเดียวไม่พอ** — auditor เคยหักคะแนนหลายรอบเมื่อส่งแค่ `test-results.txt` + checklist โดยไม่มีภาพ UI: ต้องแนบ **ภาพ Playwright HTML Report dashboard** (`npx playwright show-report` แล้ว capture) หรือภาพหน้าจอพฤติกรรมที่ test ตรวจ อย่างน้อย 1–2 ภาพต่อเป้าหมาย test
- **Flow ที่มีพฤติกรรม dynamic** (countdown lockout, error live, focus trap, toast, async state) ให้แนบ **screencast สั้น ๆ** (เช่น Loom) หรือภาพเป็นลำดับขั้นตอน — ภาพเดียวพิสูจน์พฤติกรรมต่อเนื่องไม่ได้
- **เก็บ Playwright artifacts** (`playwright-report/`, `test-results/` traces/videos) ไว้ใน repo หรือ package ให้ trace ย้อนหลังได้ — ห้ามลบทิ้งหลังรัน
- **เคส skipped/blocked ทุกเคสต้องมี triage note** ระบุเหตุผล (project gating / environment / out of scope) และการ reconcile — ห้ามส่งผลรันที่มี skipped ลอย ๆ โดยไม่มีคำอธิบาย
- **ถ้า scope ครอบ accessibility** (numerical contrast, focus trap, dialog role/aria-modal) ต้องมี direct assertion จริง (เช่น axe-core/playwright) — ถ้าทำไม่ได้ให้ระบุเป็น evidence limitation พร้อมเหตุผลในคำอธิบาย ห้ามปล่อยว่างให้ auditor ค้นเจอเอง

---

### 4. คัดชุดไฟล์สำหรับแนบ

- **แนบไฟล์จริงทีละไฟล์เป็นค่าเริ่มต้น** เพื่อให้ reviewer และ AI มองเห็น preview ได้ทันที
- **ทุกไฟล์แนบต้อง trace กลับไปหางานของเป้าหมาย** — Work Artifact (ไฟล์ที่เป้าหมายผลิต เช่น `.spec.js`, raw run output, เอกสารที่แก้) คือตัวพิสูจน์หลัก; Preview Packaging (checklist card, ภาพ render, screenshots) แนบประกอบเพื่อให้เห็นได้ทันทีเท่านั้น — **ห้ามส่งแต่ packaging โดยไม่มี work artifact**
- **ทุกเป้าหมายต้องมีภาพที่ preview ได้อย่างน้อย 1 รูป** (เป้าหมาย UI ใช้ภาพหน้าจอ, เป้าหมายเอกสาร/test ใช้ Checklist Card)
- **ภาพหน้าจอ:** แนบทุกรูปที่พิสูจน์พฤติกรรมต่างกันของเป้าหมาย ครบทั้ง desktop และ mobile
- **แนบเฉพาะหลักฐานงานจริงราย task — ห้ามแนบไฟล์ภาพรวมเป้าหมาย:** summary card ระดับ objective, รายงานรวม, และไฟล์สรุปที่สร้างเพื่อทำหลักฐาน เก็บไว้ใน repo เป็น reference เท่านั้น ไม่ต้องแนบลงฟอร์ม
- **ห้ามแนบเนื้อหาเดียวกันซ้ำสองรูปแบบ:** ถ้า `.txt` กับ `.png` มีเนื้อเดียวกัน ให้แนบเฉพาะ `.png` ที่ preview ได้ (เก็บ `.txt` เป็น source ใน repo) — ข้อยกเว้นคือเอกสาร/report ที่ `.txt` เป็นตัวงานจริงและ card เป็นแค่ตัวนำหน้า
- **ไฟล์แนบต้องเปิด/preview ได้สะดวก:** PDF ใหญ่กว่า ~15MB ให้บีบอัด (compressed PDF) หรือส่งเป็น HTML ที่มี anchor links / print CSS แทน — ไฟล์ที่ reviewer เปิดไม่ได้หรือเปิดช้าถูกนับเป็น issue (เคยโดนหักจาก PDF ~75MB)

### Evidence Reconciliation Gate — บังคับก่อนส่ง

สำหรับทุก Objective ประเภท test/verification ให้ทำตาราง traceability จาก Kanban task activity → suite/command → source spec → result → สิ่งที่แนบ โดยตรวจตามนี้:

1. บันทึกรายชื่อ `.spec.js` ทุกไฟล์ที่รันจริง แยกตาม Task; ห้ามเลือกเฉพาะ spec ที่เกี่ยวข้องบางส่วนแล้วอ้างว่าแทนทั้ง suite
2. แนบ source `.spec.js` ทุกไฟล์ที่รันจริง หรือรวมทั้งหมดใน ZIP เมื่อจำนวนมาก; ตรวจจำนวนไฟล์ใน ZIP ให้ตรงกับ run inventory และเทียบ hash กับ source ใน repo เพื่อยืนยันว่าเป็นไฟล์จริงที่ไม่ถูกแก้
3. `external_url` ต้องชี้ไปยังไฟล์หรือ directory ที่ครอบคลุมชุด spec ที่รันจริง: งานหลาย spec ใช้ tests directory พร้อมแนบ spec bundle; งาน single spec ให้ชี้ไฟล์นั้นโดยตรง
4. เก็บ raw stdout/stderr จาก runner ณ เวลารันโดยไม่แก้เนื้อหา และแยกจาก manifest/checklist/summary อย่างชัดเจน
5. ถ้า raw output ถูกล้างหรือไม่มีอยู่ ห้ามสร้างย้อนหลังหรือเรียก summary ว่า raw output ให้ระบุชัดว่าเป็น run summary และบอกแหล่งข้อมูล; rerun เพื่อเก็บ raw output ได้เฉพาะเมื่ออยู่ใน scope และได้รับอนุมัติ
6. บันทึก evidence gap, assertion ที่ไม่มี, project gating และ limitation แยกจาก product defect; ห้ามใช้คำว่า zero issues หรือ claim ว่าตรวจครบในส่วนที่ไม่มีหลักฐานรองรับ
7. ตรวจว่า task count, case count, passed/skipped/failed, exit code, run configuration และวันที่ในคำอธิบายตรงกับ Kanban และ artifacts ทุกจุด
8. เคส skipped/blocked ทุกเคสต้องมี triage note (เหตุผล + การ reconcile) แนบเป็นไฟล์หรือระบุในคำอธิบาย — ห้ามส่งผลรันที่มี skipped โดยไม่อธิบาย

---

### 5. ช่อง external_url — ใส่เฉพาะงานจริงที่ commit แล้ว

> ⚠️ **คำเตือนสำคัญที่สุด:** จากการวิเคราะห์ผลการประเมินย้อนหลัง **การปล่อยช่อง URL ว่างทั้งที่มี work artifact จริง คือสาเหตุหลักอันดับ 1 ที่ทำให้โดนหักคะแนน Evidence Completeness เหลือ 1.6 - 2.5/3.0 และถูกลดสถานะเป็น PASS WITH COMMENTS ทันที** — ในทางกลับกัน การฝืนใส่ลิงก์ที่ไม่ใช่งานจริง (เช่น commit ที่สร้างไฟล์หลักฐาน) ก็ทำให้หลักฐานไม่น่าเชื่อถือ

**กฎเหล็ก:** **ใส่ URL เฉพาะเมื่อมี Work Artifact จริงที่ commit ไว้ใน repo ของโปรเจกต์** — ต้องชี้ไปยัง Work Artifact / Source Code / Test Spec / Specific Commit จริงของเป้าหมายนั้นเท่านั้น:

- เป้าหมายที่มีการแก้ไฟล์งานจริงในโปรเจกต์ (โค้ด, prototype, spec, test) → **ต้องใส่ URL เสมอ ห้ามเว้นว่าง**
- เป้าหมาย read-only / manual inspection (เช่น เช็คเทียบเอกสารกับ prototype, ตรวจหน้าจอ/audit โดยไม่แก้ไฟล์งานจริง) ที่ไม่มี artifact commit จริง → **เว้นว่างได้** และต้องเปิดเผยในคำอธิบายว่างานเป็น manual inspection ไม่มี work artifact ที่ commit — ยอมรับความเสี่ยงคะแนนช่องนี้ดีกว่าส่งลิงก์ที่ไม่ใช่งานจริง
- ห้ามฝืนใส่ลิงก์ทุกเป้าหมายเพื่อให้ "ไม่ว่าง" — ลิงก์ที่ไม่ trace ไปหางานจริงแย่กว่าการเว้นว่างพร้อมชี้แจง:

#### ❌ สิ่งที่ห้ามใส่ในช่อง URL โดยเด็ดขาด (Blacklist):
- **ห้ามใส่ path `deliverables/` ทุกชนิด** เช่น `.../deliverables/.../test-results.txt` หรือ `.../deliverables/.../checklist-*.txt` (เพราะเป็นโฟลเดอร์ packaging รายงานผล ไม่ใช่ source artifact)
- **ห้ามใส่ path `screenshots/`** เช่น `.../screenshots/.../checklist-*.png`
- **ห้ามใส่ Commit Hash เดียวกันซ้ำทุกเป้าหมาย** โดยเฉพาะ commit ที่สร้างไฟล์ deliverables

#### ✅ สิ่งที่ต้องใส่ในช่อง URL แยกตามประเภทงาน (Whitelist & Priority):
1. **งานทดสอบ / QA / Verification (Objective 1, 2, 3):**
   - **กรณีมีไฟล์สเปกเฉพาะเป้าหมาย:** ชี้ตรงไปยังไฟล์ `.spec.js` หลักของเป้าหมายนั้นโดยตรง เช่น:
     `https://github.com/kultida-t/cat.live/blob/prototype/tests/<target-spec>.spec.js`
   - **กรณีรันทั้ง Suite / หลายสเปก (เช่น Regression ทั้งระบบ):** ชี้ไปยังโฟลเดอร์เทสต์ `https://github.com/kultida-t/cat.live/tree/prototype/tests`
2. **งานแก้โค้ด / ปรับสเปก / แก้เอกสาร (Objective 4):**
   - ชี้ไปยัง **Git Commit ที่แก้/ล็อกไฟล์จริง** เช่น `https://github.com/kultida-t/cat.live/commit/<commit-hash>` หรือชี้ตรงไปยังไฟล์เอกสารหลัก เช่น `https://github.com/kultida-t/cat.live/blob/prototype/BackOffice/BO_MASTER_BASELINE.md`
3. **งาน Final Acceptance / Closure (Objective 5):**
   - ชี้ไปยัง **Branch root ของโปรเจกต์** เช่น `https://github.com/kultida-t/cat.live/tree/prototype` หรือ Commit ปิดรอบ
4. **งาน Manual Inspection / Read-only Audit (ไม่มี work artifact commit จริง):**
   - งานที่ผลลัพธ์คือการตรวจ/audit สิ่งที่มีอยู่แล้วโดยไม่ได้ commit ไฟล์งานจริงของโปรเจกต์ — **ห้ามชี้ commit ที่สร้างไฟล์หลักฐาน** (ขัดกฎ Work Artifact เดิม)
   - ลำดับเลือก: (1) ชี้ไฟล์ที่ถูกตรวจ เช่น `Prototypes/bo-prototype.html` (2) ชี้เอกสารผลงานจริงใน `docs/` (3) ถ้าไม่มีอะไร trace ได้จริง → **เว้นว่างได้และเปิดเผยในคำอธิบาย** ว่างานเป็น manual inspection — ยอมรับความเสี่ยงคะแนน URL ดีกว่าส่งลิงก์ที่ไม่ใช่งานจริง

---

### 6. เขียนคำอธิบาย (Description) — กฎภาษาคนทำงาน (Developer/QA Tone)

- **ภาษาคนทำงานจริง กระชับ ตรงไปตรงมา (No Official Boilerplate / No AI Meta-commentary):**
  - ❌ **ห้ามใช้ภาษาทางการ/ราชการ:** เช่น *"ดำเนินการทดสอบ"*, *"ดำเนินการตรวจรับ"*, *"ดำเนินการ sync"*, *"การทดสอบดำเนินการผ่าน"*, *"ได้ดำเนินการ"*
  - ❌ **ห้ามใช้ประโยครายงานบุคคลที่สาม/มุมมอง AI (AI Meta-phrases):** เช่น *"ผู้ใช้ตรวจสอบและอนุมัติแล้ว"*, *"ผู้ใช้ได้ตรวจรับ"*, *"AI ได้ทำการ..."*, *"ได้รับความเห็นชอบจากผู้ใช้"* — ให้เขียนจากมุมมองคนทำงานสรุปผลงานของตัวเอง เช่น *"สรุปผลตรวจรับทุก Gate ผ่านครบ 100% ปิด Mission สมบูรณ์"*
  - ✅ **ต้องใช้ภาษาคนทำงาน:** เช่น *"ทดสอบ"*, *"รันเทส"*, *"เช็ค"*, *"อัปเดต"*, *"sync"*, *"ตรวจรับครบทุกเงื่อนไข ปิด Mission เรียบร้อย"*
- **ใช้คำทับศัพท์มาตรฐาน UI/Web ตรงตัว (ห้ามใส่วงเล็บแปลไทยสลับอังกฤษเด็ดขาด):**
  - คำศัพท์มาตรฐานที่ชัดเจนในตัวมันเองให้ใช้คำนั้นตรง ๆ เช่น `list`, `detail`, `modal`, `filter`, `dropdown`, `sidebar`, `breadcrumb`, `viewports`, `editor`, `button hierarchy`, `keyboard focus/trap`, `happy path`, `regression`, `E2E`, `triage`, `project gating`, `product defect`, `flaky test`, `rate limit`, `audit log`, `delivery log`
  - **ห้ามใส่วงเล็บแปลไทยสลับอังกฤษ (Zero Bilingual Parentheses)** เช่น ห้ามเขียน `คัดกรองผลลัพธ์ (Regression Triage)`, ห้ามเขียน `ไม่มีข้อผิดพลาด (Zero Product Defects)`, ห้ามเขียน `ขนาดหน้าจอ (Viewports)` — ให้เลือกใช้คำที่คนทำงานคุยกันจริงเพียงคำเดียว
  - **ห้ามแปลไทยทางการหรือแปลตรงที่อ่านยาก** เช่น ไม่แปล modal เป็น "หน้าต่างป๊อปอัปยืนยัน", ไม่แปล breadcrumb เป็น "แถบบอกตำแหน่งหน้า", ไม่แปล filter เป็น "แถบกรองข้อมูล"
- **ห้ามใช้คำสร้อยหรือคำขยายอารมณ์ที่ไม่จำเป็น (No Fluff / Idioms):**
  - ห้ามใช้คำเช่น "ผ่านฉลุย", "อย่างเข้มงวด", "ราบรื่น", "สวยงาม", "ยอดเยี่ยม" — ให้เขียนรายงานผลตามข้อเท็จจริงและตัวเลขจริง เช่น *"ผลการรันผ่าน 1,822 passed / 0 failed / 55 skipped"*
- **ระบุ Methodology ชัดเจนเมื่อเวลาทำงานกระชับ (ป้องกันการหักคะแนน Time Reasonableness):**
  - หากใช้เวลา 0.5 - 1.0 ชม. สำหรับงานหลายไฟล์หรือ test suite ขนาดใหญ่ ให้ระบุชัดเจน เช่น:
    *(ตัวอย่าง)*: *"ปรับปรุงและ sync เอกสารสเปก 5 ไฟล์ให้ตรงตาม Contract ฐานเดิม พร้อมรัน automated test suite ตรวจสอบความถูกต้องโดยใช้เครื่องมืออัตโนมัติ ไม่ได้แก้ไขแบบ manual ใหม่ทั้งหมด ทำให้ใช้เวลาได้อย่างมีประสิทธิภาพสูง"*
- **คำอธิบายสรุปแยกราย task:** เขียนเป็น `Task code: ทำอะไร → ผลอะไร` ทีละบรรทัด เพื่อให้เห็นว่าแต่ละ task ทำจริงตรงเป้าหมาย ไม่เขียนเป็นย่อหน้าภาพรวมเดียว
- **อ้างตำแหน่งในเอกสารด้วยคำว่า "หมวด"** เช่น `หมวด 10.1` — **ห้ามใช้สัญลักษณ์ `§`**
- **เครื่องมือจำลอง (Testing Helper):** หากในภาพมีปุ่ม Prototype Scenario Selector ให้ชี้แจงสั้น ๆ ว่าเป็น *"เครื่องมือจำลองสถานะสำหรับการทดสอบ (Prototype Scenario Helper)"* เพื่อไม่ให้ AI มองว่าเป็นโค้ดที่หลุด
- **หลีกเลี่ยงการทิ้งประเด็น Technical Debt ลอย ๆ:** หากมีประเด็นค้าง ให้ระบุว่าได้รับการบันทึกเป็น Deferred Items ลงแผนงานถัดไปเรียบร้อยแล้ว

---

### 7. แสดงผล — Submission Evidence Copy Block ต่อเป้าหมาย

แสดงให้ผู้ใช้ครบ 3 ส่วน: (1) รายการไฟล์แนบพร้อม path, (2) คำตอบช่อง URL, (3) คำอธิบาย — แล้วรวมเป็น copy block:

```text
หลักฐานส่งตรวจรับ — <Mission>

เป้าหมาย <N> <ชื่อเป้าหมาย>

สถานะ: <เสร็จ / รอตรวจสอบ>

Task ที่เกี่ยวข้อง: <task code 1>, <task code 2>

ไฟล์แนบ:

- <path/ชื่อไฟล์ 1> — <อธิบายสั้นว่าพิสูจน์อะไร>
- <path/ชื่อไฟล์ 2> — <อธิบายสั้น>

ช่อง URL: https://github.com/kultida-t/cat.live/commit/<commit-hash> (หรือ Pull Request / ไฟล์ work artifact จริง / เว้นว่างเฉพาะ manual inspection ที่ไม่มี artifact จริง)

คำอธิบาย

- <งานที่ทำในเป้าหมายสั้น ๆ + Methodology ตามกฎข้อ 6>
```

รูปแบบ (อัปเดตเพื่อมาตรฐาน AI Worklog QA Auditor):
- ชื่อเป้าหมายแยกบรรทัดใต้หัวข้อ mission
- แต่ละ field คั่นด้วยบรรทัดว่าง
- `ไฟล์แนบ` แต่ละรายการระบุ path เต็ม
- `ช่อง URL` มีลิงก์ GitHub Commit / Pull Request / ไฟล์ work artifact จริง เมื่อเป้าหมายมีการ commit งานจริง — เว้นว่างได้เฉพาะ manual inspection/read-only ที่ไม่มี artifact จริง และต้องชี้แจงในคำอธิบาย
- `คำอธิบาย` ชัดเจน กระชับ มีการระบุ methodology เมื่อเวลาทำงานกระชับ

---

### 8. บันทึกลง log

- ใส่ส่วน "หลักฐานส่งตรวจ" ของเป้าหมายนั้นใน Work Summary / session note ของ task สุดท้ายของเป้าหมาย (ผ่าน `save_session_note` ตาม workflow ปกติ)
- ห้ามส่งหลักฐานหรือ log ไปยังระบบภายนอกอัตโนมัติ — ทุกอย่างเป็น copy block ให้ผู้ใช้วางเอง

---

### 9. แสดงสรุป Mission แบบ Compact Objective–Feature–Task

หลังเตรียมหลักฐานส่งตรวจของ Mission เสร็จเรียบร้อยแล้ว **ต้องแสดงสรุป Mission เป็น text copy block เดียวต่อท้ายเสมอ**:

- เรียก `get_mission` จาก Kanban อีกครั้งและใช้ข้อมูลที่บันทึกอยู่จริงเท่านั้น — ห้ามเขียนจากความจำ
- ใช้ชั่วโมงรวม จำนวนวัน ชั่วโมงต่อ Objective และ weights จาก Mission baseline ตามค่าที่ Kanban แสดง
- ใช้ verdict จาก Final Acceptance task/activity ที่บันทึกจริง
- แสดงเฉพาะชื่อ Mission, ชั่วโมงรวม/จำนวนวัน, Objective, ชั่วโมง, Feature และ task code ที่เกี่ยวข้อง แล้วปิดท้ายด้วยจำนวน tasks/objectives, weights, สถานะรวม และ verdict
- **ห้ามแสดง Mission ID, UUID หรือรหัสย่อจาก Kanban** เช่น `1800d8aa`
- ต้องครอบด้วย fenced code block ชนิด `text` เพื่อให้ผู้ใช้คัดลอกได้ทันที

รูปแบบบังคับ:

```text
Mission — <ชื่อ Mission> (<ชั่วโมงรวม> ชม. / <จำนวนวัน> วัน)

Objective 1 — <ชื่อ Objective> (<ชั่วโมง> ชม.)

Feature: <ชื่อ Feature> → <Task code>
Feature: <ชื่อ Feature> → <Task code> + <Task code>

Objective 2 — <ชื่อ Objective> (<ชั่วโมง> ชม.)

Feature: <ชื่อ Feature> → <Task code>

รวม <จำนวน tasks> tasks / <จำนวน objectives> objectives / weights <เปอร์เซ็นต์>% — <สถานะรวมและ verdict ที่บันทึกจริง>
```

---

## กฎส่งหลักฐานให้ครบถ้วน (เป้าหมาย APPROVED; ไม่รับประกันคะแนนหรือ verdict)

- ⚠️ **EXTERNAL URL เฉพาะงานจริงที่ commit แล้ว:** ใส่ลิงก์ GitHub Commit/ไฟล์ที่พิสูจน์งานจริงของแต่ละเป้าหมายเฉพาะเมื่อมี work artifact จริง (งานแก้โค้ด/สเปก = Commit ที่แก้ไฟล์จริง, งานเทสต์ = ไฟล์สเปกหรือโฟลเดอร์เทสต์, งานปิดรับ = Commit ล็อก Baseline) — **ลิงก์ต้องชี้ Work Artifact เท่านั้น ห้ามชี้ Preview Packaging** (checklist card, `screenshots/`, `deliverables/`), **ห้ามชี้ commit ที่สร้างไฟล์ deliverables/หลักฐานส่งตรวจซ้ำทุกข้อ** และ **ห้ามฝืนใส่ลิงก์ที่ไม่ใช่งานจริง** — เป้าหมาย manual inspection/เช็คเทียบเอกสาร-prototype ที่ไม่มี artifact จริงให้เว้นว่างและเปิดเผยในคำอธิบาย
- ⚠️ **WORK ARTIFACT FIRST:** ทุกไฟล์แนบและทุกลิงก์ต้อง trace กลับไปหางานของเป้าหมาย — ไฟล์ที่สร้างขึ้นเพื่อทำหลักฐาน (checklist card, render scripts, `deliverables/`) ใช้ประกอบ preview เท่านั้น; เป้าหมาย test ต้องแนบ `.spec.js` จริง + `test-results.txt` ที่เป็น **raw runner output** (ไม่ใช่ summary ที่พิมพ์เอง)
- ⚠️ **ZERO VISUAL BUGS:** ตรวจภาพด้วยตา: ไม่มี focus ring ค้าง, ไม่มี layout ล้นบน mobile, ไม่มี Pagination แสดง 1/1 ในหน้า Empty, ไม่มี Typo ใน mockup
- ⚠️ **TIME REASONABLENESS:** หากเวลาบันทึกสั้น (0.5 - 1.0 ชม.) สำหรับงานที่ดูเยอะ ต้องระบุ Methodology (เช่น Automated script, Sync from baseline) ในคำอธิบายเสมอ
- ⚠️ **VISUAL EVIDENCE FIRST:** งานเอกสารและเทสต์ต้องมีภาพ Checklist Card สรุปเสมอ (อย่าแนบ text ล้วน)
- ⚠️ **AUTOMATION LOG ≠ VISUAL PROOF:** เป้าหมาย test/QA ต้องมีภาพประกอบนอกเหนือ raw log — ภาพ Playwright HTML Report dashboard, ภาพหน้าจอ หรือ screencast ของพฤติกรรม UI สำคัญ (countdown, error live, focus); เก็บ artifacts (report/traces) ไว้ trace ย้อนหลัง; เคส skipped ทุกเคสต้องมี triage note; scope a11y ต้องมี direct assertion หรือบันทึกเป็น evidence limitation
- ⚠️ **DUAL VIEWPORT:** งาน UI ต้องมีทั้ง Desktop (1440px) และ Mobile (390px) ทุกขั้นตอน
- ⚠️ **ห้ามใส่ข้อมูลลับในหลักฐาน:** token จริง, รหัสผ่าน, secrets, hash ของ credential, ข้อมูลส่วนตัวผู้ใช้จริง
- ⚠️ **ภาษาคำอธิบายเป็นภาษาคนทำงาน (NO BILINGUAL PARENTHESES / NO FLUFF):** ใช้คำทับศัพท์มาตรฐานตรงตัว (list, detail, modal, filter, dropdown, sidebar, breadcrumb, viewports, E2E, regression, triage) ไม่แปลไทยทางการ ห้ามใส่วงเล็บแปลสลับภาษา (เช่น ไม่เขียน "คัดกรอง (Triage)") และห้ามใช้คำสร้อยอารมณ์ (เช่น "ผ่านฉลุย", "อย่างเข้มงวด", "ราบรื่น")
- ⚠️ **ห้ามใช้สัญลักษณ์ `§`:** ให้อ้างตำแหน่งในเอกสารด้วยคำว่า "หมวด" เท่านั้น

---

## Checklist ก่อนส่งตรวจ AI Worklog QA Auditor

- [ ] ทุก Task ของเป้าหมายเป็น done แล้วจริง (ตรวจจาก Kanban)
- [ ] **ช่อง URL ชี้ work artifact จริง (spec/commit/docs)** — ยกเว้นงาน manual inspection/read-only ที่ไม่มี artifact จริง เว้นว่างและเปิดเผยในคำอธิบายแทนการชี้ commit หลักฐาน
- [ ] แนบไฟล์จริงทีละไฟล์เป็นค่าเริ่มต้น; มีภาพที่ preview ได้อย่างน้อย 1 รูป
- [ ] ไฟล์แนบมีแต่หลักฐานงานจริงราย task — ไม่มีไฟล์ภาพรวมเป้าหมาย/summary packaging และไม่มีเนื้อหาเดียวกันแนบซ้ำทั้ง .txt และ .png (แนบแค่ .png)
- [ ] Manual QA: checklist แยกต่อ task (1 task = 1 file + 1 card) บันทึกตั้งแต่ตอนตรวจจริง; card มีแค่ title + ขั้นตอนตรวจ + เคส check ไม่มี meta/work log
- [ ] **เป้าหมาย UI: ภาพครบทุกขั้นตอน flow และมีคู่ Desktop + Mobile ทุกขั้น**
- [ ] **Multimodal Visual Inspection: ไม่พบ Typo, ไม่พบ Empty-state Pagination bug, Mobile Spacing สวยงาม, ไม่มี focus ring**
- [ ] **เป้าหมาย test/เอกสาร: มี Checklist Card สรุปพร้อมผลลัพธ์ผ่านชัดเจน**
- [ ] **Work Artifact First: ไฟล์แนบมี artifact จริงของเป้าหมาย (เช่น `.spec.js` + raw `test-results.txt`) ไม่ได้มีแต่ไฟล์ที่สร้างเพื่อทำหลักฐาน และ external_url ชี้ไปที่ work artifact ไม่ใช่ packaging/commit สร้างหลักฐาน**
- [ ] **Test reconciliation: manifest ระบุทุก spec ที่รันจริง; ชื่อ/จำนวน spec ใน attachment และ external_url ครอบคลุม run inventory; ZIP ผ่านการตรวจรายชื่อและ hash เทียบ source**
- [ ] **Runner-output authenticity: ยืนยันว่าไฟล์เป็น raw output จริง; ถ้าไม่มี ให้ติดป้าย run summary, ระบุแหล่งข้อมูล และห้ามอ้างว่าเป็น raw หรือสร้างย้อนหลัง**
- [ ] **Caveat integrity: เปิดเผย evidence gap/ข้อจำกัดที่พบ และไม่เหมารวมว่าไม่มี issues เมื่อมี coverage gap ที่ทราบอยู่**
- [ ] **Test evidence มีภาพประกอบ: เป้าหมาย automated test มีภาพ Playwright HTML Report หรือ screenshot/screencast ของพฤติกรรม UI สำคัญ — ไม่ใช่แค่ raw log + checklist**
- [ ] **Skipped cases มี triage note: ทุกเคส skipped/blocked ระบุเหตุผลและการ reconcile แล้ว**
- [ ] **Accessibility ครบ scope: ถ้าเป้าหมายมีขอบเขต a11y (contrast, focus trap, aria) มี direct assertion จริง หรือบันทึกเป็น evidence limitation ชัดเจนในคำอธิบาย**
- [ ] **ไฟล์แนบเปิดได้: ไม่มีไฟล์ขนาดใหญ่เกินจน preview/เปิดไม่ได้ (PDF >15MB ต้องบีบอัดหรือใช้ HTML + anchor links)**
- [ ] **Time Reasonableness: หากชั่วโมงงานสั้น ได้อธิบาย Methodology ในคำอธิบายเรียบร้อยแล้ว**
- [ ] คำอธิบายเป็นภาษาคนทำงาน ตรงไปตรงมา ใช้ศัพท์มาตรฐานตรงตัว ไม่มีวงเล็บแปลไทยสลับอังกฤษ ไม่มีคำสร้อยอารมณ์ ("ผ่านฉลุย") ไม่มี `§` ไม่มีศัพท์โค้ดลอยๆ
- [ ] หลังหลักฐานทุก Objective แสดง compact Mission Objective–Feature–Task เป็น `text` copy block เดียว

