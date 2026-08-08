from __future__ import annotations

import json
import subprocess
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
CONTRACT_PATH = REPO_ROOT / "tests/fixtures/agent_guidance_requirements.json"
EXTRA_DIRECTIVE_LINES = {4, 14}


class AgentGuidanceRequirementsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.contract = json.loads(CONTRACT_PATH.read_text(encoding="utf-8"))
        cls.requirements = cls.contract["requirements"]

    def test_contract_identifies_the_migrated_source(self) -> None:
        self.assertEqual(self.contract["version"], 1)
        self.assertEqual(
            self.contract["source_path"],
            "home/dot_config/exact_agents/AGENTS.md",
        )
        self.assertRegex(self.contract["source_commit"], r"^[0-9a-f]{7,40}$")

    def test_contract_covers_every_original_requirement(self) -> None:
        identifiers = [item["id"] for item in self.requirements]
        source_lines = [item["source_line"] for item in self.requirements]
        source = subprocess.run(
            [
                "git",
                "show",
                f"{self.contract['source_commit']}:{self.contract['source_path']}",
            ],
            cwd=REPO_ROOT,
            check=True,
            capture_output=True,
            text=True,
        ).stdout.splitlines()
        bullet_lines = {
            number
            for number, line in enumerate(source, start=1)
            if line.lstrip().startswith("- ")
        }

        self.assertEqual(len(identifiers), len(set(identifiers)))
        self.assertEqual(len(source_lines), len(set(source_lines)))
        self.assertEqual(set(source_lines), bullet_lines | EXTRA_DIRECTIVE_LINES)

    def test_every_requirement_exists_at_its_mapped_destination(self) -> None:
        for item in self.requirements:
            with self.subTest(requirement=item["id"]):
                relative = Path(item["path"])
                self.assertFalse(relative.is_absolute())
                self.assertNotIn("..", relative.parts)
                destination = REPO_ROOT / relative
                self.assertTrue(destination.is_file(), destination)
                text = destination.read_text(encoding="utf-8")
                self.assertTrue(item["contains"])
                for expected in item["contains"]:
                    self.assertIn(expected, text)

    def test_third_party_research_has_one_routing_rule_and_skill_owner(self) -> None:
        agents_path = REPO_ROOT / "home/dot_config/exact_agents/AGENTS.md"
        skill_path = (
            REPO_ROOT
            / "home/dot_config/exact_agents/skills/research-before-implementation/SKILL.md"
        )
        agents = agents_path.read_text(encoding="utf-8")
        skill = skill_path.read_text(encoding="utf-8")
        web_search = skill.index(
            "Call the agent's native web search tool (`web_search` in Codex)"
        )
        github_search = skill.index(
            "call the native web search tool again with results restricted to `github.com`"
        )
        implementation = skill.index("Implement and verify")

        self.assertEqual(agents.count("`research-before-implementation`"), 1)
        self.assertLess(web_search, github_search)
        self.assertLess(github_search, implementation)
        self.assertIn("Do not edit files until both tool calls are complete", skill)
        self.assertIn(
            "In the final response, name and link the web sources and GitHub examples consulted",
            skill,
        )

    def test_always_on_sections_are_not_duplicated_in_managed_skills(self) -> None:
        agents_path = REPO_ROOT / "home/dot_config/exact_agents/AGENTS.md"
        skill_root = REPO_ROOT / "home/dot_config/exact_agents/skills"
        always_on_sections = {
            line
            for line in agents_path.read_text(encoding="utf-8").splitlines()
            if line.startswith("## ")
        }
        duplicates = {
            (skill.relative_to(REPO_ROOT).as_posix(), line)
            for skill in skill_root.glob("*/SKILL.md")
            for line in skill.read_text(encoding="utf-8").splitlines()
            if line in always_on_sections
        }

        self.assertEqual(duplicates, set())


if __name__ == "__main__":
    unittest.main()
