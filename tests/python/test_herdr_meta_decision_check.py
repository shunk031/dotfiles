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
ROOT_SPEC = importlib.util.spec_from_file_location(
    "meta_root_naming", HOOK.with_name("executable_herdr-meta-root-naming-check.py")
)
ROOT_CHECK = importlib.util.module_from_spec(ROOT_SPEC)
ROOT_SPEC.loader.exec_module(ROOT_CHECK)
CONFLICT = {
    "status": "CONFLICT",
    "decision": "standing decision",
    "reason": "This reverses the recorded choice.",
}
ALLOW = {"status": "ALLOW", "decision": "none", "reason": "No conflict."}


class DecisionCheckTest(unittest.TestCase):
    def setUp(self):
        self.log_patch = mock.patch.object(GATE, "log_result")
        self.log_patch.start()

    def tearDown(self):
        self.log_patch.stop()

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
            with mock.patch.dict(
                GATE.os.environ,
                {
                    "HOME": str(home),
                    "HERDR_META_DECISION_CHECK_MODEL": "test-model",
                    "HERDR_META_DECISION_CHECK_EFFORT": "medium",
                },
            ), mock.patch.object(GATE.subprocess, "run", side_effect=subprocess.TimeoutExpired("codex", 30)):
                result = GATE.run_checker("Drop the hourly cap.")
        self.assertEqual(result["status"], "UNKNOWN")

    def test_checker_requires_model_and_effort_settings(self):
        with tempfile.TemporaryDirectory() as temporary:
            for settings in (
                {},
                {"HERDR_META_DECISION_CHECK_MODEL": "test-model"},
                {"HERDR_META_DECISION_CHECK_EFFORT": "medium"},
            ):
                with self.subTest(settings=settings), mock.patch.dict(
                    GATE.os.environ, {"HOME": temporary, **settings}, clear=True
                ), mock.patch.object(GATE.subprocess, "run") as run:
                    result = GATE.run_checker("Keep the caps.")
                self.assertEqual(result, GATE.unknown(GATE.MISSING_SETTINGS_REASON))
                run.assert_not_called()

    def test_missing_checker_settings_block_proposal(self):
        with tempfile.TemporaryDirectory() as temporary, mock.patch.dict(
            GATE.os.environ, {"HOME": temporary}, clear=True
        ), mock.patch.object(GATE.subprocess, "run") as run:
            result = GATE.evaluate_event(
                {"hook_event_name": "Stop", "last_assistant_message": "I recommend changing the setting."}
            )
        run.assert_not_called()
        self.assertEqual("block", result["decision"])
        self.assertIn("model or effort is not configured", result["reason"])

    def test_model_unknown_with_configuration_failure_reason_still_passes(self):
        checker = mock.Mock(return_value=GATE.unknown("Decision checker returned no result."))
        result = GATE.evaluate_event(
            {"hook_event_name": "Stop", "last_assistant_message": "I recommend changing the setting."},
            checker,
        )
        self.assertIsNone(result)

    def test_checker_command_failure_blocks_proposal(self):
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary)
            ledger = home / ".local" / "state" / "meta" / "standing-permissions.md"
            ledger.parent.mkdir(parents=True)
            ledger.write_text("Recorded decision: keep all personal caps.\n")
            failed = subprocess.CompletedProcess("codex", 2, "", "invalid model or effort")
            with mock.patch.dict(
                GATE.os.environ,
                {
                    "HOME": str(home),
                    "HERDR_META_DECISION_CHECK_MODEL": "unsupported-model",
                    "HERDR_META_DECISION_CHECK_EFFORT": "medium",
                },
            ), mock.patch.object(GATE.subprocess, "run", return_value=failed):
                result = GATE.evaluate_event(
                    {"hook_event_name": "Stop", "last_assistant_message": "I recommend changing the setting."}
                )
        self.assertEqual("block", result["decision"])
        self.assertIn("no result", result["reason"])

    def test_checker_uses_private_model_and_effort_settings(self):
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary)
            ledger = home / ".local" / "state" / "meta" / "standing-permissions.md"
            ledger.parent.mkdir(parents=True)
            ledger.write_text("Recorded decision: keep all personal caps.\n")
            completed = subprocess.CompletedProcess(
                "codex", 0, '{"status":"ALLOW","decision":"No conflict","reason":"No conflict."}', ""
            )
            with mock.patch.dict(
                GATE.os.environ,
                {
                    "HOME": str(home),
                    "HERDR_META_DECISION_CHECK_MODEL": "test-model",
                    "HERDR_META_DECISION_CHECK_EFFORT": "medium",
                },
            ), mock.patch.object(GATE.subprocess, "run", return_value=completed) as run:
                result = GATE.run_checker("Keep the caps.")
        command = run.call_args.args[0]
        self.assertEqual("ALLOW", result["status"])
        self.assertEqual("test-model", command[command.index("-m") + 1])
        self.assertIn("model_reasoning_effort=medium", command)

    def test_unknown_passes_and_logs_without_proposal_text(self):
        self.log_patch.stop()
        cases = (
            ("Stop", {"hook_event_name": "Stop", "last_assistant_message": "I recommend SECRET PROPOSAL TEXT."}),
            ("Inbox record", {"hook_event_name": "PreToolUse", "tool_name": "mcp__inbox__record", "tool_input": {"ask": "SECRET PROPOSAL TEXT"}}),
            ("Inbox record", {"hook_event_name": "PreToolUse", "tool_name": "mcp__inbox__record", "tool_input": {}}),
            ("Agent prompt", {"hook_event_name": "PreToolUse", "tool_name": "Bash", "tool_input": {"command": "herdr agent prompt SECRET PROPOSAL TEXT"}}),
        )
        with tempfile.TemporaryDirectory() as temporary, mock.patch.dict(GATE.os.environ, {"HOME": temporary}):
            for i, (_, payload) in enumerate(cases):
                result = {} if i == 1 else {**GATE.unknown("Decision checker returned invalid JSON." if i == 0 else "SECRET PROPOSAL TEXT and SECRET LEDGER CONTENT"), "decision": "SECRET LEDGER CONTENT"}
                self.assertIsNone(GATE.evaluate_event(payload, mock.Mock(return_value=result)))
            path = Path(temporary) / ".local/state/meta/decision-check.log"
            content = path.read_text(encoding="utf-8")
            records = [json.loads(line) for line in content.splitlines()]
        self.assertEqual([event for event, _ in cases], [record["event"] for record in records])
        self.assertEqual(["Decision checker returned invalid JSON.", "Invalid checker response.", "Inbox record has no proposal.", "Decision checker returned UNKNOWN."], [records[i]["reason"] for i in range(4)])
        for record in records:
            self.assertTrue(record["time"] and set(record) == {"time", "event", "status", "decision", "reason", "elapsed_seconds"} and (record["status"], record["decision"]) == ("UNKNOWN", "Unclear") and record["elapsed_seconds"] >= 0)
        self.assertTrue(all(secret not in content for secret in ("SECRET PROPOSAL TEXT", "SECRET LEDGER CONTENT")))

    def test_allow_and_conflict_logs_only_outcome_fields(self):
        self.log_patch.stop()
        with tempfile.TemporaryDirectory() as temporary, mock.patch.dict(GATE.os.environ, {"HOME": temporary}):
            for response in ({**ALLOW, "decision": "SECRET PROPOSAL TEXT"}, {**CONFLICT, "decision": "SECRET LEDGER CONTENT"}):
                payload = {"hook_event_name": "Stop", "last_assistant_message": "I recommend SECRET PROPOSAL TEXT."}
                GATE.evaluate_event(payload, mock.Mock(return_value=response))
            path = Path(temporary) / ".local/state/meta/decision-check.log"
            content = path.read_text(encoding="utf-8")
            records = [json.loads(line) for line in content.splitlines()]
        self.assertEqual([("ALLOW", "No conflicting decision"), ("CONFLICT", "Standing decision conflict")], [(record["status"], record["decision"]) for record in records])
        self.assertTrue(all(record["time"] and set(record) == {"time", "event", "status", "decision", "elapsed_seconds"} and record["elapsed_seconds"] >= 0 for record in records))
        self.assertTrue(all(secret not in content for secret in ("SECRET PROPOSAL TEXT", "SECRET LEDGER CONTENT")))

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

    def test_root_naming_blocks_and_fails_open(self):
        roots = {"Local": {"root-a"}, "remote": {"root-b"}}
        local = [{"name": "meta", "pane_id": "m:p1"}]
        env = {"HERDR_ENV": "1", "HERDR_PANE_ID": "m:p1"}
        with mock.patch.dict(ROOT_CHECK.os.environ, env), mock.patch.object(
            ROOT_CHECK, "root_registry", return_value=roots
        ):
            self.assertEqual((set(), {"root-a"}, {"root-a"}, {"root-a"}, set()), tuple(ROOT_CHECK.bare_names(text, {"root-a", "root-b"}) for text in ("`root-a` ``root-a`` /tmp/root-a/file /x/root-a.py ./root-a.md task担当の Orchestrator（root-a） project work担当の Orchestrator（root-b）", "``root-a```", "root-a.", "“root-a.”", "root-b.py")))
            self.assertEqual({"root-a", "root-b", "root-c", "root-d"}, ROOT_CHECK.bare_names("Question (root-c)\nOrchestrator for  (root-b)\n担当の Orchestrator（root-a）\nOrchestrator for build review. Question (root-d)", {"root-a", "root-b", "root-c", "root-d"}))
            payload = {"hook_event_name": "PreToolUse", "tool_name": "mcp__inbox__record",
                       "tool_input": {"detail": "See /tmp/log\nroot-b"}}
            result = ROOT_CHECK.evaluate(payload, lambda machine: local if machine == "Local" else [{"name": "root-b"}])
            self.assertEqual("deny", result["hookSpecificOutput"]["permissionDecision"])
            with mock.patch.object(ROOT_CHECK, "warning") as warn:
                self.assertIsNone(
                    ROOT_CHECK.evaluate(payload, lambda m: local if m == "Local" else None)
                )
                warn.assert_called_once()


if __name__ == "__main__":
    unittest.main()
