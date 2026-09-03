from __future__ import annotations

import os
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
GUIDANCE_SOURCE = "home/dot_config/exact_agents/AGENTS.md"
GUIDANCE_EVAL = "home/dot_config/exact_agents/AGENTS.evals.json"
GUIDANCE_WRAPPER = "scripts/shuhari_guidance_gate.sh"
GUIDANCE_RUNNER = "shuhari eval instructions"
GUIDANCE_VALIDATE_HOOK = "shuhari-validate-instructions"
GUIDANCE_EVAL_HOOK = "shuhari-eval-instructions"


class AgentGuidanceStructureTest(unittest.TestCase):
    def _guidance_paths(self) -> list[Path]:
        exact_agents = REPO_ROOT / "home/dot_config/exact_agents"
        return [
            REPO_ROOT / "AGENTS.md",
            exact_agents / "AGENTS.md",
            exact_agents / "README.md",
            *sorted((exact_agents / "agents").glob("*.md")),
        ]

    def test_guidance_evaluation_wiring_has_one_truthful_consumer_map(self) -> None:
        prek = (REPO_ROOT / ".pre-commit-config.yaml").read_text(encoding="utf-8")
        hook_ids = {
            line.strip().removeprefix("- id: ")
            for line in prek.splitlines()
            if line.strip().startswith("- id: ")
        }
        self.assertIn(GUIDANCE_VALIDATE_HOOK, hook_ids)
        self.assertIn(GUIDANCE_EVAL_HOOK, hook_ids)
        self.assertNotIn("agent-guidance-", prek)

        wrapper_path = REPO_ROOT / GUIDANCE_WRAPPER
        self.assertTrue(wrapper_path.is_file(), GUIDANCE_WRAPPER)
        self.assertTrue(os.access(wrapper_path, os.X_OK), GUIDANCE_WRAPPER)

        entries = [
            line.strip().removeprefix("entry: ")
            for line in prek.splitlines()
            if line.strip().startswith("entry: ")
        ]
        guidance_entries = [entry for entry in entries if GUIDANCE_WRAPPER in entry]
        self.assertEqual(len(guidance_entries), 2, entries)
        self.assertEqual(
            {
                entry.removeprefix(GUIDANCE_WRAPPER).strip()
                for entry in guidance_entries
            },
            {"validate", "eval"},
            guidance_entries,
        )

        wrapper = wrapper_path.read_text(encoding="utf-8")
        self.assertIn(GUIDANCE_RUNNER, wrapper)
        self.assertIn(GUIDANCE_SOURCE, wrapper)
        self.assertIn(GUIDANCE_EVAL, wrapper)
        self.assertIn("--validate-only", wrapper)

        makefile = (REPO_ROOT / "Makefile").read_text(encoding="utf-8")
        self.assertIn(GUIDANCE_WRAPPER, makefile)
        self.assertNotIn(GUIDANCE_RUNNER, makefile)
        self.assertTrue((REPO_ROOT / GUIDANCE_SOURCE).is_file(), GUIDANCE_SOURCE)
        self.assertTrue((REPO_ROOT / GUIDANCE_EVAL).is_file(), GUIDANCE_EVAL)

    def test_guidance_path_inventory_has_expected_size(self) -> None:
        self.assertEqual(len(self._guidance_paths()), 4)

    def test_skill_routing_identifiers_are_unique(self) -> None:
        agents = (REPO_ROOT / GUIDANCE_SOURCE).read_text(encoding="utf-8")
        # Skill names are integration identifiers. Their cardinality protects
        # the single routing edge without pinning the surrounding prose.
        for skill in (
            "shunk031-manage-agent-guidance",
            "shunk031-research-before-implementation",
        ):
            with self.subTest(skill=skill):
                self.assertEqual(agents.count(f"`{skill}`"), 1)

    def test_always_on_sections_have_one_owner(self) -> None:
        section_owners: dict[str, list[Path]] = {}
        for path in (
            REPO_ROOT / "AGENTS.md",
            REPO_ROOT / GUIDANCE_SOURCE,
        ):
            for line in path.read_text(encoding="utf-8").splitlines():
                if line.startswith("## "):
                    section_owners.setdefault(line, []).append(path)

        duplicate_always_on = {
            section: paths
            for section, paths in section_owners.items()
            if len(paths) > 1
        }
        self.assertEqual(duplicate_always_on, {})


if __name__ == "__main__":
    unittest.main()
