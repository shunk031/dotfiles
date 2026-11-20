import json
import subprocess
import unittest
from pathlib import Path

HOOK = Path(__file__).resolve().parents[2] / "home" / "dot_claude" / "hooks" / "executable_herdr-wait-background-guard.py"
REASON = "Run `herdr agent wait <worker>` alone with run_in_background: true; a backgrounded wait inside a foreground call never notifies you."
CASES = (("herdr agent wait w >/dev/null 2>&1 &", False, True), ("herdr agent wait w >/dev/null 2>&1 &", True, False),
         ("herdr agent wait w", False, False), ("a && herdr agent wait w", False, False),
         ("herdr agent wait w 2>&1", False, False), ("herdr agent wait w; echo \"a & b\"", False, False))


class WaitBackgroundGuardTests(unittest.TestCase):
    def test_requested_commands(self):
        for command, background, denied in CASES:
            with self.subTest(command=command, background=background):
                payload = {"tool_name": "Bash", "tool_input": {"command": command, "run_in_background": background}}
                result = subprocess.run(["python3", str(HOOK)], input=json.dumps(payload), text=True, capture_output=True, check=False)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(json.loads(result.stdout)["hookSpecificOutput"]["permissionDecisionReason"] if denied else result.stdout, REASON if denied else "")

    def test_invalid_input_fails_open(self):
        result = subprocess.run(["python3", str(HOOK)], input="invalid", text=True, capture_output=True, check=False)
        self.assertEqual((result.returncode, result.stdout, result.stderr), (0, "", ""))


if __name__ == "__main__":
    unittest.main()
