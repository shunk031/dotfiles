import json
import os, subprocess, tempfile
import unittest
from pathlib import Path

HOOK = Path(__file__).resolve().parents[2] / "home" / "dot_claude" / "hooks" / "executable_herdr-wait-background-guard.py"
REASON = "Run `herdr agent wait <worker>` alone with run_in_background: true; a backgrounded wait inside a foreground call never notifies you."
CASES = (("herdr agent wait w >/dev/null 2>&1 &", False, True), ("herdr agent wait w >/dev/null 2>&1 &", True, False), ("herdr agent wait w", False, False), ("herdr agent wait w; echo 'a & b'", False, False), ("herdr agent prompt meta report", False, True), ("herdr --machine local agent prompt meta report", False, True), ("herdr --machine=local agent prompt meta report", False, True), ("command herdr agent prompt meta report", False, True), ("env herdr agent prompt meta report", False, True), ("env -S 'herdr agent prompt meta report'", False, True), ("env -u FOO herdr agent prompt meta", False, True), ("env -C /tmp FOO=1 herdr agent prompt meta", False, True), ("env --unset=FOO --chdir=/tmp FOO=1 herdr agent prompt meta", False, True), ("env -P /bin herdr agent prompt meta", False, True), ("env -- FOO=1 herdr agent prompt meta", False, True), ("herdr agent prompt 'meta' report", False, True), ("herdr agent prompt wT:p42 report", False, True), ("herdr agent prompt wT:p42-empty report", False, True), ("true; herdr agent prompt meta report", False, True), ("herdr agent prompt worker report", False, False), ("command -v herdr agent prompt meta report", False, False), ("time herdr agent prompt meta report", False, False), ("f() { herdr agent prompt meta report; }", False, False), ("herdr() { :; }", False, False), ("printf '%s' 'herdr agent prompt meta'", False, False))


class WaitBackgroundGuardTests(unittest.TestCase):
    def test_requested_commands(self):
        state_dir = tempfile.TemporaryDirectory(); self.addCleanup(state_dir.cleanup); waiters = Path(state_dir.name) / "waiters"; waiters.mkdir(); (waiters / "wT:p42.123.pid").touch(); home_waiters = Path(state_dir.name) / ".local/state/herdr-meta-patrol/waiters"; home_waiters.mkdir(parents=True); (home_waiters / "wT:p42-empty.123.pid").touch()
        for command, background, denied in CASES:
            with self.subTest(command=command, background=background):
                payload = {"tool_name": "Bash", "tool_input": {"command": command, "run_in_background": background}}
                result = subprocess.run(["python3", str(HOOK)], input=json.dumps(payload), text=True, capture_output=True, env=dict(os.environ, HOME=state_dir.name, HERDR_META_PATROL_STATE_DIR="" if "wT:p42-empty" in command else state_dir.name), check=False)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(json.loads(result.stdout)["hookSpecificOutput"]["permissionDecisionReason"] if denied else result.stdout, "meta is reached via herdr-meta-patrol-queue add" if denied and "agent prompt" in command else REASON if denied else "")

    def test_invalid_input_fails_open(self):
        result = subprocess.run(["python3", str(HOOK)], input="invalid", text=True, capture_output=True, check=False)
        self.assertEqual((result.returncode, result.stdout, result.stderr), (0, "", ""))


if __name__ == "__main__":
    unittest.main()
