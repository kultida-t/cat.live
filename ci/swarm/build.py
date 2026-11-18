"""Build each declared image and publish a non-secret release manifest."""

from __future__ import annotations

import argparse
import os
import re
import sys
import time
from pathlib import Path

from common import (
    ReleaseError, cancellation_handler, context, digest_reference, docker,
    parse_json_output, read_json, registry_session, required, validate_image_variable, warning, write_json,
)

# Docker distribution/reference pathComponent grammar. A namespace is one or
# more components; the image name occupies one final component.
REPOSITORY_COMPONENT = r"[a-z0-9]+(?:(?:[._]|__|[-]+)[a-z0-9]+)*"


def image_inputs(path: str) -> list[dict]:
    images = read_json(path)
    if not isinstance(images, list) or not images:
        raise ReleaseError("images.json must contain a nonempty image list")
    names, variables = set(), set()
    for image in images:
        if not isinstance(image, dict) or not {"name", "dockerfile", "context", "image_variable"}.issubset(image):
            raise ReleaseError("Each image requires name, dockerfile, context and image_variable")
        if set(image) != {"name", "dockerfile", "context", "image_variable"}:
            warning("Additional image manifest fields are not used by this build helper")
        name, variable = image["name"], image["image_variable"]
        if not isinstance(name, str) or not re.fullmatch(REPOSITORY_COMPONENT, name):
            raise ReleaseError("Image names must be lowercase Docker repository components")
        validate_image_variable(variable)
        if not re.fullmatch(r"[A-Z][A-Z0-9_]*_IMAGE", variable):
            warning("Image variables conventionally use uppercase names ending in _IMAGE")
        if name in names or variable in variables:
            raise ReleaseError("Image names and image variables must be unique")
        names.add(name)
        variables.add(variable)
        for key in ("dockerfile", "context"):
            value = image[key]
            if not isinstance(value, str) or not value:
                raise ReleaseError("Build paths must be nonempty strings")
            resolved = Path(value).resolve()
            if Path(value).is_absolute() or not resolved.is_relative_to(Path.cwd().resolve()):
                warning("A build path is not relative to this checkout; verify the runner has the intended build inputs")
        if not Path(image["dockerfile"]).is_file() or not Path(image["context"]).is_dir():
            raise ReleaseError("An image Dockerfile or build context is missing")
    return images


def build(images_file: str, output: str, env: dict) -> dict:
    release = context(env)
    namespace = required(env, "REGISTRY_NAMESPACE")
    if not re.fullmatch(rf"{REPOSITORY_COMPONENT}(?:/{REPOSITORY_COMPONENT})*", namespace):
        raise ReleaseError("REGISTRY_NAMESPACE must be a lowercase repository path without a hostname")
    inputs = image_inputs(images_file)
    prefix = {"staging": "stg", "production": "prod"}.get(release["environment"])
    if prefix is None:
        prefix = re.sub(r"[^a-zA-Z0-9_.-]+", "-", release["environment"]).strip(".-")[:40] or "custom"
    tag = f"{prefix}-{release['commit_sha']}-{release['pipeline_id']}"
    release["images"] = {}
    # Never leave an earlier successful manifest usable after a failed rebuild.
    Path(output).unlink(missing_ok=True)
    with registry_session(env) as session:
        registry = required(session, "DOCKER_REGISTRY")
        for image in inputs:
            print(f"Building image {image['name']}", flush=True)
            repository = f"{registry}/{namespace}/{image['name']}"
            tagged = f"{repository}:{tag}"
            docker(session, "build", "--file", image["dockerfile"], "--tag", tagged, image["context"], timeout=3600)
            for attempt in range(3):
                try:
                    docker(session, "push", tagged, timeout=1200)
                    break
                except ReleaseError:
                    if attempt == 2:
                        raise
                    time.sleep(10)
            # Pull the published reference before inspecting RepoDigests, not a local build ID.
            docker(session, "pull", tagged, timeout=1200)
            digests = parse_json_output(docker(
                session, "image", "inspect", "--format", "{{json .RepoDigests}}", tagged
            ))
            matches = [value for value in digests or []
                       if digest_reference(value) and value.startswith(repository + "@sha256:")]
            if len(set(matches)) == 1:
                release["images"][image["image_variable"]] = matches[0]
            else:
                warning("A unique published digest is unavailable; recording the successfully pushed tag instead. Check tag immutability before deployment")
                release["images"][image["image_variable"]] = tagged
            print(f"Published image {image['name']}", flush=True)
    write_json(output, release)
    return release


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--images", default="ci/swarm/images.json")
    parser.add_argument("--output", default="release.json")
    args = parser.parse_args()
    try:
        with cancellation_handler():
            build(args.images, args.output, dict(os.environ))
        print("Release manifest written; it contains image references and CI identity only")
        return 0
    except (ReleaseError, InterruptedError, KeyboardInterrupt) as error:
        print(f"Build stopped: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
