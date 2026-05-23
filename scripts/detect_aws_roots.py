#!/usr/bin/env python3
"""Detect affected AWS OpenTofu roots for GitHub Actions."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
from pathlib import Path


AWS_DIR = Path("infrastructure/aws")
MANUAL_ROOTS = {"bootstrap", "identity"}
NON_ROOT_DIRS = {"modules"}
SHARED_PATHS = (AWS_DIR / "modules",)
TOOLING_PATHS = {
    Path(".github/workflows/aws-infrastructure.yml"),
    Path("scripts/detect_aws_roots.py"),
}


def normalize_path(path: str) -> Path:
    return Path(path.strip())


def is_aws_root(repo_root: Path, root_name: str) -> bool:
    if root_name in NON_ROOT_DIRS:
        return False

    root_path = repo_root / AWS_DIR / root_name
    return root_path.is_dir() and any(root_path.glob("*.tf"))


def discover_roots(repo_root: Path) -> tuple[list[str], list[str]]:
    aws_path = repo_root / AWS_DIR
    if not aws_path.is_dir():
        return [], []

    roots = sorted(
        path.name
        for path in aws_path.iterdir()
        if path.is_dir() and is_aws_root(repo_root, path.name)
    )
    deployable_roots = [root for root in roots if root not in MANUAL_ROOTS]
    return roots, deployable_roots


def changed_files_from_git(repo_root: Path, base_sha: str, head_sha: str) -> list[Path]:
    result = subprocess.run(
        ["git", "diff", "--name-only", base_sha, head_sha],
        cwd=repo_root,
        check=True,
        text=True,
        capture_output=True,
    )
    return [normalize_path(line) for line in result.stdout.splitlines() if line.strip()]


def changed_files_from_file(path: Path) -> list[Path]:
    return [normalize_path(line) for line in path.read_text().splitlines() if line.strip()]


def is_under(path: Path, parent: Path) -> bool:
    return path == parent or parent in path.parents


def detect_roots(repo_root: Path, event_name: str, changed_files: list[Path]) -> dict[str, list[str]]:
    _all_roots, deployable_roots = discover_roots(repo_root)

    changed_roots: set[str] = set()
    shared_changed = False
    tooling_changed = False

    for file_path in changed_files:
        if file_path in TOOLING_PATHS:
            tooling_changed = True

        if any(is_under(file_path, shared_path) for shared_path in SHARED_PATHS):
            shared_changed = True
            continue

        parts = file_path.parts
        if len(parts) >= 4 and parts[0] == "infrastructure" and parts[1] == "aws":
            root = parts[2]
            if is_aws_root(repo_root, root):
                changed_roots.add(root)

    changed_deployable_roots = sorted(root for root in changed_roots if root not in MANUAL_ROOTS)
    changed_manual_roots = sorted(root for root in changed_roots if root in MANUAL_ROOTS)

    validate_roots = sorted(set(changed_deployable_roots + changed_manual_roots))
    plan_roots = changed_deployable_roots
    apply_roots: list[str] = []

    if event_name == "pull_request":
        if shared_changed or tooling_changed:
            validate_roots = sorted(set(validate_roots + deployable_roots))
            plan_roots = deployable_roots
    else:
        if shared_changed:
            apply_roots = deployable_roots
        else:
            apply_roots = changed_deployable_roots

    return {
        "validate_roots": validate_roots,
        "plan_roots": sorted(plan_roots),
        "apply_roots": sorted(apply_roots),
    }


def write_github_output(outputs: dict[str, list[str]], output_path: str | None) -> None:
    if not output_path:
        return

    with open(output_path, "a", encoding="utf-8") as output:
        for key, value in outputs.items():
            output.write(f"{key}={json.dumps(value)}\n")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", default=".", help="Repository root path")
    parser.add_argument("--event-name", default=os.environ.get("EVENT_NAME", ""))
    parser.add_argument("--base-sha", default=os.environ.get("BASE_SHA", ""))
    parser.add_argument("--head-sha", default=os.environ.get("HEAD_SHA", ""))
    parser.add_argument("--changed-files-file", help="Read changed files from this file instead of git diff")
    parser.add_argument("--github-output", default=os.environ.get("GITHUB_OUTPUT"))
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    repo_root = Path(args.repo_root).resolve()

    if args.changed_files_file:
        changed_files = changed_files_from_file(Path(args.changed_files_file))
    else:
        if not args.base_sha or not args.head_sha:
            raise SystemExit("--base-sha and --head-sha are required when --changed-files-file is not set")
        changed_files = changed_files_from_git(repo_root, args.base_sha, args.head_sha)

    outputs = detect_roots(repo_root, args.event_name, changed_files)
    write_github_output(outputs, args.github_output)

    print("Changed files:", json.dumps([str(path) for path in changed_files]))
    for key, value in outputs.items():
        print(f"{key}:", json.dumps(value))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
