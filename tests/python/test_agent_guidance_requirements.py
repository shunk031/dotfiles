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


if __name__ == "__main__":
    unittest.main()
