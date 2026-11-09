// render test checklist card ต่อ spec file (รูปแบบเดียวกับหลักฐาน QA ที่เคยส่ง)
// usage: node scripts/render-test-checklist.js <specPath1> [specPath2 ...] <outputDir>
// ตัวอย่าง: node scripts/render-test-checklist.js tests/qa-bo-001-auth-dashboard.spec.js tests/qa-bo-015-accept-invitation.spec.js screenshots/mission-login-baseline-objective-3
const { chromium } = require("@playwright/test");
const fs = require("fs");
const path = require("path");

// ชื่อ theme สั้นบนหัว card (ตามรูปแบบ "qa-bo-014c — Filter/Search/Sort/Date Range")
const THEMES = {
  "qa-bo-001": "Login + Dashboard",
  "qa-bo-012": "Cross-module Consistency",
  "qa-bo-013e": "Admin Action Modals",
  "qa-bo-013g": "Invite Admin",
  "qa-bo-015": "Accept Invitation",
  "qa-bo-016": "Invitation Recovery",
  "qa-bo-018": "Scoped UI/Responsive/A11y Smoke",
  "qa-bo-019a": "My Account + Edit Name",
  "qa-bo-019b": "Change Password",
  "qa-bo-019c": "Active Sessions",
  "qa-bo-019d": "Logout All Devices",
  "qa-bo-019e": "Session Expired",
  "qa-bo-020": "Forgot Password",
  "qa-bo-021": "Reset Password",
  "qa-bo-022": "Failed Login Lockout",
  "qa-bo-023": "Self-Service Functional",
  "qa-bo-024": "Password Recovery Functional",
  "qa-bo-025": "Scoped UI/Responsive/A11y Smoke",
  "del-pto-003": "Account Deletion Action Modals",
  "del-pto-004": "Audit Log + Cross-module Links",
};

function esc(s) {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

function parseSpec(file) {
  const src = fs.readFileSync(file, "utf8");
  const sections = [];
  let current = null;
  for (const line of src.split("\n")) {
    const d = line.match(/test\.describe(?:\.\w+)*\(\s*"([^"]+)"/);
    if (d) {
      current = { title: d[1], items: [] };
      sections.push(current);
      continue;
    }
    const t = line.match(/^\s*test\(\s*"([^"]+)"/);
    if (t) {
      if (!current) {
        current = { title: null, items: [] };
        sections.push(current);
      }
      current.items.push(t[1]);
    }
  }
  return sections;
}

(async () => {
  const args = process.argv.slice(2);
  const outDir = args.pop();
  const specs = args;
  if (!specs.length || !outDir) {
    console.error("usage: node scripts/render-test-checklist.js <specPath...> <outputDir>");
    process.exit(1);
  }
  fs.mkdirSync(outDir, { recursive: true });

  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 980, height: 900 } });

  for (const spec of specs) {
    const base = path.basename(spec, ".spec.js");
    const id = base.match(/^(qa-bo-\d+[a-z]?|del-pto-\d+)/)?.[1] || base;
    const theme = THEMES[id] || base;
    const sections = parseSpec(spec);
    const total = sections.reduce((n, s) => n + s.items.length, 0);

    const sectionHtml = sections
      .map((s) => {
        const items = s.items
          .map((i) => `      <li><span class="cb"></span><span>${esc(i)}</span></li>`)
          .join("\n");
        const head = s.title ? `    <div class="sec">${esc(s.title)}</div>\n` : "";
        return `${head}    <ul>\n${items}\n    </ul>`;
      })
      .join("\n");

    const html = `<!doctype html><html><body><div class="card">
  <div class="title">${esc(id)} — ${esc(theme)} (${total} tests)</div>
${sectionHtml}
</div></body>
<style>
  body { margin: 0; background: #171717; font-family: "Segoe UI", Tahoma, sans-serif; padding: 20px; box-sizing: border-box; }
  .card { background: #262626; border: 1px solid #3a3a3a; border-radius: 12px; padding: 20px 24px; color: #e8e8e8; }
  .title { font-weight: 700; font-size: 15px; margin-bottom: 12px; }
  .sec { font-weight: 700; font-size: 14px; margin: 14px 0 6px; color: #d8d8d8; }
  ul { list-style: none; margin: 0; padding: 0 0 0 6px; }
  li { display: flex; gap: 10px; align-items: flex-start; font-size: 14px; line-height: 1.55; margin: 3px 0; }
  .cb { flex: none; width: 15px; height: 15px; margin-top: 3px; border-radius: 3px;
        background: #4a6a58; border: 1px solid #6a8a78; position: relative; }
  .cb::after { content: ""; position: absolute; left: 4px; top: 1px; width: 4px; height: 8px;
        border: solid #e8f4ec; border-width: 0 2px 2px 0; transform: rotate(45deg); }
</style></html>`;
    await page.setContent(html);
    // แคป body element พอดี — fullPage จะเหลือพื้นดำเต็ม viewport height เมื่อ card สั้นกว่า 900px
    await page.locator("body").screenshot({ path: path.join(outDir, `checklist-${id}.png`) });
    console.log("saved", `checklist-${id}.png`, `(${total} tests)`);
  }

  await browser.close();
  console.log("done →", outDir);
})();
