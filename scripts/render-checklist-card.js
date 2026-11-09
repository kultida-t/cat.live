// render checklist card จาก input text file สำหรับหลักฐานส่งตรวจ
// input format:
//   line 1: card title (เช่น "AIL-014 — Requirement & Doc Sync (12 files)")
//   "== <section>"   — เริ่ม section header
//   บรรทัดอื่น      — checklist item
// usage: node scripts/render-checklist-card.js <input.txt> <outDir> <outName>
const { chromium } = require("@playwright/test");
const fs = require("fs");
const path = require("path");

const [,, input, outDir, outName] = process.argv;
if (!input || !outDir || !outName) {
  console.error("usage: node scripts/render-checklist-card.js <input.txt> <outDir> <outName>");
  process.exit(1);
}

function esc(s) {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

const plain = process.argv.includes("--plain"); // summary mode: ไม่มี checkbox
const raw = fs.readFileSync(input, "utf8").replace(/\r/g, "").split("\n");
const title = raw.shift().trim();

let html = "";
for (const line of raw) {
  const t = line.trim();
  if (!t) continue;
  const sec = t.match(/^==\s+(.+)/);
  if (sec) {
    html += `    <div class="sec">${esc(sec[1])}</div>\n`;
  } else if (plain) {
    html += `    <li class="pl"><span>${esc(t.replace(/^-\s*/, ""))}</span></li>\n`;
  } else {
    html += `    <li><span class="cb"></span><span>${esc(t)}</span></li>\n`;
  }
}

(async () => {
  fs.mkdirSync(outDir, { recursive: true });
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 980, height: 900 } });
  await page.setContent(`<!doctype html><html><body><div class="card">
  <div class="title">${esc(title)}</div>
  <ul>
${html}  </ul>
</div></body>
<style>
  body { margin: 0; background: #171717; font-family: "Segoe UI", Tahoma, sans-serif; padding: 20px; box-sizing: border-box; }
  .card { background: #262626; border: 1px solid #3a3a3a; border-radius: 12px; padding: 20px 24px; color: #e8e8e8; }
  .title { font-weight: 700; font-size: 15px; margin-bottom: 12px; }
  .sec { font-weight: 700; font-size: 14px; margin: 14px 0 6px; color: #d8d8d8; }
  ul { list-style: none; margin: 0; padding: 0 0 0 6px; }
  li { display: flex; gap: 10px; align-items: flex-start; font-size: 14px; line-height: 1.55; margin: 3px 0; }
  li.pl { padding-left: 4px; }
  .cb { flex: none; width: 15px; height: 15px; margin-top: 3px; border-radius: 3px;
        background: #4a6a58; border: 1px solid #6a8a78; position: relative; }
  .cb::after { content: ""; position: absolute; left: 4px; top: 1px; width: 4px; height: 8px;
        border: solid #e8f4ec; border-width: 0 2px 2px 0; transform: rotate(45deg); }
</style></html>`);
  // แคป body element พอดี — fullPage จะเหลือพื้นดำเต็ม viewport height เมื่อ card สั้นกว่า 900px
  await page.locator("body").screenshot({ path: path.join(outDir, outName) });
  await browser.close();
  console.log("saved", path.join(outDir, outName));
})();
