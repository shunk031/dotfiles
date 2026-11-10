"""Regression tests for Antigravity CLI settings modification."""

import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
HOME_SOURCE = REPO_ROOT / "home"
SETTINGS = HOME_SOURCE / "private_dot_config/antigravity-cli/settings.json"
MODIFY_TEMPLATE = HOME_SOURCE / "dot_gemini/antigravity-cli/modify_private_settings.json"
CHEZMOI = shutil.which("chezmoi")


class AntigravitySettingsTest(unittest.TestCase):
    @unittest.skipUnless(CHEZMOI, "requires chezmoi")
    def test_sparse_default_stays_sparse_and_explicit_true_is_corrected(self):
        managed = json.loads(SETTINGS.read_text())

        sparse = managed.copy()
        sparse.pop("enableTerminalSandbox")
        enabled = managed.copy()
        enabled["enableTerminalSandbox"] = True
        sparse_json = json.dumps(sparse, indent=2) + "\n"

        self.assertEqual(self._render(sparse_json), sparse_json)
        self.assertEqual(json.loads(self._render(json.dumps(enabled))), managed)

    def _render(self, current_json):
        with tempfile.TemporaryDirectory(prefix="antigravity-settings-test-") as temporary_directory:
            result = subprocess.run(
                [
                    CHEZMOI,
                    "--source",
                    str(HOME_SOURCE),
                    "--working-tree",
                    str(REPO_ROOT),
                    "--config",
                    "/dev/null",
                    "--config-format",
                    "toml",
                    "--cache",
                    str(Path(temporary_directory) / "cache"),
                    "execute-template",
                    "--with-stdin",
                    "--file",
                    str(MODIFY_TEMPLATE),
                ],
                cwd=REPO_ROOT,
                input=current_json,
                capture_output=True,
                text=True,
                check=True,
            )
        return result.stdout


if __name__ == "__main__":
    unittest.main()
