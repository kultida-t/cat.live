#!/usr/bin/env bash
# เตรียม Python 3.12 (python-build-standalone) ใน build workspace ของ job —
# ใช้เมื่อ shared runner ไม่มี Python 3.10+ (playbook ต้องการ 3.10+)
# ผลลัพธ์อยู่ใต้ $CI_PROJECT_DIR/.ci-python เท่านั้น ไม่แตะระบบของ runner
# bootstrap.sh ของ playbook จะเลือก interpreter นี้ผ่าน SWARM_CI_PYTHON
set -euo pipefail

PY_DIR="${CI_PROJECT_DIR:-$PWD}/.ci-python"
PBS_TAG="20261110"
PBS_ARCHIVE="cpython-3.12.16+${PBS_TAG}-x86_64-unknown-linux-gnu-install_only_stripped.tar.gz"
PBS_URL="https://github.com/astral-sh/python-build-standalone/releases/download/${PBS_TAG}/${PBS_ARCHIVE}"

if [[ -x "$PY_DIR/bin/python3" ]]; then
  "$PY_DIR/bin/python3" --version
  exit 0
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
curl -fsSL --retry 3 --retry-delay 2 "$PBS_URL" -o "$tmp/python.tar.gz"
mkdir -p "$PY_DIR"
tar -xzf "$tmp/python.tar.gz" -C "$PY_DIR" --strip-components=1
"$PY_DIR/bin/python3" --version
