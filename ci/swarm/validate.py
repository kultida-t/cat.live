#!/usr/bin/env python3
"""Validate the effective Swarm stack without logging its interpolated secrets.

Rendering contacts no Docker daemon. This checks configuration, not live capacity.
"""
import argparse
from decimal import Decimal, InvalidOperation
import json
import os
from pathlib import Path
import re
import subprocess
import sys

import yaml

from common import memory_bytes, warning

POLICY_PATH = Path(__file__).with_name("policy.json")
DIGEST = re.compile(r"^[^\s@$]+@sha256:[0-9a-f]{64}$")


def positive(value, label, *, allow_zero=False):
    if isinstance(value, bool):
        raise ValueError(f"{label}: expected a positive number")
    try:
        result = Decimal(str(value))
    except InvalidOperation:
        raise ValueError(f"{label}: expected a positive number") from None
    if not result.is_finite() or result < 0 or (result == 0 and not allow_zero):
        raise ValueError(f"{label}: expected a positive number")
    return result


def normalize_constraint(value):
    match = re.fullmatch(r"\s*([A-Za-z][A-Za-z0-9_.-]*)\s*(==|!=)\s*(\S(?:.*\S)?)\s*", str(value))
    if not match:
        raise ValueError("Invalid placement constraint; use a selector and ==/!= with a value")
    return " ".join(match.groups())


def validate_document(document, environment, release_images=None, policy=None):
    policy = policy or json.loads(POLICY_PATH.read_text())
    if environment not in policy["placement"]:
        warning("No placement baseline is defined for this environment; review its target nodes explicitly")
    if not isinstance(document, dict) or not isinstance(document.get("services"), dict) or not document["services"]:
        raise ValueError("Stack must contain services")
    expected = {normalize_constraint(c) for c in policy["placement"].get(environment, [])}
    for name, service in document["services"].items():
        if not isinstance(service, dict) or not re.fullmatch(r"[a-zA-Z0-9][a-zA-Z0-9_.-]*", name):
            raise ValueError("Invalid service definition or unresolved service placeholder")
        deploy = service.get("deploy", {})
        if not isinstance(deploy, dict):
            raise ValueError(f"{name}: deploy must be a mapping")
        placement = deploy.get("placement", {})
        if not isinstance(placement, dict):
            raise ValueError(f"{name}: placement must be a mapping")
        constraints = placement.get("constraints", [])
        if not isinstance(constraints, list):
            raise ValueError(f"{name}: placement constraints must be a list")
        actual = [normalize_constraint(c) for c in constraints]
        if len(actual) != len(set(actual)):
            warning(f"{name}: duplicate placement constraints add no scheduling protection")
        if environment in policy["placement"] and set(actual) != expected:
            warning(f"{name}: placement differs from the default labels; review the exception with admin and preserve intended scheduling constraints")
        resources = deploy.get("resources", {})
        if not isinstance(resources, dict):
            raise ValueError(f"{name}: resources must be a mapping")
        parsed = {}
        for kind in ("reservations", "limits"):
            values = resources.get(kind, {})
            if not isinstance(values, dict):
                raise ValueError(f"{name}: resource {kind} must be a mapping")
            if not {"cpus", "memory"}.issubset(values):
                warning(f"{name}: CPU and RAM {kind} are recommended; missing fields leave Docker defaults in effect")
            parsed[kind] = {}
            for key, parse in (("cpus", positive), ("memory", memory_bytes)):
                if key in values:
                    parsed[kind][key] = parse(values[key], f"{name} {key} {kind}", allow_zero=True)
                    if parsed[kind][key] == 0:
                        warning(f"{name}: zero {key} {kind} does not provide the recommended resource bound/reservation")
        for key in ("cpus", "memory"):
            reserve = parsed["reservations"].get(key)
            limit = parsed["limits"].get(key)
            if reserve is not None and limit is not None and limit > 0 and reserve > limit:
                raise ValueError(f"{name}: {key} reservation exceeds limit")
        mode = deploy.get("mode", "replicated")
        if mode == "replicated":
            replicas = deploy.get("replicas", 1)
            if isinstance(replicas, bool) or not isinstance(replicas, int) or replicas < 0:
                raise ValueError(f"{name}: replicas must be a nonnegative integer")
            if replicas == 0:
                warning(f"{name}: zero replicas leave this service scaled down")
        elif mode != "global":
            raise ValueError(f"{name}: unsupported service mode")
        image = service.get("image", "")
        if not isinstance(image, str) or not image or any(x in image for x in ("$", "<", ">")):
            raise ValueError(f"{name}: image is missing or unresolved")
        if release_images is not None and (not DIGEST.fullmatch(image) or image not in release_images.values()):
            warning(f"{name}: image is not an immutable digest from this release manifest; verify its provenance and tag stability")
    return document


def validate_stack(stack_files, environment, env, release_images=None):
    if not stack_files or any(not Path(p).is_file() for p in stack_files):
        raise ValueError("Every deployment stack file must exist")
    if environment == "production":
        # Inspect variable names only. Never echo defaults or interpolated values.
        for path in stack_files:
            for key in sorted(set(re.findall(r"\$\{((?:[A-Za-z_][A-Za-z0-9_]*_)?(?:CPU|MEMORY)_(?:RESERVATION|LIMIT)):-", Path(path).read_text()))):
                if not env.get(key):
                    warning(f"{key} is not set; using this template's starter resource value. Review production sizing and capacity")
    command = ["docker", "stack", "config"]
    for path in stack_files:
        command.extend(["--compose-file", str(path)])
    try:
        result = subprocess.run(command, env=env, text=True, capture_output=True, timeout=60)
    except (OSError, subprocess.TimeoutExpired):
        raise ValueError("Cannot render stack with the configured Docker CLI") from None
    if result.returncode:
        # Docker/YAML errors can contain an interpolated secret: never echo them.
        raise ValueError("Docker stack validation failed; inspect with mock values, never print a secret-bearing config")
    if re.search(r"unsupported|ignor(?:e|ed|ing)", result.stderr, re.I):
        warning("Docker ignored or does not support an option; continuing with its rendered stack. Review the option using mock values")
    try:
        document = yaml.safe_load(result.stdout)
    except yaml.YAMLError:
        raise ValueError("Docker returned an invalid stack document") from None
    return validate_document(document, environment, release_images)


def mock_environment(environment):
    """Explicit fixture values; never called by release.py or used for deployment."""
    env = os.environ.copy()
    env.update({
        "API_IMAGE": "example.invalid/mock/api@sha256:" + "a" * 64,
        "WORKER_IMAGE": "example.invalid/mock/worker@sha256:" + "b" * 64,
        "APP_IMAGE": "example.invalid/mock/app@sha256:" + "c" * 64,
        "MIGRATOR_IMAGE": "example.invalid/mock/migrator@sha256:" + "d" * 64,
        "APP_POSTGRES_CONNECTION": "Host=mock;Database=mock;Username=mock;Password=not-a-secret",
        "ASPNETCORE_ENVIRONMENT": {"staging": "Staging", "stg": "Staging", "production": "Production", "prod": "Production"}.get(environment, environment),
        "DOTNET_ENVIRONMENT": {"staging": "Staging", "stg": "Staging", "production": "Production", "prod": "Production"}.get(environment, environment),
        "CI_PIPELINE_ID": "101", "CI_PROJECT_ID": "42",
    })
    for service in ("API", "WORKER", "APP"):
        for key, value in {"CPU_RESERVATION": "0.10", "CPU_LIMIT": "1.00", "MEMORY_RESERVATION": "256M", "MEMORY_LIMIT": "512M"}.items():
            env[f"{service}_{key}"] = value
    return env


def safe_summary(document):
    # Deliberately exclude images, arbitrary labels, environment, mounts and URLs.
    return {"services": {name: {"mode": service.get("deploy", {}).get("mode", "replicated"),
                                  "replicas": None if service.get("deploy", {}).get("mode") == "global" else service.get("deploy", {}).get("replicas", 1),
                                  "resources": {kind: {key: service.get("deploy", {}).get("resources", {}).get(kind, {}).get(key) for key in ("cpus", "memory")} for kind in ("reservations", "limits")},
                                  "constraint_count": len(service.get("deploy", {}).get("placement", {}).get("constraints", []))}
                         for name, service in document["services"].items()},
            "capacity": "NOT CHECKED: infra must confirm eligible nodes, host/transient workload and rollout headroom"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--stack-file", action="append", required=True)
    parser.add_argument("--environment", required=True)
    parser.add_argument("--mock", action="store_true", help="Use fixture values for offline checks; not a capacity or deployment test")
    args = parser.parse_args()
    try:
        env = mock_environment(args.environment) if args.mock else os.environ.copy()
        document = validate_stack(args.stack_file, args.environment, env)
        print(json.dumps({"validation": "mock" if args.mock else "actual-config", **safe_summary(document)}, indent=2))
    except ValueError as error:
        print(f"Validation failed: {error}", file=sys.stderr)
        return 1
    except (KeyError, TypeError, OSError):
        print("Validation failed: malformed policy/configuration. No rendered configuration was logged.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
