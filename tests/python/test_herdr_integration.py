"""Exercise official Herdr assets without touching a running Herdr session."""

import json
import os
from pathlib import Path
import re
import shlex
import shutil
import socket
import subprocess
import tempfile
import unittest


REPO_ROOT = Path(__file__).resolve().parents[2]
SYNC_SCRIPT = REPO_ROOT / "install" / "common" / "herdr.sh"
HERDR = shutil.which("herdr")


@unittest.skipUnless(HERDR, "requires the mise-pinned Herdr binary")
class HerdrIntegrationTest(unittest.TestCase):
    def setUp(self):
        # Short socket paths also work under macOS's Unix socket length limit.
        self.temporary = tempfile.TemporaryDirectory(prefix="herdr-test-", dir="/tmp")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.env = {
            key: value for key, value in os.environ.items()
            if not key.startswith("HERDR_")
            and key not in ("CODEX_HOME", "CLAUDE_CONFIG_DIR", "CODEX_THREAD_ID", "CURSOR_VERSION")
        }
        self.env["HOME"] = str(self.root)
        self.claude = self.root / ".claude"
        self.codex = self.root / ".codex"
        self.claude.mkdir()
        self.codex.mkdir()
        self.env["CLAUDE_CONFIG_DIR"] = str(self.claude)
        self.env["CODEX_HOME"] = str(self.codex)
        self.assets = {
            "claude": self.claude / "hooks" / "herdr-agent-state.sh",
            "codex": self.codex / "herdr-agent-state.sh",
        }

    def run_sync(self, check=True):
        return subprocess.run(
            [
                "bash", "-c",
                'source "$1"; shift; sync_herdr_integrations "$@"',
                "herdr-test", str(SYNC_SCRIPT), HERDR,
            ],
            env=self.env,
            text=True, capture_output=True, check=check,
        )

    def test_binary_matches_mise_pin(self):
        config = (REPO_ROOT / "home" / "dot_mise" / "config.toml").read_text()
        version = re.search(r'^herdr = "([^"]+)"', config, re.MULTILINE)[1]
        result = subprocess.run([HERDR, "--version"], env=self.env, check=True,
                                capture_output=True, text=True)
        self.assertEqual(result.stdout.strip(), f"herdr {version}")

    def test_sync_repairs_assets_without_editing_configs(self):
        source_settings = self.root / "settings-source.json"
        source_settings.write_text('{"hooks": {}, "sentinel": true}\n')
        settings = self.claude / "settings.json"
        settings.symlink_to(source_settings)
        codex_config = self.codex / "config.toml"
        configs = [source_settings, self.codex / "hooks.json"]
        configs[1].write_text('{"hooks": {}}\n')
        originals = {path: path.read_bytes() for path in configs}
        for asset in self.assets.values():
            asset.parent.mkdir(exist_ok=True)
            asset.write_text("# HERDR_INTEGRATION_VERSION=0\n")

        self.run_sync()
        installed = {agent: path.read_bytes() for agent, path in self.assets.items()}
        for agent, content in installed.items():
            self.assertIn(f"HERDR_INTEGRATION_ID={agent}".encode(), content)
            self.assertNotIn(b"HERDR_INTEGRATION_VERSION=0\n", content)
        self.assets["codex"].unlink()
        self.run_sync()
        self.run_sync()
        self.assertTrue(settings.is_symlink())
        self.assertEqual(originals, {path: path.read_bytes() for path in configs})
        self.assertFalse(codex_config.exists())
        self.assertEqual(installed, {agent: path.read_bytes() for agent, path in self.assets.items()})
        codex_config.write_text('[features]\nmemories = false\n')
        original_config = codex_config.read_bytes()
        self.assets["codex"].unlink()
        self.run_sync()
        self.assertEqual(codex_config.read_bytes(), original_config)
        status = subprocess.run(
            [HERDR, "integration", "status"], env=self.env,
            text=True, capture_output=True, check=True,
        ).stdout
        for agent in self.assets:
            self.assertRegex(status, rf"(?m)^{agent}: current\b")

    def test_source_directory_symlink_is_not_written_through(self):
        source = self.root / "source-hooks"
        source.mkdir()
        (self.claude / "hooks").symlink_to(source, target_is_directory=True)
        result = self.run_sync(check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("chezmoi apply", result.stderr)
        self.assertEqual(list(source.iterdir()), [])

    def test_installer_failure_restores_settings(self):
        hooks = self.codex / "hooks.json"
        config = self.codex / "config.toml"
        hooks.write_text('{"hooks": {}}\n')
        config.write_bytes(b"\xff")  # Herdr fails to read TOML after updating hooks.json.
        original_hooks = hooks.read_bytes()
        result = self.run_sync(check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(hooks.read_bytes(), original_hooks)
        self.assertEqual(config.read_bytes(), b"\xff")
        self.assertFalse((self.claude / "settings.json").exists())

    @unittest.skipUnless(shutil.which("chezmoi"), "requires chezmoi")
    def test_apply_migrates_source_symlink_without_changing_its_target(self):
        source = self.root / "source"
        source_hooks = source / "dot_config" / "claude" / "hooks"
        source_hooks.mkdir(parents=True)
        original = source_hooks / "herdr-agent-state.sh"
        original.write_text("old source-owned hook\n")
        enforce = source_hooks / "enforce-uv.sh"
        enforce.write_text("#!/bin/sh\n")
        (self.claude / "hooks").symlink_to(source_hooks, target_is_directory=True)
        shutil.copytree(REPO_ROOT / "home" / "dot_claude" / "hooks", source / "dot_claude" / "hooks")
        (source / ".chezmoiignore").write_text(".config\n")
        result = subprocess.run(
            [shutil.which("chezmoi"), "--source", str(source), "--destination", str(self.root),
             "--config", "/dev/null", "--config-format", "toml",
             "--persistent-state", str(self.root / "state.boltdb"),
             "apply", "--force"],
            env=self.env, capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((self.claude / "hooks").is_symlink())
        self.assertEqual((self.claude / "hooks" / "enforce-uv.sh").resolve(), enforce.resolve())
        self.run_sync()
        self.assertEqual(original.read_text(), "old source-owned hook\n")

    def test_mise_herdr_pin_has_no_postinstall(self):
        config = REPO_ROOT / "home" / "dot_mise" / "config.toml"
        self.assertNotRegex(
            config.read_text(), re.compile(r"^herdr = .*postinstall", re.MULTILINE)
        )

    def test_official_registration_matches_managed_contract(self):
        for agent in self.assets:
            subprocess.run(
                [HERDR, "integration", "install", agent], env=self.env,
                text=True, capture_output=True, check=True,
            )
        claude = json.loads((self.claude / "settings.json").read_text())["hooks"]
        managed = json.loads(
            (REPO_ROOT / "home" / "dot_config" / "claude" / "settings.json").read_text()
        )["hooks"]["SessionStart"]
        self.assertEqual(set(claude), {"SessionStart"})
        expected = json.loads(json.dumps(managed))
        expected[0]["hooks"][0]["command"] = claude["SessionStart"][0]["hooks"][0]["command"]
        self.assertEqual(claude["SessionStart"], expected)
        self.assertEqual(
            shlex.split(claude["SessionStart"][0]["hooks"][0]["command"]),
            ["bash", str(self.assets["claude"]), "session"],
        )
        codex = json.loads((self.codex / "hooks.json").read_text())["hooks"]
        command = codex["SessionStart"][0]["hooks"][0]["command"]
        self.assertEqual(codex, {"SessionStart": [{"hooks": [{
            "type": "command", "command": command, "timeout": 10,
        }]}]})
        self.assertEqual(shlex.split(command), ["bash", str(self.assets["codex"]), "session"])

    def test_startup_and_resume_report_session_identity(self):
        self.run_sync()
        for agent, asset in self.assets.items():
            for source in ("startup", "resume"):
                with self.subTest(agent=agent, source=source):
                    socket_path = self.root / f"{agent}-{source}.sock"
                    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as server:
                        server.bind(str(socket_path))
                        server.listen(1)
                        server.settimeout(5)
                        env = dict(self.env, HERDR_ENV="1", HERDR_PANE_ID="w1:p1",
                                   HERDR_SOCKET_PATH=str(socket_path))
                        payload = json.dumps({
                            "hook_event_name": "SessionStart", "source": source,
                            "session_id": "session-under-test", "transcript_path": "/tmp/transcript",
                        })
                        with subprocess.Popen(
                            ["bash", str(asset), "session"], env=env,
                            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                            text=True,
                        ) as process:
                            process.stdin.write(payload)
                            process.stdin.close()
                            with server.accept()[0] as client:
                                client.settimeout(5)
                                with client.makefile("rb") as incoming:
                                    request = json.loads(incoming.readline())
                                client.sendall(b'{"result": {}}\n')
                            self.assertEqual(process.wait(timeout=5), 0)
                        self.assertEqual(request["method"], "pane.report_agent_session")
                        self.assertEqual(request["params"]["agent_session_id"], "session-under-test")
                        self.assertEqual(request["params"]["session_start_source"], source)
                        self.assertEqual(request["params"]["source"], f"herdr:{agent}")


if __name__ == "__main__":
    unittest.main()
