"""Tests for the Claude Code date-context hook command."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPO_ROOT = Path(__file__).resolve().parents[2]
SETTINGS_PATH = REPO_ROOT / "home" / "private_dot_config" / "claude" / "settings.json"
SCRIPT_PATH = REPO_ROOT / "home" / "private_dot_config" / "exact_agents" / "date_context.py"


class DateContextHookTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        hooks = json.loads(SETTINGS_PATH.read_text())["hooks"]["UserPromptSubmit"]
        cls.command = hooks[0]["hooks"][0]["command"]

    def run_hook(self, home, path):
        return subprocess.run(
            ["/bin/sh", "-c", self.command],
            env={"HOME": str(home), "PATH": path},
            input="{}\n",
            capture_output=True,
            text=True,
            check=False,
        )

    def test_missing_script_succeeds_silently(self):
        with tempfile.TemporaryDirectory() as directory:
            result = self.run_hook(directory, os.environ["PATH"])

        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")
        self.assertEqual(result.stderr, "")

    def test_missing_python_succeeds_silently(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            agents = home / ".agents"
            agents.mkdir()
            (agents / "date_context.py").write_text("raise SystemExit(2)\n")
            bin_dir = home / "bin"
            bin_dir.mkdir()

            result = self.run_hook(home, str(bin_dir))

        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")
        self.assertEqual(result.stderr, "")

    def test_existing_script_emits_date_context(self):
        self.assertIsNotNone(shutil.which("python3"))
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            agents = home / ".agents"
            agents.mkdir()
            shutil.copyfile(SCRIPT_PATH, agents / "date_context.py")

            result = self.run_hook(home, os.environ["PATH"])

        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads(result.stdout)
        self.assertEqual(
            payload["hookSpecificOutput"]["hookEventName"], "UserPromptSubmit"
        )
        self.assertTrue(
            payload["hookSpecificOutput"]["additionalContext"].startswith(
                "Current local date/time for this UserPromptSubmit event only: "
            )
        )


if __name__ == "__main__":
    unittest.main()
