import json
import os, subprocess, tempfile
import unittest
from pathlib import Path

HOOK = Path(__file__).resolve().parents[2] / "home" / "dot_claude" / "hooks" / "executable_herdr-wait-background-guard.py"
REASON = "Run `herdr agent wait <worker>` alone with run_in_background: true; a backgrounded wait inside a foreground call never notifies you."
CASES = (("herdr agent wait w >/dev/null 2>&1 &", False, True), ("herdr agent wait w >/dev/null 2>&1 &", True, False),
         ("herdr agent prompt meta report", False, True), ("herdr --machine local agent prompt meta report", False, True), ("herdr agent prompt 'meta' report", False, True), ("herdr agent prompt \"me\"ta report", False, True), ("herdr agent prompt $'meta' report", False, True), (r"herdr agent prompt m\eta report", False, True), (r"herdr agent prompt $'\x6deta' report", False, True), ("herdr agent prompt meta>/dev/null", False, True), ("herdr agent prompt worker report", False, False), ("herdr agent prompt \"meta\"-worker report", False, False), ("herdr agent prompt \"meta$(printf %s -worker)\" report", False, False), ("herdr --machine local agent prompt worker report", False, False), ("true;herdr agent prompt meta report", False, True), ("true;(herdr agent prompt meta report)", False, True), ("true &&\nherdr --machine local agent prompt meta report", False, True), ("printf ok # comment\nherdr agent prompt meta report", False, True), ("HERDR=1 herdr agent prompt meta report", False, True), ("env HERDR=1 herdr agent prompt meta report", False, True), ("env -- herdr agent prompt meta report", False, True), ("env -u UNUSED herdr --machine local agent prompt meta report", False, True), ("env -u A -u B herdr agent prompt meta report", False, True), ("/usr/bin/env herdr agent prompt meta report", False, True), ("printf '%s' \"$(herdr agent prompt 'meta' report)\"", False, True), ("printf '%s' \"$(\nherdr --machine local agent prompt meta report\n)\"", False, True), ("printf '%s' \"$(printf ')'; herdr agent prompt meta report)\"", False, True), ("printf '%s' `herdr agent prompt meta report`", False, True), ("printf '%s' `herdr --machine local agent prompt meta report`", False, True), ("printf '%s' '$(herdr agent prompt meta)'", False, False), ("printf '%s\\n' 'herdr agent prompt meta' # $(herdr agent prompt meta report)", False, False), ("printf '%s' example';herdr agent prompt meta report'", False, False), ("cat <<'EOF'\nherdr agent prompt meta report\nEOF", False, False), ("printf ';' herdr agent prompt meta", False, False), ("printf '%s' \"a\\\"b\"; herdr agent wait w &", False, True),
         ("herdr agent wait w", False, False), ("a && herdr agent wait w", False, False),
         ("herdr agent wait w 2>&1", False, False), ("herdr agent wait w; echo \"a & b\"", False, False))


class WaitBackgroundGuardTests(unittest.TestCase):
    def test_meta_pane_id_from_waiter_marker(self):
        with tempfile.TemporaryDirectory() as state_dir:
            waiters = Path(state_dir) / "waiters"; waiters.mkdir(); (waiters / "wT:p42.123.pid").touch()
            for command in ("herdr agent prompt wT:p42 report", "herdr --machine local agent prompt wT:p42 report"): payload = {"tool_name": "Bash", "tool_input": {"command": command}}; result = subprocess.run(["python3", str(HOOK)], input=json.dumps(payload), text=True, capture_output=True, env=dict(os.environ, HERDR_META_PATROL_STATE_DIR=state_dir), check=False); self.assertEqual(json.loads(result.stdout)["hookSpecificOutput"]["permissionDecisionReason"], "meta is reached via herdr-meta-patrol-queue add")

    def test_requested_commands(self):
        for command, background, denied in CASES:
            with self.subTest(command=command, background=background):
                payload = {"tool_name": "Bash", "tool_input": {"command": command, "run_in_background": background}}
                result = subprocess.run(["python3", str(HOOK)], input=json.dumps(payload), text=True, capture_output=True, env=dict(os.environ, HERDR_META_PATROL_STATE_DIR=str(HOOK)), check=False)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(json.loads(result.stdout)["hookSpecificOutput"]["permissionDecisionReason"] if denied else result.stdout, "meta is reached via herdr-meta-patrol-queue add" if denied and "agent prompt" in command else REASON if denied else "")

    def test_invalid_input_fails_open(self):
        result = subprocess.run(["python3", str(HOOK)], input="invalid", text=True, capture_output=True, check=False)
        self.assertEqual((result.returncode, result.stdout, result.stderr), (0, "", ""))


if __name__ == "__main__":
    unittest.main()
