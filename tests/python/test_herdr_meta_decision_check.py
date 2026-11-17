import importlib.util
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

HOOK = Path(__file__).parents[2] / "home/dot_claude/hooks/executable_herdr-meta-decision-check.py"
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
                result = GATE.evaluate_event(payload, checker)
                output = result["hookSpecificOutput"]
                self.assertEqual(output["permissionDecision"], "deny")
                self.assertIn("standing decision", output["permissionDecisionReason"])

    def test_valid_proposal_is_allowed(self):
        checker = mock.Mock(return_value=ALLOW)
        payload = {"hook_event_name": "Stop", "last_assistant_message": "I recommend keeping the daily, hourly, and minute caps."}
        self.assertIsNone(GATE.evaluate_event(payload, checker))

    def test_checker_result_requires_exact_schema(self):
        cases = (("blank", {**ALLOW, "decision": ""}), ("whitespace", {**ALLOW, "reason": " \t"}),
                 ("missing", {"status": "ALLOW", "reason": "No conflict."}),
                 ("extra", {**ALLOW, "extra": "unexpected"}), ("wrong type", {**ALLOW, "status": None}))
        for label, response in cases:
            with self.subTest(label=label):
                self.assertEqual("UNKNOWN", GATE.normalize_result(response)["status"])
        self.assertEqual({}, GATE.unique_object([("status", "CONFLICT"), ("status", "ALLOW")]))

    def test_checker_timeout_becomes_unknown(self):
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

    def test_unknown_passes_and_logs_without_proposal_text(self):
        cases = (
            ("Stop", {"hook_event_name": "Stop", "last_assistant_message": "I recommend SECRET PROPOSAL TEXT."}),
            ("Inbox record", {"hook_event_name": "PreToolUse", "tool_name": "mcp__inbox__record", "tool_input": {"ask": "SECRET PROPOSAL TEXT"}}),
            ("Inbox record", {"hook_event_name": "PreToolUse", "tool_name": "mcp__inbox__record", "tool_input": {}}),
            ("Agent prompt", {"hook_event_name": "PreToolUse", "tool_name": "Bash", "tool_input": {"command": "herdr agent prompt SECRET PROPOSAL TEXT"}}),
        )
        with tempfile.TemporaryDirectory() as temporary, mock.patch.dict(GATE.os.environ, {"HOME": temporary}):
            for _, payload in cases:
                self.assertIsNone(GATE.evaluate_event(payload, mock.Mock(return_value=GATE.unknown("SECRET PROPOSAL TEXT"))))
            path = Path(temporary) / ".local/state/meta/decision-check.log"
            content = path.read_text(encoding="utf-8")
            records = [json.loads(line) for line in content.splitlines()]
        self.assertEqual([event for event, _ in cases], [record["event"] for record in records])
        for record in records:
            self.assertEqual({"time", "event", "decision", "reason"}, set(record))
            self.assertTrue(record["time"])
            self.assertEqual("UNKNOWN", record["decision"])
        self.assertNotIn("SECRET PROPOSAL TEXT", content)

    def test_conflict_is_blocked(self):
        checker = mock.Mock(return_value={**CONFLICT, "decision": "caps", "reason": "Reverses caps."})
        payload = {"hook_event_name": "Stop", "stop_hook_active": True, "last_assistant_message": "I recommend dropping the personal hour and minute caps."}
        result = GATE.evaluate_event(payload, checker)
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
            )
        self.assertEqual(checker.call_count, 1)


if __name__ == "__main__":
    unittest.main()
