import json
import os, subprocess, tempfile
import unittest
from pathlib import Path

HOOK = Path(__file__).resolve().parents[2] / "home" / "dot_claude" / "hooks" / "executable_herdr-wait-background-guard.py"
REASON = "Run `herdr agent wait <worker>` alone with run_in_background: true; a backgrounded wait inside a foreground call never notifies you."
CASES = (("herdr agent wait w >/dev/null 2>&1 &", False, True), ("herdr agent wait w >/dev/null 2>&1 &", True, False), ("herdr agent wait w", False, False), ("herdr agent wait w; echo 'a & b'", False, False), ("herdr agent prompt meta report", False, True), ("herdr --machine local agent prompt meta report", False, True), ("herdr --machine=local agent prompt meta report", False, True), ("command herdr agent prompt meta report", False, True), ("env herdr agent prompt meta report", False, True), ("env -S 'herdr agent prompt meta report'", False, True), ("env --split-string='herdr agent prompt meta report'", False, True), ("env -u FOO herdr agent prompt meta", False, True), ("env -C /tmp FOO=1 herdr agent prompt meta", False, True), ("env -S 'herdr --machine local agent -v prompt wT:p42 report'", False, True), ("env -S 'ls herdr agent prompt meta'", False, True), ("env FOO=1 ls", False, False), ("env --unset=FOO --chdir=/tmp FOO=1 herdr agent prompt meta", False, True), ("env -P /bin herdr agent prompt meta", False, True), ("env -- FOO=1 herdr agent prompt meta", False, True), ("herdr agent prompt 'meta' report", False, True), ("herdr agent prompt wT:p42 report", False, True), ("true; herdr agent prompt meta report", False, True), ("herdr agent prompt worker report", False, False), ("command -v herdr", False, False), ("time herdr agent prompt meta report", False, False), ("f() { herdr agent prompt meta report; }", False, False), ("herdr() { :; }", False, False), ("printf '%s' 'herdr agent prompt meta'", False, False))


class WaitBackgroundGuardTests(unittest.TestCase):
    def test_requested_commands(self):
        state_dir = tempfile.TemporaryDirectory(); self.addCleanup(state_dir.cleanup); fake = Path(state_dir.name) / "herdr"; fake.write_text("#!/bin/sh\nprintf '%s\\n' '" + json.dumps({"result": {"agents": [{"name": "meta", "pane_id": "wT:p42"}]}}) + "'\n"); fake.chmod(0o755)
        for command, background, denied in CASES:
            with self.subTest(command=command, background=background):
                payload = {"tool_name": "Bash", "tool_input": {"command": command, "run_in_background": background}}
                result = subprocess.run(["python3", str(HOOK)], input=json.dumps(payload), text=True, capture_output=True, env=dict(os.environ, PATH=state_dir.name + os.pathsep + os.environ["PATH"], HOME=state_dir.name), check=False)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(json.loads(result.stdout)["hookSpecificOutput"]["permissionDecisionReason"] if denied else result.stdout, "meta is reached via herdr-meta-patrol-queue add" if denied and "agent" in command and "prompt" in command else REASON if denied else "")
        fake.write_text("#!/bin/sh\nsleep 2\n")
        for target, denied in (("meta", True), ("wT:p42", False)):
            result = subprocess.run(["python3", str(HOOK)], input=json.dumps({"tool_name": "Bash", "tool_input": {"command": f"herdr agent prompt {target}"}}), text=True, capture_output=True, env=dict(os.environ, PATH=state_dir.name + os.pathsep + os.environ["PATH"]), check=False)
            self.assertEqual(json.loads(result.stdout)["hookSpecificOutput"]["permissionDecisionReason"] if denied else result.stdout, "meta is reached via herdr-meta-patrol-queue add" if denied else "")

    def test_invalid_input_fails_open(self):
        result = subprocess.run(["python3", str(HOOK)], input="invalid", text=True, capture_output=True, check=False)
        self.assertEqual((result.returncode, result.stdout, result.stderr), (0, "", ""))


if __name__ == "__main__":
    unittest.main()
