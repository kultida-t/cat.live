#!/usr/bin/env bash
set -euo pipefail

# Select an already installed interpreter; never change the shared runner.
supported_python() {
  local executable
  executable="$(command -v -- "$1" 2>/dev/null)" || return 1
  [[ -f "$executable" && -x "$executable" ]] || return 1
  if ! "$executable" -c 'import sys; raise SystemExit(sys.version_info < (3, 10))' >/dev/null 2>&1; then
    printf 'Python 3.10+ check failed for %s: ' "$executable" >&2
    "$executable" --version >&2 || true
    return 1
  fi
  selected_python="$executable"
}

selected_python=""
if [[ ${SWARM_CI_PYTHON+x} ]]; then
  if [[ -z "$SWARM_CI_PYTHON" ]] || ! supported_python "$SWARM_CI_PYTHON"; then
    printf '%s\n' 'SWARM_CI_PYTHON must name one installed Python 3.10+ executable. Ask infra to provide that interpreter with venv/pip, or correct the override; no packages were installed.' >&2
    exit 1
  fi
else
  for candidate in python3.12 python3.11 python3.10 python3.13 python3; do
    if supported_python "$candidate"; then
      break
    fi
  done
  if [[ -z "$selected_python" ]]; then
    printf '%s\n' 'No supported Python found. This playbook requires Python 3.10+ with venv/pip. Ask infra to provide it on the runner, then set SWARM_CI_PYTHON to its executable path if needed; no packages were installed.' >&2
    exit 1
  fi
fi

printf 'Swarm CI interpreter: %s\n' "$selected_python"
"$selected_python" --version
if ! "$selected_python" -m venv .ci-venv; then
  printf '%s\n' 'Cannot create .ci-venv. Ask infra to provide venv/pip for the selected Python interpreter.' >&2
  exit 1
fi
if ! .ci-venv/bin/python -c 'import sys; raise SystemExit(sys.version_info < (3, 10))'; then
  printf '%s\n' '.ci-venv does not use Python 3.10+. Recreate this project-local virtual environment with the selected interpreter before installing dependencies.' >&2
  exit 1
fi

bootstrap_dir="$(cd -- "${BASH_SOURCE[0]%/*}" && pwd)"
.ci-venv/bin/python -m pip install --disable-pip-version-check -r "$bootstrap_dir/requirements.txt"
