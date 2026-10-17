from __future__ import annotations

import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
GUIDANCE_SOURCE = "home/dot_config/exact_agents/AGENTS.md"


class AgentGuidanceStructureTest(unittest.TestCase):
    def _guidance_paths(self) -> list[Path]:
        exact_agents = REPO_ROOT / "home/dot_config/exact_agents"
        return [
            REPO_ROOT / "AGENTS.md",
            exact_agents / "AGENTS.md",
            exact_agents / "README.md",
            *sorted((exact_agents / "agents").glob("*.md")),
        ]

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
