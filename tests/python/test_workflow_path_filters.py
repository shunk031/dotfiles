from __future__ import annotations

import re
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

        if line == "    paths:":
            paths[event] = []
            in_paths = True
            continue
        if line.startswith("    ") and not line.startswith("      - "):
            in_paths = False
        if in_paths:
            item = re.fullmatch(r"      - (.+)", line)
            if item:
                value = item.group(1)
                if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
                    value = value[1:-1]
                paths[event].append(value)

    return paths


class WorkflowPathFiltersTest(unittest.TestCase):
    def test_push_and_pull_request_filters_match_and_point_to_real_paths(self) -> None:
        for workflow in sorted(WORKFLOWS.glob("*.yaml")):
            paths = _workflow_paths(workflow)
            if "push" in paths and "pull_request" in paths:
                with self.subTest(workflow=workflow.name, check="event parity"):
                    self.assertEqual(paths["push"], paths["pull_request"])

            for event, entries in paths.items():
                for entry in entries:
                    with self.subTest(
                        workflow=workflow.name, event=event, entry=entry
                    ):
                        prefix = GLOB_METACHARACTERS.split(entry, maxsplit=1)[0]
                        prefix = prefix.rstrip("/")
                        self.assertTrue(
                            (REPO_ROOT / prefix).exists(),
                            f"{workflow.name} {event} path does not exist: {entry}",
                        )


if __name__ == "__main__":
    unittest.main()
