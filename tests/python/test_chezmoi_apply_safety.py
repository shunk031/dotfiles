"""Regression tests for deterministic modes and source-safe adapters."""

import os
from pathlib import Path
import shutil
import stat
import subprocess
import tempfile
import unittest


REPO_ROOT = Path(__file__).resolve().parents[2]
HOME_SOURCE = REPO_ROOT / "home"
CHEZMOI = shutil.which("chezmoi")


class ChezmoiApplySafetyTest(unittest.TestCase):
    def test_home_symlink_templates_do_not_target_the_public_source(self):
        offenders = []
        for template in sorted(HOME_SOURCE.rglob("symlink_*.tmpl")):
            content = template.read_text()
            if ".chezmoi.sourceDir" in content or ".local/share/chezmoi/home/" in content:
                offenders.append(str(template.relative_to(REPO_ROOT)))

        self.assertEqual(offenders, [])

    @unittest.skipUnless(CHEZMOI and os.name == "posix", "requires POSIX chezmoi")
    def test_apply_uses_configured_modes_with_caller_umask_077(self):
        with tempfile.TemporaryDirectory(prefix="chezmoi-mode-test-") as temp:
            root = Path(temp)
            home = root / "home"
            home.mkdir()
            env = {
                key: value
                for key, value in os.environ.items()
                if not key.startswith("HERDR_")
            }
            env.update(CI="true", HOME=str(home))
            config = root / "chezmoi.yaml"
            rendered_config = subprocess.run(
                [
                    CHEZMOI,
                    "--source",
                    str(HOME_SOURCE),
                    "--config",
                    "/dev/null",
                    "--config-format",
                    "toml",
                    "execute-template",
                    "--init",
                    "--promptString",
                    "Email address=test@example.com",
                    "--promptString",
                    "System (client or server)=client",
                    "--file",
                    str(HOME_SOURCE / ".chezmoi.yaml.tmpl"),
                ],
                env=env,
                capture_output=True,
                text=True,
                check=True,
            )
            config.write_text(rendered_config.stdout)

            sources = {
                "public": root / "public-source",
                "private": root / "private-source",
                "executable": root / "executable-source",
            }
            files = {
                "public": (sources["public"] / "dot_public" / "public_file", "public\n"),
                "private": (sources["private"] / "private_dot_private" / "private_secret", "private\n"),
                "executable": (sources["executable"] / "bin" / "executable_tool", "#!/bin/sh\n"),
            }
            for path, content in files.values():
                path.parent.mkdir(parents=True)
                path.write_text(content)

            previous_targets = {
                home / ".public" / "public_file": ("public\n", 0o600),
                home / ".private" / "secret": ("private\n", 0o600),
                home / "bin" / "tool": ("#!/bin/sh\n", 0o700),
            }
            for path, (content, mode) in previous_targets.items():
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(content)
                path.chmod(mode)
            for directory in (home / ".public", home / ".private", home / "bin"):
                directory.chmod(0o700)

            for name, source in sources.items():
                result = subprocess.run(
                    [
                        CHEZMOI,
                        "--source",
                        str(source),
                        "--destination",
                        str(home),
                        "--config",
                        str(config),
                        "--config-format",
                        "yaml",
                        "--cache",
                        str(root / f"cache-{name}"),
                        "--persistent-state",
                        str(root / f"state-{name}"),
                        "--refresh-externals=never",
                        "apply",
                        "--force",
                        "--exclude=externals,scripts",
                    ],
                    env=env,
                    capture_output=True,
                    text=True,
                    preexec_fn=lambda: os.umask(0o077),
                )
                self.assertEqual(result.returncode, 0, result.stderr)

            actual_modes = {
                "public file": stat.S_IMODE((home / ".public" / "public_file").stat().st_mode),
                "public directory": stat.S_IMODE((home / ".public").stat().st_mode),
                "private file": stat.S_IMODE((home / ".private" / "secret").stat().st_mode),
                "private directory": stat.S_IMODE((home / ".private").stat().st_mode),
                "executable": stat.S_IMODE((home / "bin" / "tool").stat().st_mode),
            }
            self.assertEqual(
                actual_modes,
                {
                    "public file": 0o644,
                    "public directory": 0o755,
                    "private file": 0o600,
                    "private directory": 0o700,
                    "executable": 0o755,
                },
            )


if __name__ == "__main__":
    unittest.main()
