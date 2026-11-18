"""Shared runtime helpers. Never print Docker output or environment values."""

from __future__ import annotations

import contextlib
import json
import os
import re
import signal
import subprocess
import sys
import tempfile
from decimal import Decimal, DecimalException
from pathlib import Path


class ReleaseError(ValueError):
    """An actionable error whose message is safe to put in a CI log."""


def warning(message: str) -> None:
    """Log a caller-supplied guideline; never pass secrets or Docker output here."""
    print(f"WARNING: {message}", file=sys.stderr, flush=True)


def validate_image_variable(key) -> None:
    """Image substitutions cannot also select the runner, target or credentials."""
    if not isinstance(key, str) or not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", key):
        raise ReleaseError("Image variable must be a valid environment variable name")
    reserved = {
        "PATH", "HOME", "USERPROFILE", "SYSTEMROOT", "COMSPEC", "PATHEXT",
        "TMPDIR", "TMP", "TEMP", "BASH_ENV", "ENV", "SHELL",
        "LD_PRELOAD", "LD_LIBRARY_PATH", "LD_AUDIT", "DYLD_INSERT_LIBRARIES",
        "DYLD_LIBRARY_PATH", "DYLD_FRAMEWORK_PATH", "DYLD_FALLBACK_LIBRARY_PATH",
        "PYTHONPATH", "PYTHONHOME", "PYTHONSTARTUP", "PYTHONEXECUTABLE",
        "DOCKER_HOST", "DOCKER_CONTEXT", "DOCKER_CONFIG", "DOCKER_CERT_PATH",
        "DOCKER_TLS", "DOCKER_TLS_VERIFY", "DOCKER_TLSVERIFY", "DOCKER_API_VERSION",
        "DOCKER_AUTH_CONFIG", "DOCKER_REGISTRY", "DOCKER_CUSTOM_HEADERS",
        "DOCKER_CONTENT_TRUST", "DOCKER_CONTENT_TRUST_SERVER", "DOCKER_DEFAULT_PLATFORM",
        "DOCKER_BUILDKIT", "BUILDKIT_HOST", "BUILDKIT_PROGRESS",
        "HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY", "NO_PROXY",
        "http_proxy", "https_proxy", "all_proxy", "no_proxy",
        "SSL_CERT_FILE", "SSL_CERT_DIR", "SSH_AUTH_SOCK", "SSH_AGENT_PID", "SSH_ASKPASS",
        "MrFox_Agent_User", "MrFox_Agent_Token", "REGISTRY_NAMESPACE",
        "DEPLOY_ENVIRONMENT", "STACK_NAME", "EXPECTED_SWARM_ID", "READINESS_URL",
        "READINESS_SUCCESS_CODES", "ROLLOUT_TIMEOUT", "STABILITY_SECONDS", "MIGRATION_TIMEOUT", "MIGRATOR_CPUS",
        "MIGRATOR_MEMORY", "APP_MIGRATOR_POSTGRES_CONNECTION", "APP_POSTGRES_CONNECTION",
        "ConnectionStrings__Postgres", "SWARM_CI_PYTHON",
    }
    if key in reserved or key.startswith("CI_"):
        raise ReleaseError("Image variable collides with a runtime setting or credential; use a separate image substitution key")


def required(env: dict, key: str) -> str:
    value = env.get(key, "").strip()
    if not value or any(marker in value for marker in ("<", ">", "${", "CHANGE_ME")):
        raise ReleaseError(f"Set {key}; empty values and placeholders are not allowed")
    return value


def secret_required(env: dict, key: str) -> str:
    """Secrets are opaque: preserve whitespace, '$', '<', '>' and other literals."""
    value = env.get(key)
    if not isinstance(value, str) or not value:
        raise ReleaseError(f"Set {key}; an empty secret is not allowed")
    return value


def positive_int(env: dict, key: str, default: str | None = None) -> int:
    value = env.get(key, default)
    if not isinstance(value, str) or not value.isdigit() or int(value) <= 0:
        raise ReleaseError(f"{key} must be a positive integer")
    return int(value)


def memory_bytes(value, label: str, *, allow_zero: bool = False) -> int:
    """Normalize Docker RAM quantities to bytes without logging the input.

    Docker uses powers of 1024 for both M/MB and MiB. Fractional bytes are
    truncated, as in Docker's RAMInBytes parser; zero remains an explicit value.
    """
    match = re.fullmatch(
        r"(\d+(?:\.\d*)?|\.\d+)(?:([eE][+-]?\d+))?\s*([kmgtp](?:i?b)?|b)?",
        str(value).strip(), re.I,
    )
    if not match:
        raise ReleaseError(f"{label}: invalid memory quantity")
    unit = (match.group(3) or "b").lower()[0]
    try:
        amount = Decimal(match.group(1) + (match.group(2) or ""))
        amount *= 1024 ** ("kmgtp".index(unit) + 1) if unit != "b" else 1
        if not amount.is_finite() or amount > 2**63 - 1:
            raise ReleaseError(f"{label}: memory quantity exceeds Docker's byte range")
        result = int(amount)
    except DecimalException:
        raise ReleaseError(f"{label}: invalid memory quantity") from None
    if result == 0 and not allow_zero:
        raise ReleaseError(f"{label}: expected a positive memory quantity")
    return result


def context(env: dict) -> dict:
    branch = env.get("CI_COMMIT_BRANCH", "").strip()
    target = next((env[key].strip() for key in ("DEPLOY_ENVIRONMENT", "CI_ENVIRONMENT_NAME", "CI_COMMIT_BRANCH", "CI_COMMIT_TAG")
                   if env.get(key, "").strip()), "")
    if not target:
        raise ReleaseError("Set a deployment environment or provide a CI branch/tag to identify the release")
    environment = {"stg": "staging", "prod": "production"}.get(target, target)
    if environment not in ("staging", "production"):
        warning("Deployment environment is outside the staging/production examples; check the selected stack, runner and target explicitly")
    if branch not in ("staging", "production") or env.get("CI_COMMIT_TAG") or environment != branch:
        warning("Release context differs from the staging/production branch convention; verify this pipeline is intended for the selected environment")
    sha = required(env, "CI_COMMIT_SHA")
    if not re.fullmatch(r"[0-9a-f]{40}|[0-9a-f]{64}", sha):
        raise ReleaseError("CI_COMMIT_SHA must be a full Git commit ID")
    return {
        "schema_version": 1,
        "environment": environment,
        "commit_sha": sha,
        "pipeline_id": positive_int(env, "CI_PIPELINE_ID"),
        "project_id": positive_int(env, "CI_PROJECT_ID"),
    }


def read_json(path: str | Path):
    try:
        return json.loads(Path(path).read_text())
    except (OSError, ValueError):
        raise ReleaseError("Cannot read the required JSON input; check its path and syntax") from None


def write_json(path: str | Path, value: dict) -> None:
    destination = Path(path)
    temporary = destination.with_suffix(destination.suffix + ".tmp")
    temporary.write_text(json.dumps(value, indent=2) + "\n")
    temporary.replace(destination)


def docker(env: dict, *args: str, timeout: float = 120, stdin: str | None = None) -> str:
    """Capture output privately; kill the CLI on timeout/cancel, never log secrets."""
    command = ["docker", *args]
    process = None
    try:
        process = subprocess.Popen(
            command, env=env, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE, text=True, start_new_session=True,
        )
        stdout, _stderr = process.communicate(stdin, timeout=timeout)
        if process.returncode:
            raise ReleaseError(f"Docker {args[0]} failed; inspect the operation securely on the runner")
        return stdout.strip()
    except subprocess.TimeoutExpired:
        raise ReleaseError(f"Docker {args[0]} exceeded its timeout") from None
    except OSError:
        raise ReleaseError("Cannot execute Docker; check the runner prerequisites") from None
    finally:
        if process is not None and process.poll() is None:
            os.killpg(process.pid, signal.SIGKILL)
            process.communicate()


def check_docker_endpoint(env: dict) -> None:
    """Reject context metadata that the private credential directory would hide.

    This reads configuration only; it neither contacts nor changes a daemon.
    Explicit DOCKER_CONTEXT precedes DOCKER_HOST. The default context uses
    DOCKER_HOST/TLS options; otherwise a stored named context is unsupported.
    """
    message = ("Named Docker contexts are not supported by isolated registry sessions; "
               "ask infra to configure the local daemon or explicit DOCKER_HOST/TLS")
    selected = env.get("DOCKER_CONTEXT", "")
    if selected and selected != "default":
        raise ReleaseError(message)
    if selected == "default" or env.get("DOCKER_HOST"):
        return
    config_dir = Path(env.get("DOCKER_CONFIG") or Path(env.get("HOME") or Path.home()) / ".docker")
    try:
        config = json.loads((config_dir / "config.json").read_text())
    except FileNotFoundError:
        return
    except (OSError, ValueError):
        raise ReleaseError("Cannot inspect Docker client configuration; ask infra to check the runner endpoint setup") from None
    if not isinstance(config, dict) or not isinstance(config.get("currentContext", ""), str):
        raise ReleaseError("Invalid Docker client configuration; ask infra to check the runner endpoint setup")
    if config.get("currentContext", "") not in ("", "default"):
        raise ReleaseError(message)


@contextlib.contextmanager
def registry_session(env: dict):
    """Per-job credentials; deleting this directory never logs another job out."""
    registry = required(env, "DOCKER_REGISTRY")
    if not re.fullmatch(r"[a-zA-Z0-9.-]+(?::[0-9]+)?", registry):
        raise ReleaseError("DOCKER_REGISTRY must be a registry hostname, without a URL scheme")
    user = env.get("MrFox_Agent_User", "").strip()
    token = env.get("MrFox_Agent_Token", "")
    check_docker_endpoint(env)
    with tempfile.TemporaryDirectory(prefix="swarm-docker-") as directory:
        private_env = dict(env, DOCKER_CONFIG=directory)
        if user and token:
            docker(private_env, "login", "--username", user, "--password-stdin", registry, stdin=token)
        else:
            warning("Registry credentials are missing or incomplete; continuing anonymously in an isolated Docker credential directory. Private registry operations may fail")
        yield private_env


@contextlib.contextmanager
def cancellation_handler():
    def cancel(_signal, _frame):
        raise InterruptedError("Job cancelled")

    previous = signal.signal(signal.SIGTERM, cancel)
    try:
        yield
    finally:
        signal.signal(signal.SIGTERM, previous)


def digest_reference(value) -> bool:
    return isinstance(value, str) and bool(re.fullmatch(
        r"[a-zA-Z0-9._:/-]+@sha256:[0-9a-f]{64}", value
    ))


def parse_json_output(value: str):
    try:
        return json.loads(value)
    except (TypeError, ValueError):
        raise ReleaseError("Docker returned unexpected metadata; check the supported CLI/Engine versions") from None
