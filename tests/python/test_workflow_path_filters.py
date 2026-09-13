from __future__ import annotations

import re
from tempfile import TemporaryDirectory
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
WORKFLOWS = REPO_ROOT / ".github/workflows"
GLOB_METACHARACTERS = re.compile(r"[*?\[]")


def _workflow_paths(workflow: Path) -> dict[str, list[str]]:
    """Read path filters from the repository's two-space workflow layout."""
    lines = workflow.read_text(encoding="utf-8").splitlines()
    paths: dict[str, list[str]] = {}
    in_on_block = False
    event: str | None = None
    in_paths = False

    for line in lines:
        if line == "on:":
            in_on_block = True
            continue
        if not in_on_block:
            continue

        # Workflow event mappings use two spaces and end the `on` block.
        event_match = re.fullmatch(r"  (push|pull_request):", line)
        if event_match:
            event = event_match.group(1)
            in_paths = False
            continue
        if line and not line.startswith((" ", "\t")):
            break
        if event is None:
            continue

        if in_paths:
            # Comments and blank lines do not end a YAML sequence.
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            item = re.fullmatch(r"      - (.+)", line)
            if item:
                value = item.group(1)
                if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
                    value = value[1:-1]
                paths[event].append(value)
                continue

            # A four-space key or an event-level key ends the paths sequence.
            in_paths = False

        if line == "    paths:":
            paths[event] = []
            in_paths = True
            continue

    return paths


def _workflow_path_errors(workflow: Path, repo_root: Path) -> list[str]:
    """Return all path-filter violations found in one workflow."""
    paths = _workflow_paths(workflow)
    errors: list[str] = []

    for event, entries in paths.items():
        if not entries:
            errors.append(f"{workflow.name} {event} paths list is empty")

    if "push" in paths and "pull_request" in paths:
        if paths["push"] != paths["pull_request"]:
            errors.append(f"{workflow.name} push and pull_request paths differ")

    for event, entries in paths.items():
        for entry in entries:
            prefix = GLOB_METACHARACTERS.split(entry, maxsplit=1)[0]
            prefix = prefix.rstrip("/")
            if not (repo_root / prefix).exists():
                errors.append(
                    f"{workflow.name} {event} path does not exist: {entry}"
                )

    return errors


class WorkflowPathFiltersTest(unittest.TestCase):
    def test_push_and_pull_request_filters_match_and_point_to_real_paths(self) -> None:
        for workflow in sorted(WORKFLOWS.glob("*.yaml")):
            errors = _workflow_path_errors(workflow, REPO_ROOT)
            with self.subTest(workflow=workflow.name):
                self.assertEqual(errors, [])

    def test_fixture_reports_mismatch_and_missing_path(self) -> None:
        with TemporaryDirectory() as temporary_directory:
            repo_root = Path(temporary_directory)
            workflow = repo_root / ".github/workflows/fixture.yaml"
            workflow.parent.mkdir(parents=True)
            (repo_root / "existing").mkdir()
            workflow.write_text(
                """name: fixture
on:
  push:
    paths:
      # Comments and blank lines are valid inside a paths list.
      - "existing/**"

      - "does-not-exist/**"
  pull_request:
    paths:
      - "existing/**"
""",
                encoding="utf-8",
            )

            self.assertEqual(
                _workflow_path_errors(workflow, repo_root),
                [
                    "fixture.yaml push and pull_request paths differ",
                    "fixture.yaml push path does not exist: does-not-exist/**",
                ],
            )


if __name__ == "__main__":
    unittest.main()
