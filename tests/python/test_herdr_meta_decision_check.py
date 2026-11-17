import importlib.util
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

REPO_ROOT = Path(__file__).parents[2]
HOOK = (
    REPO_ROOT
    / "home"
    / "dot_claude"
    / "hooks"
    / "executable_herdr-meta-decision-check.py"
)
SPEC = importlib.util.spec_from_file_location("meta_decision_check", HOOK)
assert SPEC is not None and SPEC.loader is not None
GATE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(GATE)
CONFLICT = {
    "status": "CONFLICT",
    "decision": "standing decision",
    "reason": "This reverses the recorded choice.",
}
ALLOW = {"status": "ALLOW", "decision": "none", "reason": "No conflict."}


class DecisionCheckTest(unittest.TestCase):
    def retry_unknown(self, reason, _payload):
        raise AssertionError(f"CONFLICT must not use UNKNOWN retries: {reason}")

    def test_replays_three_recorded_conflicts_before_agent_prompt(self):
        cases = (
            "Propose one Dockerfile per package again.",
            "Drop the personal hour and minute caps; keep only the daily cap.",
            "Start T6 before its prerequisite is complete.",
        )
        for text in cases:
            with self.subTest(text=text):
                checker = mock.Mock(return_value=CONFLICT)
                payload = {
                    "hook_event_name": "PreToolUse", "tool_name": "Bash",
                    "tool_input": {"command": f"(herdr-agent-prompt-if-input-empty.sh {text})"},
                }
                result = GATE.evaluate_event(payload, checker, self.retry_unknown)
                output = result["hookSpecificOutput"]
                self.assertEqual(output["permissionDecision"], "deny")
                self.assertIn("standing decision", output["permissionDecisionReason"])

    def test_valid_proposal_is_allowed(self):
        checker = mock.Mock(return_value=ALLOW)
        payload = {"hook_event_name": "Stop", "last_assistant_message": "I recommend keeping the daily, hourly, and minute caps."}
        self.assertIsNone(GATE.evaluate_event(payload, checker, self.retry_unknown))
        malformed = (
            {**ALLOW, "decision": ""}, {**ALLOW, "decision": " "},
            {"status": "ALLOW", "reason": "missing decision"}, {**ALLOW, "extra": "unexpected"},
            {**ALLOW, "decision": None}, {**ALLOW, "status": None}, {**ALLOW, "reason": None},
        )
        for response in malformed:
            self.assertEqual("UNKNOWN", GATE.normalize_result(response)["status"])
        duplicate = [("status", "CONFLICT"), ("status", "ALLOW")]
        self.assertEqual(GATE.unique_object(duplicate), {})
        retry = mock.Mock()
        checker.return_value = GATE.unknown("Timed out.")
        GATE.evaluate_event(payload, checker, retry)
        retry.assert_called_once()

    def test_checker_timeout_becomes_unknown_and_denies_pretool(self):
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary)
            ledger = home / ".local" / "state" / "meta" / "standing-permissions.md"
            ledger.parent.mkdir(parents=True)
            ledger.write_text("Recorded decision: keep all personal caps.\n")
            with mock.patch.dict(GATE.os.environ, {"HOME": str(home)}), mock.patch.object(
                GATE.subprocess, "run", side_effect=subprocess.TimeoutExpired("codex", 30)
            ):
                result = GATE.run_checker("Drop the hourly cap.")
        self.assertEqual(result["status"], "UNKNOWN")

    def test_unknown_is_denied_for_pretool(self):
        checker = mock.Mock(return_value=GATE.unknown("Timed out."))
        payload = {
            "hook_event_name": "PreToolUse", "tool_name": "mcp__inbox__record",
            "tool_input": {"kind": "question", "ask": "Drop the hour cap?"},
        }
        result = GATE.evaluate_event(payload, checker, self.retry_unknown)
        self.assertEqual(result["hookSpecificOutput"]["permissionDecision"], "deny")

    def test_conflict_never_uses_unknown_retry_allowance(self):
        checker = mock.Mock(return_value={**CONFLICT, "decision": "caps", "reason": "Reverses caps."})
        payload = {
            "hook_event_name": "Stop",
            "stop_hook_active": True,
            "last_assistant_message": "I recommend dropping the personal hour and minute caps.",
        }
        result = GATE.evaluate_event(payload, checker, self.retry_unknown)
        self.assertEqual(result["decision"], "block")

    def test_checker_runs_only_for_action_or_choice_text(self):
        cases = (
            ("Any update?", False), ("We can proceed.", False),
            ("Let's continue.", False), ("Would you pick A or B?", True),
            ("I recommend A.", True), ("Options:\n- A\n- B", True),
            ("We could keep the caps, or drop them.", False),
        )
        self.assertTrue(all(GATE.stop_proposes(text) == expected for text, expected in cases))
        checker = mock.Mock(return_value=ALLOW)
        for text in ("Facts.", "I recommend the other option."):
            GATE.evaluate_event(
                {"hook_event_name": "Stop", "last_assistant_message": text},
                checker,
                self.retry_unknown,
            )
        self.assertEqual(checker.call_count, 1)


if __name__ == "__main__":
    unittest.main()
