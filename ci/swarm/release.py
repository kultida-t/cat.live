"""Run one locked release: preflight, optional migration, deploy and verify."""

from __future__ import annotations

import argparse
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from decimal import Decimal, InvalidOperation

from common import (
    ReleaseError, cancellation_handler, context, digest_reference, docker,
    memory_bytes, parse_json_output, positive_int, read_json, registry_session, required, secret_required,
    validate_image_variable, warning,
)


PIPELINE_LABEL = "io.mrfox.ci.pipeline-id"
PROJECT_LABEL = "io.mrfox.ci.project-id"
SERVICE_METADATA = (
    '{"image":{{json .Spec.TaskTemplate.ContainerSpec.Image}},'
    '"labels":{{json .Spec.Labels}},"update":{{json .UpdateStatus}}}'
)
TASK_METADATA = (
    '{"image":{{json .Spec.ContainerSpec.Image}},'
    '"state":{{json .Status.State}},"desired":{{json .DesiredState}}}'
)


def load_manifest(path: str, env: dict) -> dict:
    manifest = read_json(path)
    identity = context(env)
    if (not isinstance(manifest, dict) or type(manifest.get("schema_version")) is not int or manifest["schema_version"] != 1
            or not isinstance(manifest.get("environment"), str) or not manifest["environment"]
            or not isinstance(manifest.get("commit_sha"), str) or not manifest["commit_sha"]
            or any(not isinstance(manifest.get(key), int) or isinstance(manifest[key], bool)
                   or manifest[key] <= 0 for key in ("project_id", "pipeline_id"))):
        raise ReleaseError("Release manifest needs a supported schema and valid release identity fields")
    if any(manifest.get(key) != value for key, value in identity.items()):
        warning("Release manifest identity differs from this job; continuing with the supplied release manifest")
    images = manifest.get("images")
    if not isinstance(images, dict) or not images:
        raise ReleaseError("Release manifest has no images")
    for key, value in images.items():
        validate_image_variable(key)
        if not image_reference(value):
            raise ReleaseError("Release manifest must contain usable image references")
        if not re.fullmatch(r"[A-Z][A-Z0-9_]*_IMAGE", key):
            warning("Manifest image key differs from the starter naming convention; continuing")
        if not digest_reference(value):
            warning("Manifest contains an image tag instead of an immutable digest; continuing without a recorded digest guarantee")
    return manifest


def image_reference(value) -> bool:
    """Reject unusable input; Docker remains the authority on image syntax."""
    return (isinstance(value, str) and bool(value) and not any(character.isspace() for character in value)
            and not any(marker in value for marker in ("${", "<", ">")))


def image_matches(actual, requested) -> bool:
    if actual == requested:
        return True
    if not isinstance(requested, str) or not digest_reference(actual):
        return False

    def normalized(reference):
        name, _, digest = reference.partition("@")
        tag = "latest"
        if ":" in name.rsplit("/", 1)[-1]:
            name, tag = name.rsplit(":", 1)
        first, slash, rest = name.partition("/")
        if slash and ("." in first or ":" in first or first == "localhost"):
            domain, repository = first, rest
        else:
            domain, repository = "docker.io", name
        if domain in ("docker.io", "index.docker.io"):
            domain = "docker.io"
            if "/" not in repository:
                repository = "library/" + repository
        return domain, repository, tag, digest

    # Docker may resolve a requested tag in the service spec. Tasks must then
    # match that resolved spec, not merely any digest under the original tag.
    actual_parts, requested_parts = normalized(actual), normalized(requested)
    if requested_parts[3]:
        return actual_parts[:2] == requested_parts[:2] and actual_parts[3] == requested_parts[3]
    return actual_parts[:3] == requested_parts[:3]


def expected_services(config: dict, stack: str) -> dict:
    result = {}
    for name, service in config.get("services", {}).items():
        deploy = service.get("deploy", {})
        mode = deploy.get("mode", "replicated")
        if mode not in ("replicated", "global"):
            raise ReleaseError("Cannot verify this service mode; supported modes are replicated and global")
        replicas = deploy.get("replicas", 1) if mode == "replicated" else None
        if mode == "replicated" and (not isinstance(replicas, int) or isinstance(replicas, bool) or replicas < 0):
            raise ReleaseError("Application replicas must be a nonnegative integer")
        if mode == "global":
            warning("Global service differs from the starter profile; verifying its actual Swarm desired task count")
        elif replicas == 0:
            warning("Service is configured with zero replicas; verification will confirm it is scaled down")
        image = service.get("image")
        if not image_reference(image):
            raise ReleaseError("Every deployed application needs a usable image reference")
        if not digest_reference(image):
            warning("Service uses an image tag; verification will compare tasks with Docker's resulting service spec")
        result[f"{stack}_{name}"] = {"image": image, "replicas": replicas, "mode": mode}
    if not result:
        raise ReleaseError("The rendered stack contains no application services")
    return result


def check_release_labels(config: dict, manifest: dict) -> None:
    for service in config["services"].values():
        labels = service.get("deploy", {}).get("labels", {})
        if (str(labels.get(PROJECT_LABEL, "")) != str(manifest["project_id"])
                or str(labels.get(PIPELINE_LABEL, "")) != str(manifest["pipeline_id"])):
            warning("Service CI project/pipeline labels are missing or differ; continuing without matching deployment markers")


def check_manager(env: dict) -> None:
    info = parse_json_output(docker(env, "info", "--format", "{{json .Swarm}}"))
    if (not isinstance(info, dict) or info.get("LocalNodeState") != "active"
            or info.get("ControlAvailable") is not True):
        raise ReleaseError("Deploy runner must connect to an active Swarm manager")
    expected = env.get("EXPECTED_SWARM_ID", "").strip()
    if not expected:
        warning("EXPECTED_SWARM_ID is not set; target cluster identity was not checked")
    elif info.get("Cluster", {}).get("ID") != expected:
        warning("Docker target differs from EXPECTED_SWARM_ID; continuing on the configured active Swarm manager")


def check_networks(config: dict, env: dict) -> None:
    for name, network in config.get("networks", {}).items():
        if isinstance(network, dict) and network.get("external"):
            external = network["external"]
            actual_name = network.get("name") or (external.get("name") if isinstance(external, dict) else None) or name
            docker(env, "network", "inspect", "--format", "{{.ID}}", actual_name)


def check_current_release(expected: dict, stack: str, release: dict, env: dict) -> None:
    existing = set(docker(env, "service", "ls", "--filter", f"label=com.docker.stack.namespace={stack}",
                          "--format", "{{.Name}}").splitlines())
    if existing - set(expected):
        warning("Existing stack has services absent from this config; continuing without pruning those services")
    for name in sorted(existing):
        metadata = parse_json_output(docker(env, "service", "inspect", "--format", SERVICE_METADATA, name))
        labels = metadata.get("labels") or {}
        if str(labels.get(PROJECT_LABEL, "")) != str(release["project_id"]):
            warning("Existing stack ownership differs or is unrecorded; continuing with this project's requested deployment")
        current_pipeline = str(labels.get(PIPELINE_LABEL, ""))
        if not current_pipeline.isdigit():
            warning("Existing stack has no valid pipeline marker; deployment order could not be checked")
        elif int(current_pipeline) > release["pipeline_id"]:
            warning("A newer pipeline marker is already deployed; continuing with the requested older release")


def migration(env: dict, release: dict) -> None:
    image = release["images"].get("MIGRATOR_IMAGE")
    if not image_reference(image):
        raise ReleaseError("Migration requires a usable MIGRATOR_IMAGE in the build manifest")
    if not digest_reference(image):
        warning("Migrator uses an image tag instead of an immutable digest; continuing")
    resource_args = []
    cpu = env.get("MIGRATOR_CPUS", "").strip()
    if cpu:
        try:
            if not Decimal(cpu).is_finite() or Decimal(cpu) < 0:
                raise InvalidOperation
        except InvalidOperation:
            raise ReleaseError("MIGRATOR_CPUS must be a nonnegative CPU limit") from None
        resource_args.extend(["--cpus", cpu])
        if Decimal(cpu) == 0:
            warning("Migrator CPU limit is zero; Docker will not impose a CPU limit")
    else:
        warning("MIGRATOR_CPUS is not set; continuing without an explicit migrator CPU limit")
    memory = env.get("MIGRATOR_MEMORY", "").strip()
    if memory:
        limit_bytes = memory_bytes(memory, "MIGRATOR_MEMORY", allow_zero=True)
        resource_args.extend(["--memory", str(limit_bytes)])
        if limit_bytes == 0:
            warning("Migrator memory limit is zero; Docker will not impose a memory limit")
    else:
        warning("MIGRATOR_MEMORY is not set; continuing without an explicit migrator memory limit")
    duration = positive_int(env, "MIGRATION_TIMEOUT")
    connection = secret_required(env, "APP_MIGRATOR_POSTGRES_CONNECTION")
    job_id = positive_int(env, "CI_JOB_ID")
    name = f"ci-migrate-{release['project_id']}-{job_id}"
    # Pass the value via the subprocess environment, not a command-line argument.
    private_env = dict(env, ConnectionStrings__Postgres=connection)
    docker(env, "pull", image, timeout=1200)
    try:
        docker(private_env, "run", "--rm", "--name", name, *resource_args,
               "-e", "ConnectionStrings__Postgres", image, timeout=duration)
    finally:
        # Docker CLI cancellation does not guarantee a standalone container stopped.
        # Only remove this job's uniquely named migrator, never an app service/stack.
        remaining = docker(env, "container", "ls", "--all", "--filter", f"name=^/{name}$",
                           "--format", "{{.ID}}", timeout=30)
        if remaining:
            docker(env, "rm", "--force", name, timeout=30)


def service_ready(name: str, desired: dict, env: dict, deadline: float | None = None) -> tuple | None:
    def inspect(*args):
        remaining = 10 if deadline is None else deadline - time.monotonic()
        if remaining <= 0:
            raise ReleaseError("Rollout verification exceeded its deadline")
        return docker(env, *args, timeout=min(10, remaining))

    metadata = parse_json_output(inspect("service", "inspect", "--format", SERVICE_METADATA, name))
    update_state = (metadata.get("update") or {}).get("State", "")
    if "paused" in update_state or update_state.startswith("rollback"):
        raise ReleaseError(f"Service {name} update paused or rolled back")
    if not image_matches(metadata.get("image"), desired["image"]) or update_state not in ("", "completed"):
        return None
    replicas = desired.get("replicas")
    if desired.get("mode", "replicated") == "global":
        counts = inspect("service", "ls", "--filter", f"name={name}", "--format", "{{.Name}} {{.Replicas}}")
        matches = [line.split() for line in counts.splitlines() if line.split() and line.split()[0] == name]
        if len(matches) != 1 or len(matches[0]) != 2:
            raise ReleaseError("Cannot read global service desired/running replica counts")
        pair = re.fullmatch(r"([0-9]+)/([0-9]+)", matches[0][1])
        if pair is None:
            raise ReleaseError("Cannot parse global service desired/running replica counts")
        running, replicas = (int(value) for value in pair.groups())
        if running != replicas:
            return None
    task_ids = inspect("service", "ps", "--quiet", name).splitlines()
    if not task_ids:
        return () if replicas == 0 else None
    raw_tasks = inspect("inspect", "--type", "task", "--format", TASK_METADATA, *task_ids).splitlines()
    if len(raw_tasks) != len(task_ids):
        return None
    tasks = [(task_id, parse_json_output(raw)) for task_id, raw in zip(task_ids, raw_tasks)]
    active_states = {"new", "allocated", "pending", "assigned", "accepted", "preparing", "ready", "starting", "running"}
    # A replaced task can still be running during stop-grace-period even though
    # its desired state is shutdown. Do not claim convergence while it remains.
    if any(task.get("desired") != "running" and task.get("state") in active_states for _, task in tasks):
        return None
    current = [(task_id, task) for task_id, task in tasks if task.get("desired") == "running"]
    if len(current) != replicas or any(
        task.get("state") != "running" or not image_matches(task.get("image"), metadata["image"]) for _, task in current
    ):
        return None
    return tuple(sorted(task_id for task_id, _ in current))


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def readiness(url: str, timeout: float = 5, success_codes: frozenset[int] | None = None) -> bool:
    accepted = frozenset({200}) if success_codes is None else success_codes
    try:
        with urllib.request.build_opener(NoRedirect()).open(url, timeout=timeout) as response:
            return response.status in accepted
    except urllib.error.HTTPError as response:
        # urllib represents non-2xx (including redirects we did not follow) as
        # HTTPError. These are actual HTTP responses, unlike connection errors.
        try:
            return response.code in accepted
        finally:
            response.close()
    except (OSError, ValueError, urllib.error.URLError):
        return False


def readiness_settings(env: dict) -> tuple[str | None, int, int, frozenset[int]]:
    url = env.get("READINESS_URL", "").strip() or None
    if url:
        try:
            parts = urllib.parse.urlsplit(url)
        except ValueError:
            raise ReleaseError("READINESS_URL is not a valid HTTP(S) URL") from None
        if parts.scheme not in ("http", "https") or not parts.hostname or parts.username or parts.password or parts.fragment:
            raise ReleaseError("READINESS_URL must be an HTTP(S) URL without credentials or fragments")
        if parts.path != "/health":
            warning("READINESS_URL uses a path other than /health; continuing with that URL; coordinate the load balancer health-check path with admin")
    else:
        warning("READINESS_URL is not set; HTTP readiness will not be checked; only Swarm convergence will be verified")
    raw_codes = env.get("READINESS_SUCCESS_CODES", "200")
    codes = raw_codes.split(",") if isinstance(raw_codes, str) else []
    if not codes or any(not re.fullmatch(r"[1-5][0-9]{2}", code.strip()) for code in codes):
        raise ReleaseError("READINESS_SUCCESS_CODES must be a comma-separated list of HTTP status codes from 100 to 599")
    success_codes = frozenset(int(code.strip()) for code in codes)
    duration = positive_int(env, "ROLLOUT_TIMEOUT", "300")
    stable_value = env.get("STABILITY_SECONDS", "30")
    if not isinstance(stable_value, str) or not stable_value.isdigit():
        raise ReleaseError("STABILITY_SECONDS must be a nonnegative integer")
    stable_seconds = int(stable_value)
    if stable_seconds >= duration:
        raise ReleaseError("STABILITY_SECONDS must be shorter than ROLLOUT_TIMEOUT")
    if stable_seconds == 0:
        warning("STABILITY_SECONDS is zero; checking convergence and configured HTTP readiness once without a stability window")
    return url, duration, stable_seconds, success_codes


def wait_ready(expected: dict, env: dict, settings: tuple[str | None, int, int, frozenset[int]] | None = None) -> None:
    url, duration, stable_seconds, success_codes = settings if settings is not None else readiness_settings(env)
    deadline = time.monotonic() + duration
    stable_since = None
    previous_tasks = None
    while time.monotonic() < deadline:
        tasks = tuple((name, service_ready(name, desired, env, deadline)) for name, desired in expected.items())
        services_ok = all(task_ids is not None for _, task_ids in tasks)
        healthy = services_ok and (url is None or readiness(url, min(5, max(0.1, deadline - time.monotonic())), success_codes))
        now = time.monotonic()
        if now >= deadline:
            break
        if healthy:
            stable_since = now if stable_since is None or tasks != previous_tasks else stable_since
            if now - stable_since >= stable_seconds:
                return
        else:
            stable_since = None
        previous_tasks = tasks
        time.sleep(min(2, max(0, deadline - time.monotonic())))
    raise ReleaseError("Rollout/readiness did not stabilize before its deadline; inspect service tasks securely")


def release(manifest_path: str, stack_files: list[str], migrate: bool, env: dict) -> None:
    # Import lazily so build-only use does not require the stack parser dependency.
    from validate import validate_stack

    manifest = load_manifest(manifest_path, env)
    stack = required(env, "STACK_NAME")
    if not re.fullmatch(r"[a-z0-9][a-z0-9_-]*", stack):
        warning("STACK_NAME differs from the starter naming convention; Docker will validate the supplied name")
    readiness = readiness_settings(env)
    deployment_env = dict(env, **manifest["images"])
    with registry_session(deployment_env) as session:
        check_manager(session)
        config = validate_stack(stack_files, manifest["environment"], session, release_images=manifest["images"])
        expected = expected_services(config, stack)
        check_release_labels(config, manifest)
        check_networks(config, session)
        check_current_release(expected, stack, manifest, session)
        if migrate:
            migration(session, manifest)
        check_current_release(expected, stack, manifest, session)
        args = ["stack", "deploy", "--with-registry-auth"]
        for path in stack_files:
            args.extend(["--compose-file", path])
        # Use original files with the same environment as validation. Feeding an
        # interpolated secret through a second parse could expand literal '$'.
        docker(session, *args, stack, timeout=180)
        wait_ready(expected, session, readiness)
        if readiness[0] is None:
            print("Services converged to the configured image references; HTTP readiness was not checked")
        elif readiness[2] == 0:
            print("Services converged to the configured image references and passed HTTP readiness; stability window was disabled")
        else:
            print("Services converged to the configured image references and passed stable HTTP readiness")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", default="release.json")
    parser.add_argument("--stack-file", action="append", required=True)
    parser.add_argument("--migrate", action="store_true")
    args = parser.parse_args()
    try:
        with cancellation_handler():
            release(args.manifest, args.stack_file, args.migrate, dict(os.environ))
        return 0
    except (ValueError, InterruptedError, KeyboardInterrupt) as error:
        print(f"Release stopped: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
