#!/usr/bin/env python3
"""
sync_prompt_log.py — Offline Daily AI Conversation Log Builder (Schema 2.0)

Supports:
1. Antigravity IDE transcripts (`transcript_full.jsonl` / `transcript.jsonl`)
2. Claude Code transcripts (`~/.claude/projects/**/*.jsonl`)
3. Manual / IDE turns (`--turns-json` for Cursor, Windsurf, Copilot)

Features:
- Pure offline Schema 2.0 JSON generator (never uploads or accesses network/credentials)
- Incremental append to `YYYY-MM-DD_ai-log.json` (preserves earlier messages, deduplicates)
- Automatic UTC -> Asia/Bangkok (+07:00) timestamp conversion & 3-Tier fallback estimation
- Verbatim user prompt extraction (strips `<USER_REQUEST>`, `<ADDITIONAL_METADATA>`, `<CONTEXT_SUMMARY>`)
- Automatic assistant response summarization (1-3 sentences) & local path sanitization
- Automatic media attachment basename extraction + local file path listing for MCP upload
"""

import argparse
import datetime
import glob
import json
import mimetypes
import os
import re
import sys
import urllib.request
import uuid
from datetime import timedelta, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

BKK_TZ = timezone(timedelta(hours=7))

USER_REQ_RE = re.compile(r"<USER_REQUEST>\s*(.*?)\s*</USER_REQUEST>", re.DOTALL)
CONTEXT_SUMMARY_RE = re.compile(r"<CONTEXT_SUMMARY>.*?</CONTEXT_SUMMARY>", re.DOTALL)
ADDITIONAL_META_RE = re.compile(r"<ADDITIONAL_METADATA>.*?</ADDITIONAL_METADATA>", re.DOTALL)
SYSTEM_MSG_RE = re.compile(r"<SYSTEM_MESSAGE>.*?</SYSTEM_MESSAGE>", re.DOTALL)
FILE_LINK_RE = re.compile(r"\[([^\]]+)\]\(file://[^)]+\)")
RAW_FILE_URI_RE = re.compile(r"file://[^\s)\]>\"'`]+")
MARKDOWN_HEADING_RE = re.compile(r"^#{1,6}\s+", re.MULTILINE)


def now_bkk() -> datetime.datetime:
    return datetime.datetime.now(BKK_TZ)


def parse_iso_to_bkk(raw_ts: Optional[str]) -> Optional[datetime.datetime]:
    if not raw_ts or not isinstance(raw_ts, str):
        return None
    cleaned = raw_ts.strip()
    if not cleaned:
        return None
    try:
        if cleaned.endswith("Z"):
            cleaned = cleaned[:-1] + "+00:00"
        dt = datetime.datetime.fromisoformat(cleaned)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt.astimezone(BKK_TZ)
    except Exception:
        return None


def format_bkk_iso(dt: datetime.datetime) -> str:
    return dt.astimezone(BKK_TZ).isoformat(timespec="seconds")


def sanitize_local_paths(text: str) -> str:
    """Remove file:// links and local user home paths from assistant summaries."""
    if not text:
        return ""
    out = FILE_LINK_RE.sub(r"`\1`", text)
    out = RAW_FILE_URI_RE.sub("", out)
    home_dir = os.path.expanduser("~")
    if home_dir and home_dir != "/" and home_dir in out:
        out = out.replace(home_dir + "/", "").replace(home_dir, "~")
    return out


def extract_verbatim_user_prompt(raw_content: str) -> str:
    """Extract verbatim user prompt while stripping IDE wrapper tags."""
    if not raw_content:
        return ""
    match = USER_REQ_RE.search(raw_content)
    if match:
        return match.group(1).strip()
    cleaned = CONTEXT_SUMMARY_RE.sub("", raw_content)
    cleaned = ADDITIONAL_META_RE.sub("", cleaned)
    cleaned = SYSTEM_MSG_RE.sub("", cleaned)
    return cleaned.strip()


def summarize_assistant_text(raw_text: str, max_chars: int = 320) -> str:
    """Create a concise 1-3 sentence summary from an assistant response."""
    cleaned = sanitize_local_paths(raw_text or "").strip()
    if not cleaned:
        return ""
    # Remove fenced code blocks from summary to keep it concise
    cleaned = re.sub(r"```.*?```", "", cleaned, flags=re.DOTALL)
    lines = []
    for line in cleaned.splitlines():
        s = line.strip()
        if not s or s == "---" or s.startswith("|") or s.startswith(">"):
            continue
        s = MARKDOWN_HEADING_RE.sub("", s)
        s = re.sub(r"^[-*•]\s+", "", s)
        s = re.sub(r"^\d+\.\s+", "", s)
        s = s.replace("**", "")
        if s:
            lines.append(s)
        if len(lines) >= 3:
            break
    summary = " ".join(lines).strip()
    summary = re.sub(r"\s+", " ", summary)
    if len(summary) > max_chars:
        summary = summary[: max_chars - 1].rstrip() + "…"
    return summary


def summarize_tool_calls(tool_calls: List[Dict[str, Any]]) -> str:
    """Generate a concise summary when an assistant turn consists only of tool executions."""
    summaries = []
    touched_files = []
    for tc in tool_calls:
        name = tc.get("name") or ""
        args = tc.get("arguments") or tc.get("args") or {}
        if isinstance(args, str):
            try:
                args = json.loads(args)
            except Exception:
                args = {}
        if not isinstance(args, dict):
            args = {}
        tsum = args.get("toolSummary")
        if tsum and tsum not in summaries:
            summaries.append(str(tsum))
        path_val = args.get("Path") or args.get("path") or args.get("filename")
        if path_val and isinstance(path_val, str):
            bname = os.path.basename(path_val)
            if bname and bname not in touched_files:
                touched_files.append(bname)
        elif name and name not in summaries and not tsum:
            summaries.append(name)

    parts = []
    if summaries:
        parts.append("ดำเนินการ: " + ", ".join(summaries[:4]))
    if touched_files:
        parts.append("ไฟล์ที่เกี่ยวข้อง: " + ", ".join(touched_files[:5]))
    return " | ".join(parts) if parts else "ตรวจสอบโค้ดและประมวลผลคำสั่งในโปรเจกต์"


def parse_antigravity_transcript(
    transcript_path: str,
    target_date: str,
    since_ts: Optional[str] = None,
) -> Tuple[List[Dict[str, Any]], Dict[str, str], Optional[str]]:
    """
    Parse Antigravity transcript_full.jsonl or transcript.jsonl.
    Returns (messages, media_map[filename -> local_path], session_id).
    """
    p = Path(transcript_path)
    full_candidate = p.parent / "transcript_full.jsonl"
    if p.name == "transcript.jsonl" and full_candidate.exists():
        p = full_candidate

    session_id = None
    # Try to infer conversation UUID from brain/<uuid>/.system_generated/logs/
    for parent in p.parents:
        if re.match(r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", parent.name):
            session_id = parent.name
            break

    raw_steps = []
    with open(p, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                raw_steps.append(json.loads(line))
            except Exception:
                continue

    messages: List[Dict[str, Any]] = []
    media_map: Dict[str, str] = {}

    pending_tool_calls: List[Dict[str, Any]] = []
    pending_assistant_texts: List[str] = []
    last_planner_ts: Optional[str] = None

    def flush_pending_assistant():
        nonlocal pending_tool_calls, pending_assistant_texts, last_planner_ts
        if not last_planner_ts:
            pending_tool_calls = []
            pending_assistant_texts = []
            return
        if since_ts and last_planner_ts <= since_ts:
            pending_tool_calls = []
            pending_assistant_texts = []
            last_planner_ts = None
            return
        if pending_assistant_texts:
            combined_text = "\n".join(pending_assistant_texts)
            summary = summarize_assistant_text(combined_text)
        else:
            summary = summarize_tool_calls(pending_tool_calls)
        if summary:
            messages.append({
                "role": "assistant",
                "timestamp": last_planner_ts,
                "summary": summary,
            })
        pending_tool_calls = []
        pending_assistant_texts = []
        last_planner_ts = None

    for step in raw_steps:
        stype = step.get("type")
        # 1) Antigravity transcript format
        if stype in ("USER_INPUT", "PLANNER_RESPONSE"):
            dt_bkk = parse_iso_to_bkk(step.get("created_at"))
            if not dt_bkk:
                continue
            date_str = dt_bkk.strftime("%Y-%m-%d")
            if date_str != target_date:
                continue
            ts_str = format_bkk_iso(dt_bkk)

            if stype == "USER_INPUT":
                raw_content = step.get("content") or ""
                if "<SYSTEM_MESSAGE>" in raw_content and "<USER_REQUEST>" not in raw_content:
                    continue
                user_text = extract_verbatim_user_prompt(raw_content)
                if not user_text:
                    continue

                flush_pending_assistant()

                if since_ts and ts_str <= since_ts:
                    continue

                media_list = []
                for m in step.get("media") or []:
                    uri = m.get("uri") or ""
                    if uri:
                        local_path = uri.replace("file://", "")
                        bname = os.path.basename(local_path)
                        if bname:
                            media_list.append(bname)
                            if os.path.exists(local_path):
                                media_map[bname] = local_path

                msg_obj: Dict[str, Any] = {
                    "role": "user",
                    "timestamp": ts_str,
                    "content": user_text,
                }
                if media_list:
                    msg_obj["media"] = media_list
                messages.append(msg_obj)

            elif stype == "PLANNER_RESPONSE":
                last_planner_ts = ts_str
                content = (step.get("content") or "").strip()
                tcalls = step.get("tool_calls") or []
                if content:
                    pending_assistant_texts.append(content)
                if tcalls:
                    pending_tool_calls.extend(tcalls)

        # 2) OpenAI Codex JSONL format
        elif stype in ("session_meta", "response_item", "event_msg"):
            payload = step.get("payload") or {}
            if stype == "session_meta":
                session_id = payload.get("id") or payload.get("session_id") or session_id
                continue
            dt_bkk = parse_iso_to_bkk(step.get("timestamp"))
            if not dt_bkk or dt_bkk.strftime("%Y-%m-%d") != target_date:
                continue
            ts_str = format_bkk_iso(dt_bkk)
            if since_ts and ts_str <= since_ts:
                continue

            if stype == "response_item" and payload.get("type") == "message":
                role = payload.get("role")
                phase = payload.get("channel") or payload.get("phase")
                if role not in ("user", "assistant") or phase in ("analysis", "reasoning", "justify", "confidence"):
                    continue
                parts = payload.get("content") or []
                text = "".join(x.get("text", "") for x in parts if isinstance(x, dict)).strip()
                if not text or text.startswith(("<environment_context>", "<external_codex_apps_open_page>")):
                    continue
                if role == "user":
                    messages.append({
                        "role": "user",
                        "timestamp": ts_str,
                        "content": extract_verbatim_user_prompt(text),
                    })
                else:
                    messages.append({
                        "role": "assistant",
                        "timestamp": ts_str,
                        "summary": summarize_assistant_text(text),
                    })

        # 3) Claude Code JSONL format
        elif stype in ("user", "assistant") and isinstance(step.get("message"), dict):
            session_id = step.get("sessionId") or session_id
            dt_bkk = parse_iso_to_bkk(step.get("timestamp"))
            if not dt_bkk or dt_bkk.strftime("%Y-%m-%d") != target_date:
                continue
            ts_str = format_bkk_iso(dt_bkk)
            if since_ts and ts_str <= since_ts:
                continue
            msg_data = step["message"]
            raw_c = msg_data.get("content")
            if isinstance(raw_c, str):
                text = raw_c.strip()
            elif isinstance(raw_c, list):
                text = "\n".join(
                    part.get("text", "")
                    for part in raw_c
                    if isinstance(part, dict) and part.get("type") == "text"
                ).strip()
            else:
                text = ""
            if not text:
                continue
            if stype == "user":
                messages.append({
                    "role": "user",
                    "timestamp": ts_str,
                    "content": extract_verbatim_user_prompt(text),
                })
            else:
                messages.append({
                    "role": "assistant",
                    "timestamp": ts_str,
                    "summary": summarize_assistant_text(text),
                })

    flush_pending_assistant()
    return messages, media_map, session_id


def auto_discover_transcript() -> Optional[str]:
    """Find the most recently modified transcript (.jsonl) across Antigravity, Codex, and Claude Code."""
    home = os.path.expanduser("~")
    patterns = [
        os.path.join(home, ".gemini", "antigravity", "brain", "*", ".system_generated", "logs", "transcript_full.jsonl"),
        os.path.join(home, ".gemini", "antigravity", "brain", "*", ".system_generated", "logs", "transcript.jsonl"),
        os.path.join(home, ".codex", "sessions", "**", "*.jsonl"),
        os.path.join(home, ".claude", "projects", "**", "*.jsonl"),
    ]
    candidates: List[str] = []
    for pat in patterns:
        candidates.extend(glob.glob(pat, recursive=True))
    if not candidates:
        return None
    candidates.sort(key=lambda p: os.path.getmtime(p), reverse=True)
    return candidates[0]


def apply_backward_timestamps(messages: List[Dict[str, Any]], anchor_dt: datetime.datetime) -> None:
    """
    Tier 3 Fallback: If messages have missing timestamps, estimate backward from anchor_dt.
    """
    if not messages:
        return
    needs_estimation = any(not m.get("timestamp") for m in messages)
    if not needs_estimation:
        return

    cur_dt = anchor_dt
    for i in range(len(messages) - 1, -1, -1):
        m = messages[i]
        if not m.get("timestamp"):
            m["timestamp"] = format_bkk_iso(cur_dt)
        else:
            parsed = parse_iso_to_bkk(m["timestamp"])
            if parsed:
                cur_dt = parsed
        text_len = len(m.get("content") or m.get("summary") or "")
        if m.get("role") == "assistant":
            step_sec = min(180, max(45, 45 + text_len // 15))
        else:
            step_sec = min(480, max(120, 120 + text_len // 10))
        cur_dt = cur_dt - timedelta(seconds=step_sec)


def load_or_init_daily_log(
    output_path: str,
    target_date: str,
    session_id: str,
    tool_name: str,
    project_name: Optional[str],
    task_id: Optional[str],
    mission: Optional[str],
    objective: Optional[str],
    feature: Optional[str],
    objective_id: Optional[int],
    feature_id: Optional[int],
    auto_worklog: bool,
) -> Tuple[Dict[str, Any], Dict[str, Any], Optional[str]]:
    """
    Load existing YYYY-MM-DD_ai-log.json or initialize a new Schema 2.0 structure.
    Returns (full_data, target_session_dict, last_timestamp_in_file).
    """
    last_ts: Optional[str] = None
    if os.path.exists(output_path):
        with open(output_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        for s in data.get("sessions") or []:
            for m in s.get("messages") or []:
                ts = m.get("timestamp")
                if ts and (not last_ts or ts > last_ts):
                    last_ts = ts
        sessions = data.setdefault("sessions", [])
        target_sess = None
        for s in sessions:
            if s.get("session_id") == session_id or (project_name and s.get("project") == project_name):
                target_sess = s
                break
        if not target_sess:
            target_sess = {
                "session_id": session_id,
                "tool": tool_name,
                "project": project_name,
                "task_id": task_id,
                "mission": mission,
                "objective": objective,
                "feature": feature,
                "objective_id": objective_id,
                "feature_id": feature_id,
                "auto_worklog": auto_worklog,
                "messages": [],
            }
            sessions.append(target_sess)
        else:
            if project_name:
                target_sess["project"] = project_name
            if task_id:
                target_sess["task_id"] = task_id
            if mission is not None:
                target_sess["mission"] = mission
            if objective is not None:
                target_sess["objective"] = objective
            if feature is not None:
                target_sess["feature"] = feature
            if objective_id is not None:
                target_sess["objective_id"] = objective_id
            if feature_id is not None:
                target_sess["feature_id"] = feature_id
            target_sess["auto_worklog"] = auto_worklog
        data["auto_worklog"] = auto_worklog
        return data, target_sess, last_ts

    target_sess = {
        "session_id": session_id,
        "tool": tool_name,
        "project": project_name,
        "task_id": task_id,
        "mission": mission,
        "objective": objective,
        "feature": feature,
        "objective_id": objective_id,
        "feature_id": feature_id,
        "auto_worklog": auto_worklog,
        "messages": [],
    }
    data = {
        "schema_version": "2.0",
        "date": target_date,
        "timezone": "Asia/Bangkok",
        "auto_worklog": auto_worklog,
        "sessions": [target_sess],
        "limitations": [],
        "redactions_applied": False,
    }
    return data, target_sess, None


def upload_media_batches(
    server_url: str,
    api_key: str,
    file_paths: List[str],
    batch_size: int = 20,
) -> Dict[str, Any]:
    """
    Upload attached media files in batches of at most 20 files to
    POST <server_url>/api/agent/prompt-logs/media using standard library urllib.
    No hardcoded environment URLs — uses the exact server_url and api_key returned by MCP.
    """
    valid_paths = [p for p in file_paths if p and os.path.exists(p)]
    if not valid_paths:
        return {"success": True, "uploaded_count": 0, "media": []}

    url = f"{server_url.rstrip('/')}/api/agent/prompt-logs/media"
    all_uploaded: List[Dict[str, Any]] = []

    for idx in range(0, len(valid_paths), batch_size):
        chunk = valid_paths[idx : idx + batch_size]
        boundary = f"----PersonaMediaBoundary{uuid.uuid4().hex}"
        body_parts: List[bytes] = []

        for fpath in chunk:
            fname = os.path.basename(fpath)
            ctype = mimetypes.guess_type(fname)[0] or "application/octet-stream"
            with open(fpath, "rb") as f:
                file_bytes = f.read()
            header = (
                f"--{boundary}\r\n"
                f'Content-Disposition: form-data; name="files"; filename="{fname}"\r\n'
                f"Content-Type: {ctype}\r\n\r\n"
            ).encode("utf-8")
            body_parts.append(header)
            body_parts.append(file_bytes)
            body_parts.append(b"\r\n")

        body_parts.append(f"--{boundary}--\r\n".encode("utf-8"))
        body_bytes = b"".join(body_parts)

        req = urllib.request.Request(
            url,
            data=body_bytes,
            headers={
                "Content-Type": f"multipart/form-data; boundary={boundary}",
                "Content-Length": str(len(body_bytes)),
                "X-API-Key": api_key,
                "User-Agent": "PersonaPromptLogSync/2.0",
            },
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=90) as resp:
            res_json = json.loads(resp.read().decode("utf-8"))
            all_uploaded.extend(res_json.get("media") or [])

    return {
        "success": True,
        "uploaded_count": len(all_uploaded),
        "media": all_uploaded,
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Daily AI conversation prompt log builder (YYYY-MM-DD_ai-log.json, Schema 2.0) and optional media uploader."
    )
    parser.add_argument("--date", default=now_bkk().strftime("%Y-%m-%d"), help="Target date YYYY-MM-DD (default: today in Asia/Bangkok)")
    parser.add_argument("--transcript", default=None, help="Path to IDE transcript.jsonl or transcript_full.jsonl")
    parser.add_argument("--turns-json", default=None, help="Path to JSON file or inline JSON array of new messages [{role, timestamp, content/summary, media}]")
    parser.add_argument("--output", default=None, help="Output file path (default: <date>_ai-log.json in current directory)")
    parser.add_argument("--delta-output", default=None, help="Optional path to write compact delta JSON containing only newly added messages")
    parser.add_argument("--tool", default="Antigravity", help="AI tool name (e.g., Antigravity, Cursor, Claude Code, Windsurf, Copilot)")
    parser.add_argument("--project", default="Persona", help="Official Application name from list_my_apps (default: Persona)")
    parser.add_argument("--session-id", default=None, help="Session ID (auto-detected from transcript if omitted)")
    parser.add_argument("--task-id", default=None, help="Optional task_id description")
    parser.add_argument("--mission", default=None, help="Optional Ongoing Mission name")
    parser.add_argument("--objective", default=None, help="Optional Doing Objective name")
    parser.add_argument("--feature", default=None, help="Optional sub-Feature name")
    parser.add_argument("--objective-id", type=int, default=None, help="Optional Objective ID")
    parser.add_argument("--feature-id", type=int, default=None, help="Optional Feature ID")
    parser.add_argument("--no-auto-worklog", action="store_true", help="Disable automatic Pending Worklog creation (sets auto_worklog: false)")
    parser.add_argument("--full-resync", action="store_true", help="Re-parse all messages for the date instead of only messages after last timestamp")
    parser.add_argument("--upload-media", action="store_true", help="Upload discovered media files to --server-url using --api-key")
    parser.add_argument("--server-url", default=None, help="Server base URL returned by MCP upload_prompt_log")
    parser.add_argument("--api-key", default=None, help="Personal API key returned by MCP upload_prompt_log")

    args = parser.parse_args()
    target_date = args.date
    auto_worklog = not args.no_auto_worklog
    output_path = args.output or f"{target_date}_ai-log.json"

    # 1. Resolve transcript path if not using --turns-json
    transcript_path = args.transcript
    if not transcript_path and not args.turns_json:
        transcript_path = auto_discover_transcript()

    # Peek existing log to get last_ts for incremental sync
    existing_last_ts = None
    existing_session_id = args.session_id
    if os.path.exists(output_path) and not args.full_resync:
        try:
            with open(output_path, "r", encoding="utf-8") as f:
                existing_data = json.load(f)
            for s in existing_data.get("sessions") or []:
                if not existing_session_id and s.get("session_id"):
                    existing_session_id = s["session_id"]
                for m in s.get("messages") or []:
                    ts = m.get("timestamp")
                    if ts and (not existing_last_ts or ts > existing_last_ts):
                        existing_last_ts = ts
        except Exception:
            existing_last_ts = None

    new_messages: List[Dict[str, Any]] = []
    media_map: Dict[str, str] = {}
    detected_session_id: Optional[str] = None
    used_backward_estimation = False

    if args.turns_json:
        raw_turns = args.turns_json
        if os.path.exists(raw_turns):
            with open(raw_turns, "r", encoding="utf-8") as f:
                turns_list = json.load(f)
        else:
            turns_list = json.loads(raw_turns)
        if not isinstance(turns_list, list):
            raise ValueError("--turns-json must be a JSON array of message objects")
        if any(not m.get("timestamp") for m in turns_list):
            apply_backward_timestamps(turns_list, now_bkk())
            used_backward_estimation = True
        for m in turns_list:
            role = m.get("role")
            ts = m.get("timestamp")
            if existing_last_ts and ts and ts <= existing_last_ts and not args.full_resync:
                continue
            if role == "user":
                entry: Dict[str, Any] = {
                    "role": "user",
                    "timestamp": ts,
                    "content": extract_verbatim_user_prompt(m.get("content") or ""),
                }
                if m.get("media"):
                    media_names = []
                    for item in m["media"]:
                        bname = os.path.basename(item)
                        media_names.append(bname)
                        if os.path.exists(item):
                            media_map[bname] = item
                    if media_names:
                        entry["media"] = media_names
                new_messages.append(entry)
            elif role == "assistant":
                raw_sum = m.get("summary") or m.get("content") or ""
                new_messages.append({
                    "role": "assistant",
                    "timestamp": ts,
                    "summary": sanitize_local_paths(raw_sum),
                })
    elif transcript_path and os.path.exists(transcript_path):
        new_messages, media_map, detected_session_id = parse_antigravity_transcript(
            transcript_path=transcript_path,
            target_date=target_date,
            since_ts=None if args.full_resync else existing_last_ts,
        )
    else:
        print("Error: No transcript found. Pass --transcript <path> or --turns-json <json>.", file=sys.stderr)
        return 1

    final_session_id = args.session_id or detected_session_id or existing_session_id or f"session-{target_date}"

    data, target_sess, _ = load_or_init_daily_log(
        output_path=output_path,
        target_date=target_date,
        session_id=final_session_id,
        tool_name=args.tool,
        project_name=args.project,
        task_id=args.task_id,
        mission=args.mission,
        objective=args.objective,
        feature=args.feature,
        objective_id=args.objective_id,
        feature_id=args.feature_id,
        auto_worklog=auto_worklog,
    )

    if used_backward_estimation:
        lim_note = "แพลตฟอร์มแชตไม่เปิดเผยเวลาของแต่ละข้อความย้อนหลัง จึงประมาณการ timestamp ย้อนหลังจากเวลาปัจจุบันตามความซับซ้อนของแต่ละรอบสนทนา"
        if lim_note not in data["limitations"]:
            data["limitations"].append(lim_note)

    existing_msgs = target_sess.setdefault("messages", [])
    if args.full_resync:
        existing_msgs.clear()

    existing_keys = {
        (m.get("role"), m.get("timestamp"), (m.get("content") or m.get("summary") or "")[:80])
        for m in existing_msgs
    }

    appended_msgs: List[Dict[str, Any]] = []
    for m in new_messages:
        key = (m.get("role"), m.get("timestamp"), (m.get("content") or m.get("summary") or "")[:80])
        if key not in existing_keys:
            existing_msgs.append(m)
            existing_keys.add(key)
            appended_msgs.append(m)

    existing_msgs.sort(key=lambda x: x.get("timestamp") or "")

    # Also ensure any media filenames referenced across existing_msgs are included in media_map
    if transcript_path:
        session_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(transcript_path))))
        user_uploaded_dir = os.path.join(session_root, ".user_uploaded")
        for m in existing_msgs:
            for mfile in m.get("media") or []:
                if mfile and mfile not in media_map:
                    candidate = os.path.join(user_uploaded_dir, mfile)
                    if os.path.exists(candidate):
                        media_map[mfile] = candidate

    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    if args.delta_output:
        delta_msgs = appended_msgs if appended_msgs else existing_msgs[-20:]
        delta_payload = {
            "schema_version": "2.0",
            "date": target_date,
            "timezone": "Asia/Bangkok",
            "auto_worklog": auto_worklog,
            "sessions": [
                {
                    "session_id": f"{final_session_id}-delta",
                    "tool": args.tool,
                    "project": None if existing_last_ts else args.project,
                    "task_id": args.task_id or f"App: {args.project}",
                    "mission": args.mission,
                    "objective": args.objective,
                    "feature": args.feature,
                    "objective_id": args.objective_id,
                    "feature_id": args.feature_id,
                    "auto_worklog": auto_worklog,
                    "messages": delta_msgs,
                }
            ],
            "limitations": data.get("limitations") or [],
            "redactions_applied": Boolean_val(data.get("redactions_applied")),
        }
        with open(args.delta_output, "w", encoding="utf-8") as f:
            json.dump(delta_payload, f, ensure_ascii=False, separators=(",", ":"))

    result_summary: Dict[str, Any] = {
        "status": "ok",
        "output_file": output_path,
        "date": target_date,
        "project": args.project,
        "session_id": final_session_id,
        "appended_count": len(appended_msgs),
        "total_messages": len(existing_msgs),
        "media_files": list(media_map.values()),
    }

    if args.upload_media and media_map:
        if not args.server_url or not args.api_key:
            result_summary["media_upload_error"] = "Pass both --server-url and --api-key (from MCP upload_prompt_log output) when using --upload-media."
        else:
            result_summary["media_upload_result"] = upload_media_batches(
                server_url=args.server_url,
                api_key=args.api_key,
                file_paths=list(media_map.values()),
            )

    print(json.dumps(result_summary, ensure_ascii=False, indent=2))
    return 0


def Boolean_val(v: Any) -> bool:
    return bool(v)


if __name__ == "__main__":
    sys.exit(main())
