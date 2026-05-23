#!/usr/bin/env python3
"""Fixture checks for AWS root detection."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

import detect_aws_roots


class DetectAwsRootsTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.repo = Path(self.temp_dir.name)

        for root in ("bootstrap", "identity", "guardrails", "homelab-heartbeat"):
            root_path = self.repo / "infrastructure" / "aws" / root
            root_path.mkdir(parents=True)
            (root_path / "main.tf").write_text("terraform {}\n")

        modules_path = self.repo / "infrastructure" / "aws" / "modules" / "shared"
        modules_path.mkdir(parents=True)
        (modules_path / "main.tf").write_text("variable \"name\" {}\n")

        workflow_path = self.repo / ".github" / "workflows"
        workflow_path.mkdir(parents=True)
        (workflow_path / "aws-infrastructure.yml").write_text("name: aws\n")

        scripts_path = self.repo / "scripts"
        scripts_path.mkdir(parents=True)
        (scripts_path / "detect_aws_roots.py").write_text("# detector\n")

    def tearDown(self) -> None:
        self.temp_dir.cleanup()

    def detect(self, event_name: str, *files: str) -> dict[str, list[str]]:
        return detect_aws_roots.detect_roots(self.repo, event_name, [Path(file) for file in files])

    def test_pr_deployable_root_change(self) -> None:
        self.assertEqual(
            self.detect("pull_request", "infrastructure/aws/guardrails/main.tf"),
            {
                "validate_roots": ["guardrails"],
                "plan_roots": ["guardrails"],
                "apply_roots": [],
            },
        )

    def test_pr_manual_root_change_validates_without_plan(self) -> None:
        self.assertEqual(
            self.detect("pull_request", "infrastructure/aws/identity/main.tf"),
            {
                "validate_roots": ["identity"],
                "plan_roots": [],
                "apply_roots": [],
            },
        )

    def test_pr_shared_module_change_affects_all_deployable_roots(self) -> None:
        self.assertEqual(
            self.detect("pull_request", "infrastructure/aws/modules/shared/main.tf"),
            {
                "validate_roots": ["guardrails", "homelab-heartbeat"],
                "plan_roots": ["guardrails", "homelab-heartbeat"],
                "apply_roots": [],
            },
        )

    def test_pr_workflow_change_affects_deployable_roots_only(self) -> None:
        self.assertEqual(
            self.detect("pull_request", ".github/workflows/aws-infrastructure.yml"),
            {
                "validate_roots": ["guardrails", "homelab-heartbeat"],
                "plan_roots": ["guardrails", "homelab-heartbeat"],
                "apply_roots": [],
            },
        )

    def test_push_workflow_change_does_not_apply(self) -> None:
        self.assertEqual(
            self.detect("push", "scripts/detect_aws_roots.py"),
            {
                "validate_roots": [],
                "plan_roots": [],
                "apply_roots": [],
            },
        )

    def test_push_shared_module_change_applies_deployable_roots(self) -> None:
        self.assertEqual(
            self.detect("push", "infrastructure/aws/modules/shared/main.tf"),
            {
                "validate_roots": [],
                "plan_roots": [],
                "apply_roots": ["guardrails", "homelab-heartbeat"],
            },
        )


if __name__ == "__main__":
    unittest.main()
