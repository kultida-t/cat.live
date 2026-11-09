// แปลงผลรัน Playwright (list reporter) เป็นภาพ terminal-style สำหรับหลักฐานส่งตรวจ
// usage: node scripts/render-test-output.js <input-txt> <output-dir> [lines-per-shot]
// ตัวอย่าง: node scripts/render-test-output.js deliverables/AIL-016-test-results.txt screenshots/mission-login-baseline-objective-3
const { chromium } = require("@playwright/test");
const fs = require("fs");
const path = require("path");

const INPUT = process.argv[2];
const OUT = process.argv[3];
const PER_SHOT = parseInt(process.argv[4] || "40", 10);
const CMD_LABEL = process.env.CMD_LABEL || "";

if (!INPUT || !OUT) {
  console.error("usage: node scripts/render-test-output.js <input-txt> <output-dir> [lines-per-shot]");
  process.exit(1);
}

function esc(s) {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

function colorize(line) {
  let l = esc(line);
  l = l.replace(/^(\s+)(ok|x|-)\s+(\d+)/, (m, sp, mark, n) => {
    const cls = mark === "ok" ? "pass" : mark === "x" ? "fail" : "skip";
    return `${sp}<span class="${cls}">${mark}</span> <span class="num">${n}</span>`;
  });
  l = l.replace(/(\d+ (passed|failed|skipped|flaky).*)/g, '<span class="$2">$1</span>');
  l = l.replace(/(Running \d+ tests.*)/g, '<span class="info">$1</span>');
  return l;
}

(async () => {
  const raw = fs.readFileSync(INPUT, "utf8").replace(/\r/g, "");
  const lines = raw.split("\n");
  // ตัดบรรทัดว่างท้ายไฟล์ออก แต่เก็บความจริงของ output
  while (lines.length && lines[lines.length - 1].trim() === "") lines.pop();

  fs.mkdirSync(OUT, { recursive: true });

  const chunks = [];
  for (let i = 0; i < lines.length; i += PER_SHOT) chunks.push(lines.slice(i, i + PER_SHOT));

  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });

  for (let c = 0; c < chunks.length; c++) {
    const body = chunks[c]
      .map(colorize)
      .join("\n");
    const head = c === 0 && CMD_LABEL ? `<div class="cmd">${esc(CMD_LABEL)}</div>\n` : "";
    const html = `<!doctype html><html><body><pre>${head}${body}</pre></body>
<style>
  body { margin: 0; background: #1e1e1e; }
  pre {
    font-family: Consolas, "Cascadia Mono", monospace;
    font-size: 14px; line-height: 22px; color: #d4d4d4;
    padding: 14px 18px; margin: 0; white-space: pre-wrap; word-break: break-word;
  }
  .pass { color: #4ec9b0; font-weight: bold; }
  .fail { color: #f44747; font-weight: bold; }
  .skip { color: #9cdcfe; font-weight: bold; }
  .info { color: #dcdcaa; }
  .num  { color: #808080; }
  .cmd  { color: #6a9955; margin-bottom: 10px; }
</style></html>`;
    await page.setContent(html);
    await page.screenshot({ path: path.join(OUT, `test-run-${String(c + 1).padStart(2, "0")}.png`), fullPage: true });
    console.log("saved", `test-run-${String(c + 1).padStart(2, "0")}.png`);
  }

  await browser.close();
  console.log("done →", OUT);
})();
