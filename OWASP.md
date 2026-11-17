# 🤖 SOFTWARE SECURITY INSTRUCTION (OWASP ENFORCEMENT)

## สำหรับ AI Agent / GitHub Copilot / Code Generator

---

## 🎯 Objective

Instruction นี้กำหนดกฎที่ AI Agent ต้องปฏิบัติตามเมื่อ generate code
เพื่อให้สอดคล้องกับ:

* OWASP Top 10
* OWASP ASVS (Level 2)
* Secure Coding Best Practices

---

## ⚠️ Core Security Rules (ห้ามละเมิด)

AI MUST:

* ❗ ห้ามเชื่อถือข้อมูลจาก Client (Web / Mobile)
* ❗ ต้อง enforce security ที่ API เท่านั้น
* ❗ ต้อง validate input ทุกครั้ง
* ❗ ต้องมี authentication และ authorization ทุก endpoint ที่จำเป็น

---

# 🔐 1. AUTHENTICATION & AUTHORIZATION

## REQUIREMENTS

* ต้องมี authentication สำหรับ endpoint ที่มีข้อมูลสำคัญ
* ต้องตรวจสอบ authorization ทุก request

## IMPLEMENTATION RULE

* ใช้ JWT (JSON Web Token) หรือ OAuth2
* ใช้ Role-Based Access Control (RBAC)

## FORBIDDEN

* ❌ ห้ามตรวจ role จาก client
* ❌ ห้าม skip authorization

---

# 🔐 2. INPUT VALIDATION

## REQUIREMENTS

* ต้อง validate input ทุก field
* ต้องตรวจ:

  * type
  * length
  * format

## IMPLEMENTATION RULE

* ใช้ whitelist validation
* reject input ที่ไม่ถูกต้องทันที

## FORBIDDEN

* ❌ ห้ามใช้ input โดยตรงโดยไม่ validate

---

# 💉 3. INJECTION PREVENTION

## REQUIREMENTS

* ต้องป้องกัน SQL Injection / Command Injection

## IMPLEMENTATION RULE

* ใช้ parameterized query
* ใช้ ORM (เช่น Entity Framework)

## FORBIDDEN

* ❌ ห้ามใช้ string concat SQL
* ❌ ห้าม execute command จาก input

---

# 🔐 4. CRYPTOGRAPHY

## REQUIREMENTS

* ต้องเข้ารหัสข้อมูลสำคัญ

## IMPLEMENTATION RULE

* Password:

  * bcrypt หรือ argon2 เท่านั้น
* Communication:

  * HTTPS เท่านั้น (TLS - Transport Layer Security)

## FORBIDDEN

* ❌ ห้ามเก็บ password แบบ plaintext
* ❌ ห้ามสร้าง crypto เอง

---

# 🔐 5. SESSION / TOKEN MANAGEMENT

## REQUIREMENTS

* ต้อง validate token ทุก request

## IMPLEMENTATION RULE

* ตรวจ:

  * signature
  * expiration

* ใช้ refresh token สำหรับ session

## FORBIDDEN

* ❌ ห้าม trust token โดยไม่ validate
* ❌ ห้ามเก็บ token แบบ plaintext (Mobile)

---

# 🔐 6. API SECURITY

## REQUIREMENTS

* ทุก API ต้อง:

  * authentication
  * authorization (ถ้าจำเป็น)

## IMPLEMENTATION RULE

* มี rate limiting
* validate request schema

## FORBIDDEN

* ❌ ห้ามเปิด public endpoint โดยไม่มีเหตุผล

---

# 🪵 7. LOGGING

## REQUIREMENTS

* ต้อง log:

  * authentication events
  * error
  * security event

## FORBIDDEN

* ❌ ห้าม log:

  * password
  * token
  * PII

---

# 🔑 8. SECRET MANAGEMENT

## REQUIREMENTS

* secret ต้องถูกจัดการอย่างปลอดภัย

## IMPLEMENTATION RULE

* ใช้:

  * environment variables
  * secret manager (เช่น AWS Secrets Manager)

## FORBIDDEN

* ❌ ห้าม hardcode:

  * API key
  * connection string
  * password

---

# 📦 9. DEPENDENCY SECURITY

## REQUIREMENTS

* ต้องตรวจสอบ dependency

## IMPLEMENTATION RULE

* ใช้ SCA (Software Composition Analysis)

## FORBIDDEN

* ❌ ห้ามใช้ library ที่มี CVE Critical

---

# 🧠 10. BUSINESS LOGIC VALIDATION

## REQUIREMENTS

* ต้องตรวจสอบ logic ของระบบ

## IMPLEMENTATION RULE

* ป้องกัน:

  * duplicate transaction
  * invalid workflow

---

# 📱 11. MOBILE SECURITY RULE

## REQUIREMENTS

* Mobile เป็น untrusted environment

## IMPLEMENTATION RULE

* ใช้ secure storage:

  * iOS → Keychain
  * Android → Keystore

* ใช้ certificate pinning

## FORBIDDEN

* ❌ ห้ามเก็บ secret ใน app
* ❌ ห้ามเก็บ token plaintext

---

# 🌐 12. WEB SECURITY RULE

## IMPLEMENTATION RULE

* ใช้:

  * HttpOnly cookie
  * Secure cookie

* ป้องกัน XSS (Cross-Site Scripting)

---

# 🚨 13. GLOBAL FORBIDDEN RULES

AI MUST NEVER GENERATE:

* ❌ Hardcoded secret
* ❌ Plaintext password
* ❌ SQL string concatenation
* ❌ Missing authentication
* ❌ Missing authorization
* ❌ Unvalidated input

---

# ✅ 14. OUTPUT REQUIREMENT

เมื่อ AI generate code:

* ต้อง include validation
* ต้อง include error handling
* ต้อง include security control
* ต้องไม่ลด security เพื่อความง่าย

---

# 🎯 FINAL RULE

> If there is a conflict between functionality and security,
> AI MUST choose SECURITY FIRST.
