#!/usr/bin/env python3
"""
extract_devin_sessions.py — เพิ่มบทสนทนา Devin Desktop/CLI ของวันที่เลือกเข้า YYYY-MM-DD_ai-log.json (Schema 2.0)

แหล่งข้อมูล (อ่านอย่างเดียว ไม่แก้ไขต้นทาง):
- ~/.local/share/devin/cli/sessions.db (ข้อความหลัก)
- ~/Library/Application Support/Devin/User/acp-messages/*.db (เพิ่มเฉพาะรอบที่ไม่ซ้ำกับ sessions.db)

สคริปต์นี้ไม่เรียก AI เอง จึงต้องทำ 3 ขั้นตามลำดับ:
1. --dump /tmp/devin_turns.json        ดึงรายการรอบสนทนา + คำตอบสุดท้ายของ AI
2. AI อ่านไฟล์ข้อ 1 แล้วเขียน /tmp/devin_summaries.json รูปแบบ {"<tid>": "สรุป 1-3 ประโยค"}
3. --summaries /tmp/devin_summaries.json --output deliverables/YYYY-MM-DD_ai-log.json
   รวมเข้า log โดยข้อความของพี่มาเต็มคัดลอกตรงทุกคำ และแทนที่เฉพาะ session เดิมที่มี session_id ตรงกัน

ไม่แตะ session ของ Antigravity (ใช้ sync_prompt_log.py ตามเดิม)
"""

import argparse
import datetime as dt
import glob
import html
import json
import os
import re
import sqlite3
import sys

BKK = dt.timezone(dt.timedelta(hours=7))
SESSIONS_DB = os.path.expanduser("~/.local/share/devin/cli/sessions.db")
ACP_DIR = os.path.expanduser("~/Library/Application Support/Devin/User/acp-messages")
TOOL = "Devin Desktop"
PROJECT = "แมว.live"  # ชื่อแอปตาม list_my_apps
AUTO = "[อัตโนมัติ] "  # คำนำหน้า limitations ที่สคริปต์สร้าง เพื่อให้เขียนทับได้ทุกครั้ง
DEDUP_SEC = 120

SECRET_RE = re.compile(r"(sk_[A-Za-z0-9_\-]{8,}|Bearer\s+[A-Za-z0-9._\-]{8,}|(?i:(api[_-]?key|token|secret|password)[\"']?\s*[:=]\s*[\"']?)[^\s\"',}]{6,})")
IMG_RE = re.compile(r"\[Image \d+: ([^\]]+)\]")
IMG_PLACEHOLDER_RE = re.compile(r"\[Image \d+: [^\]]*\]\n?")
TEMP_PATH_RE = re.compile(r"/var/folders/")
QUOTED_RE = re.compile(r"<quoted_artifact\b[^>]*>\s*(?:<caption>.*?</caption>\s*)?<content>\s*(.*?)\s*</content>\s*</quoted_artifact>", re.DOTALL)
MEDIA_DIR = os.path.join(os.environ.get("TMPDIR", "/tmp"), "devin-pasted-images")
SKIP_MEDIA = {"1794563689194685000-6563-1-pasted.png", "1794563689198844000-6563-2-pasted.png"}  # ภาพที่มี API Key ห้ามส่ง


def day_window(date):
    d = dt.datetime.strptime(date, "%Y-%m-%d").replace(tzinfo=BKK)
    return int(d.timestamp()), int((d + dt.timedelta(days=1)).timestamp())


def iso(ts):
    return dt.datetime.fromtimestamp(ts, BKK).isoformat(timespec="seconds")


def redact(text):
    def rep(m):
        s = m.group(0)
        if s.lower().startswith("bearer"):
            return "Bearer [REDACTED]"
        pre = re.match(r"(?i)^(api[_-]?key|token|secret|password)[\"']?\s*[:=]\s*[\"']?", s)
        return (pre.group(0) if pre else "") + "[REDACTED]"
    return SECRET_RE.sub(rep, text)


def group_turns(events):
    """เรียง event ตามเวลา แล้วจัดเป็นรอบ: 1 รอบ = ข้อความของพี่ 1 ข้อความ + คำตอบล่าสุดของ AI ก่อนรอบถัดไป"""
    turns, cur = [], None
    for ts, kind, content in events:
        if kind == "user":
            cur = {"ts": ts, "content": content, "asst_ts": None, "asst": None}
            turns.append(cur)
        elif cur is not None:
            cur["asst_ts"], cur["asst"] = ts, content
    return turns


def load_sessions_db(start, end):
    if not os.path.exists(SESSIONS_DB):
        return {}
    rows = sqlite3.connect(SESSIONS_DB).execute(
        "select session_id, created_at, chat_message from message_nodes "
        "where created_at>=? and created_at<? order by session_id, created_at, row_id", (start, end)).fetchall()
    events, seen = {}, set()
    for sid, ca, raw in rows:
        o = json.loads(raw)
        if o.get("message_id") in seen:
            continue
        seen.add(o.get("message_id"))
        role, content = o.get("role"), o.get("content") or ""
        if role == "user" and (o.get("metadata") or {}).get("is_user_input"):
            events.setdefault(sid, []).append((ca, "user", content))
        elif role == "assistant" and content.strip():
            events.setdefault(sid, []).append((ca, "assistant", content))
    return {sid: group_turns(evs) for sid, evs in events.items()}


def acp_payload(payload):
    o = json.loads(payload)
    parts, ts = [], None
    for c in o.get("content", []):
        ts = ts or (c.get("_meta") or {}).get("cognition.ai/timestamp")
        if (c.get("content") or {}).get("text"):
            parts.append(c["content"]["text"])
    return "".join(parts), (int(dt.datetime.fromisoformat(ts).timestamp()) if ts else None)


def load_acp(start, end, known_ts):
    """คืน session ที่มีรอบของวันนี้ซึ่งไม่ตรงกับ sessions.db (เทียบเวลาห่างไม่เกิน DEDUP_SEC วินาที)"""
    res = {}
    for path in sorted(glob.glob(os.path.join(ACP_DIR, "*.db"))):
        try:
            rows = sqlite3.connect(path).execute("select kind, payload from messages order by position").fetchall()
        except sqlite3.Error:
            continue
        events, last = [], None
        for kind, payload in rows:
            if kind not in ("user_message", "agent_message"):
                continue
            txt, ts = acp_payload(payload)
            last = ts or last
            if kind == "user_message" and ts:
                events.append((ts, "user", txt))
            elif kind == "agent_message" and txt.strip():
                events.append((ts or last, "assistant", txt))
        turns = [t for t in group_turns(events)
                 if start <= t["ts"] < end and not any(abs(t["ts"] - k) <= DEDUP_SEC for k in known_ts)]
        if turns:
            res[os.path.basename(path)[:-3]] = turns
    return res


def collect(date):
    start, end = day_window(date)
    db = load_sessions_db(start, end)
    known = [t["ts"] for turns in db.values() for t in turns]
    sessions = [("sessions.db", sid, turns) for sid, turns in db.items()]
    sessions += [("acp", sid, turns) for sid, turns in load_acp(start, end, known).items()]
    sessions.sort(key=lambda s: s[2][0]["ts"])
    return sessions


def tid_of(sid, i):
    return f"{sid[:8]}-{i:03d}"


def dump(date, path):
    sessions = collect(date)
    turns = []
    for src, sid, ts_list in sessions:
        for i, t in enumerate(ts_list):
            turns.append({"tid": tid_of(sid, i), "session_id": sid, "source": src, "time": iso(t["ts"]),
                          "user_preview": t["content"][:120], "assistant_final": t["asst"]})
    json.dump({"date": date, "turns": turns}, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
    print(f"sessions {len(sessions)} (sessions.db {sum(s[0] == 'sessions.db' for s in sessions)}, acp เพิ่ม {sum(s[0] == 'acp' for s in sessions)})")
    print(f"turns {len(turns)} (มีคำตอบ {sum(1 for t in turns if t['assistant_final'])}) -> {path}")


def gap_notes(sessions):
    stamps = sorted(dt.datetime.fromisoformat(m["timestamp"]) for s in sessions for m in s["messages"])
    out = []
    for a, b in zip(stamps, stamps[1:]):
        mins = (b - a).total_seconds() / 60
        if mins > 30:
            out.append(f"ช่วง {a:%H:%M}–{b:%H:%M} น. ไม่มีบันทึกบทสนทนา ({int(mins)} นาที)")
    return out


def merge(date, summaries_path, output):
    sessions = collect(date)
    summaries = json.load(open(summaries_path, encoding="utf-8"))
    new_sessions, missing, no_reply, redactions = [], [], [], 0
    for src, sid, ts_list in sessions:
        msgs = []
        for i, t in enumerate(ts_list):
            tid = tid_of(sid, i)
            media = [p.rsplit("/", 1)[-1] for p in IMG_RE.findall(t["content"])]
            content = redact(html.unescape(QUOTED_RE.sub(lambda x: x.group(1), IMG_PLACEHOLDER_RE.sub("", t["content"]))).strip())
            redactions += content.count("[REDACTED]")
            if TEMP_PATH_RE.search(content):
                sys.exit(f"ยังพบ path ในเครื่องในข้อความ {tid} หยุดก่อนบันทึก")
            u = {"role": "user", "timestamp": iso(t["ts"]), "content": content}
            if media:
                u["media"] = media
            msgs.append(u)
            if not (t["asst"] and t["asst"].strip()):
                no_reply.append(tid)
                continue
            if tid not in summaries:
                missing.append(tid)
                continue
            msgs.append({"role": "assistant", "timestamp": iso(t["asst_ts"] or t["ts"]), "summary": summaries[tid]})
        new_sessions.append({"session_id": sid, "tool": TOOL, "project": PROJECT, "task_id": None,
                             "mission": None, "objective": None, "feature": None, "objective_id": None,
                             "feature_id": None, "auto_worklog": False, "messages": msgs})
    if missing:
        sys.exit("ยังไม่มีสรุปของรอบเหล่านี้: " + ", ".join(missing))

    if os.path.exists(output):
        doc = json.load(open(output, encoding="utf-8"))
        if doc.get("date") != date:
            sys.exit(f"วันที่ในไฟล์ ({doc.get('date')}) ไม่ตรงกับ --date ({date})")
    else:
        doc = {"schema_version": "2.0", "date": date, "timezone": "Asia/Bangkok", "auto_worklog": False,
               "sessions": [], "limitations": [], "redactions_applied": False}
    new_ids = {s["session_id"] for s in new_sessions}
    kept = [s for s in doc["sessions"] if s["session_id"] not in new_ids]
    doc["sessions"] = sorted(kept + new_sessions, key=lambda s: s["messages"][0]["timestamp"])

    notes = [
        f"แหล่ง Devin: sessions.db {sum(s[0] == 'sessions.db' for s in sessions)} session, ACP store เพิ่มเฉพาะรอบที่ไม่ซ้ำ {sum(s[0] == 'acp' for s in sessions)} session",
        "ข้อความระบบที่แทรกอัตโนมัติ (system prompt, กฎ AGENTS, ข้อความ tool) ไม่รวม",
        "คำตอบ AI สรุปจากคำตอบสุดท้ายของแต่ละรอบ ข้อความระหว่างทางและการเรียกเครื่องมือไม่รวม",
        f"รอบที่ไม่มีคำตอบที่บันทึกไว้ ({len(no_reply)} รอบ): " + (", ".join(no_reply) if no_reply else "-"),
        "รูปภาพที่แนบ เก็บเฉพาะชื่อไฟล์ใน media ไม่ได้อัปโหลดไฟล์รูป",
    ]
    if redactions:
        notes.append(f"มีการปกปิดข้อมูลลับ {redactions} จุด (แทนด้วย [REDACTED])")
    notes += gap_notes(doc["sessions"])
    doc["limitations"] = [l for l in doc["limitations"] if not l.startswith(AUTO) and not re.match(r"^ช่วง .*ไม่มีบันทึกบทสนทนา", l)]
    doc["limitations"] += [AUTO + n for n in notes]
    doc["redactions_applied"] = "[REDACTED]" in json.dumps(doc["sessions"], ensure_ascii=False)

    json.dump(doc, open(output, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
    print(f"รวมเข้า {output}: session Devin {len(new_sessions)} (ข้อความ {sum(len(s['messages']) for s in new_sessions)}), session ทั้งหมด {len(doc['sessions'])}")


def audit(output):
    """ตรวจไฟล์ log แบบอ่านอย่างเดียว: path ในเครื่อง, รูปที่หาไม่เจอ, รูปที่ต้องข้าม, จำนวนรูปที่จะส่ง"""
    doc = json.load(open(output, encoding="utf-8"))
    leaks = [m["timestamp"] for s in doc["sessions"] for m in s["messages"] if TEMP_PATH_RE.search(m.get("content") or m.get("summary") or "")]
    paths, skipped, missing = media_plan(output)
    print(f"path ในเครื่องที่หลงในข้อความ: {len(leaks)} จุด")
    print(f"รูปที่จะส่ง: {len(paths)} ไฟล์ | ข้ามเพราะมี key: {len(skipped)} | หาไม่เจอ: {len(missing)}")
    return not leaks and not missing


def media_plan(output):
    """รายการรูปของ Devin ใน log: คืน (ไฟล์ที่จะส่ง, ชื่อที่ข้ามเพราะมี key, ชื่อที่หาไฟล์ไม่เจอ)"""
    doc = json.load(open(output, encoding="utf-8"))
    names = sorted({n for s in doc["sessions"] if s["tool"] == TOOL for m in s["messages"] for n in m.get("media", [])})
    skipped = [n for n in names if n in SKIP_MEDIA]
    paths, missing = [], []
    for n in names:
        if n in SKIP_MEDIA:
            continue
        p = os.path.join(MEDIA_DIR, n)
        (paths if os.path.exists(p) else missing).append(p)
    return paths, skipped, missing


def upload_media(output, send):
    paths, skipped, missing = media_plan(output)
    print(f"รูป Devin ที่จะส่ง {len(paths)} ไฟล์ ข้าม {len(skipped)} ไฟล์ (มี key ในภาพ) หาไม่เจอ {len(missing)} ไฟล์")
    for p in paths:
        print("  -", os.path.basename(p))
    if not send:
        print("ยังไม่ได้ส่ง (ทดสอบแบบแห้ง) ใช้ --send-media เพื่อส่งจริง")
        return
    server_url, api_key = os.environ.get("PERSONA_SERVER_URL"), os.environ.get("PERSONA_API_KEY")
    if not (server_url and api_key):
        sys.exit("ต้องตั้งค่าตัวแปร PERSONA_SERVER_URL และ PERSONA_API_KEY ในเครื่องก่อน")
    from sync_prompt_log import upload_media_batches
    res = upload_media_batches(server_url, api_key, paths)
    print(f"ส่งรูปสำเร็จ {res['uploaded_count']} ไฟล์")


def main():
    p = argparse.ArgumentParser(description="เพิ่มบทสนทนา Devin Desktop/CLI เข้า ai-log รายวัน")
    p.add_argument("--date", default=dt.datetime.now(BKK).strftime("%Y-%m-%d"))
    p.add_argument("--dump", help="ขั้น 1: เขียนรายการรอบสนทนาไปไฟล์ JSON")
    p.add_argument("--summaries", help="ขั้น 3: ไฟล์สรุป {tid: สรุป}")
    p.add_argument("--output", help="ไฟล์ ai-log ปลายทาง (ค่าเริ่มต้น deliverables/<date>_ai-log.json)")
    p.add_argument("--audit", action="store_true", help="ตรวจไฟล์ log อย่างเดียว ไม่แก้ไขและไม่ส่งอะไร")
    p.add_argument("--upload-media", action="store_true", help="แสดงรายการรูป Devin ใน log (ยังไม่ส่ง ถ้าไม่ใส่ --send-media)")
    p.add_argument("--send-media", action="store_true", help="ส่งรูปจริงไปยัง PERSONA_SERVER_URL ด้วย PERSONA_API_KEY")
    a = p.parse_args()
    output = a.output or f"deliverables/{a.date}_ai-log.json"
    if a.dump:
        dump(a.date, a.dump)
    if a.summaries:
        merge(a.date, a.summaries, output)
    if a.audit:
        audit(output)
    if a.upload_media or a.send_media:
        upload_media(output, a.send_media)
    if not (a.dump or a.summaries or a.audit or a.upload_media or a.send_media):
        p.error("ต้องระบุ --dump, --summaries, --audit หรือ --upload-media")


if __name__ == "__main__":
    main()
