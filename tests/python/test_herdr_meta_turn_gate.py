"""Tests for the Meta-only Claude Stop hook."""

import contextlib
import hashlib
import importlib.util
import io
import json
import os
import shutil
import subprocess
import tempfile
import time
import unittest
from datetime import datetime, timedelta, timezone
from pathlib import Path
from unittest import mock

REPO_ROOT = Path(__file__).resolve().parents[2]
HOOK = REPO_ROOT / "home" / "dot_claude" / "hooks" / "executable_herdr-meta-turn-gate.py"
QUEUE_SOURCE = (
    REPO_ROOT / "home" / "private_dot_local" / "private_bin" / "exact_common"
    / "executable_herdr-meta-patrol-queue"
)
GATE_MODULE_SPEC = importlib.util.spec_from_file_location("herdr_meta_turn_gate", HOOK)
assert GATE_MODULE_SPEC is not None and GATE_MODULE_SPEC.loader is not None
GATE_MODULE = importlib.util.module_from_spec(GATE_MODULE_SPEC)
GATE_MODULE_SPEC.loader.exec_module(GATE_MODULE)


@unittest.skipUnless(shutil.which("jq") and shutil.which("ps"), "requires jq and ps")
class HerdrMetaTurnGateTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="meta-turn-gate-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.state = self.root / "state"
        self.queue_state = self.root / "queue-state"
        self.registry = self.state / "herdr-worker-lifecycle" / "workers.tsv"
        self.registry.parent.mkdir(parents=True)
        self.registry.write_text("")
        self.task_tree_dir = self.root / ".local" / "state" / "inbox" / "task-tree"
        self.task_tree_dir.mkdir(parents=True)
        (self.queue_state / "waiters").mkdir(parents=True)
        (self.queue_state / "queue.jsonl").touch()
        self.queue = self.bin / "herdr-meta-patrol-queue"
        shutil.copyfile(QUEUE_SOURCE, self.queue)
        self.queue.chmod(0o755)
        self.agents_file = self.root / "agents.json"
        self.agents_file.write_text(json.dumps({
            "result": {"agents": [
                {
                    "name": "meta", "pane_id": "w1:p1", "tab_id": "w1:t1",
                    "terminal_id": "meta-terminal", "agent_status": "idle",
                },
                {
                    "name": "gate-worker", "pane_id": "w2:p2", "tab_id": "w2:t2",
                    "terminal_id": "worker-terminal", "agent_status": "idle",
                },
            ]},
        }))
        self.tabs_file = self.root / "tabs.json"
        self.tabs_file.write_text(json.dumps({
            "result": {"tabs": [
                {"tab_id": "w1:t1", "label": "Meta"},
                {"tab_id": "w2:t2", "label": "gate-worker"},
            ]},
        }))
        (self.bin / "herdr").write_text(
            "#!/bin/sh\n"
            "case \"$1 $2\" in\n"
            "  'agent list') cat \"$HOME/agents.json\" ;;\n"
            "  'tab list') cat \"$HOME/tabs.json\" ;;\n"
            "  *) exit 2 ;;\n"
            "esac\n"
        )
        (self.bin / "herdr").chmod(0o755)
        self.env = {
            **os.environ,
            "HOME": str(self.root),
            "XDG_STATE_HOME": str(self.state),
            "HERDR_META_PATROL_STATE_DIR": str(self.queue_state),
            "HERDR_META_PATROL_QUEUE_COMMAND": str(self.queue),
            "HERDR_META_PATROL_QUEUE_POLL": "0.02",
            "HERDR_ENV": "1",
            "HERDR_PANE_ID": "w1:p1",
            "PATH": f"{self.bin}{os.pathsep}{os.environ['PATH']}",
        }
        self.write_task_tree([])

    @staticmethod
    def utc_text(value=None):
        value = value or datetime.now(timezone.utc)
        return value.isoformat(timespec="seconds").replace("+00:00", "Z")

    def task_fixture(self, *, task_id="task-1", title="Review gate", status="queued",
                     updated_at=None, owner=None, pr=None, parent_id=None, warnings=None):
        return {
            "id": task_id, "title": title, "status": status,
            "updated_at": self.utc_text(updated_at), "owner": owner, "pr": pr,
            "parent_id": parent_id, "warnings": warnings or [],
        }

    def write_task_tree(self, tasks, *, session_id="session-under-test", **changes):
        document = {
            "schema": 1, "session_id": session_id,
            "saved_at": self.utc_text(), "tasks": tasks,
            **changes,
        }
        path = self.task_tree_dir / f"{session_id}.json"
        path.write_text(json.dumps(document))
        return path

    def run_hook(self, *, active=False, include_active=True, env=None,
                 session_id="session-under-test", include_task_export=True):
        if include_task_export and isinstance(session_id, str):
            path = self.task_tree_dir / f"{session_id}.json"
            if not path.exists():
                self.write_task_tree([], session_id=session_id)
        payload = {"hook_event_name": "Stop"}
        if include_active:
            payload["stop_hook_active"] = active
        if session_id is not None:
            payload["session_id"] = session_id
        try:
            return subprocess.run(
                ["python3", str(HOOK)], input=json.dumps(payload), text=True,
                capture_output=True, env={**self.env, **(env or {})}, check=False,
                timeout=5,
            )
        except subprocess.TimeoutExpired as error:
            self.fail(f"hook timed out: stdout={error.stdout!r}; stderr={error.stderr!r}")

    def run_hook_raw(self, payload, *, env=None):
        try:
            return subprocess.run(
                ["python3", str(HOOK)], input=payload, text=True,
                capture_output=True, env={**self.env, **(env or {})}, check=False,
                timeout=7,
            )
        except subprocess.TimeoutExpired as error:
            self.fail(f"hook timed out: stdout={error.stdout!r}; stderr={error.stderr!r}")

    def run_queue(self, *arguments):
        return subprocess.run(
            [str(self.queue), *arguments], env=self.env, text=True,
            capture_output=True, check=False,
        )

    def configure_queue_response(self, response):
        response_file = self.root / "strict-queue-response.json"
        response_file.write_text(json.dumps(response) + "\n")
        command = self.bin / "strict-queue"
        command.write_text('#!/bin/sh\ncat "$HOME/strict-queue-response.json"\n')
        command.chmod(0o755)
        return {"HERDR_META_PATROL_QUEUE_COMMAND": str(command)}

    def assert_blocked(self, result, text):
        self.assertEqual(result.returncode, 0, result.stderr)
        decision = json.loads(result.stdout)
        self.assertEqual(decision["decision"], "block")
        self.assertIn(text, decision["reason"])

    def waiter_marker(self, pid):
        return self.queue_state / "waiters" / f"w1:p1.{pid}.pid"

    def set_worker_status(self, status):
        agents = json.loads(self.agents_file.read_text())
        agents["result"]["agents"][1]["agent_status"] = status
        self.agents_file.write_text(json.dumps(agents))

    @property
    def gate_state_dir(self):
        primary = self.queue_state / "stop-gate"
        fallback = Path(self.env.get("TMPDIR", "/tmp")) / f"herdr-meta-turn-gate-{os.getuid()}"
        return fallback if primary.exists() and not primary.is_dir() else primary

    def start_waiter(self):
        process = subprocess.Popen(
            [str(self.queue), "wait", "--max-seconds", "60"], env=self.env,
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
        marker = self.waiter_marker(process.pid)

        def stop_process():
            if process.poll() is None:
                process.terminate()
                process.wait(timeout=2)

        self.addCleanup(stop_process)
        deadline = time.monotonic() + 2
        while not marker.exists() and time.monotonic() < deadline:
            time.sleep(0.01)
        self.assertTrue(marker.exists(), "queue helper did not register its waiter")
        self.assertEqual(marker.read_text().strip(), str(process.pid))
        return process, marker

    def test_unread_queue_blocks_with_read_and_ack_instructions(self):
        self.run_queue("add", "--from", "gate-test", "worker report")
        result = self.run_hook()
        self.assert_blocked(result, "herdr-meta-patrol-queue read")
        self.assertIn("ack", json.loads(result.stdout)["reason"])

    def test_missing_session_wait_blocks(self):
        self.assert_blocked(self.run_hook(), "herdr-meta-patrol-queue wait")

    def test_live_session_wait_allows_when_no_other_gate_is_pending(self):
        self.start_waiter()
        result = self.run_hook()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")

    def test_waiter_marker_is_removed_when_wait_exits(self):
        process, marker = self.start_waiter()
        process.terminate()
        process.wait(timeout=2)
        self.assertFalse(marker.exists())

    def test_concurrent_waiters_keep_independent_markers(self):
        first, first_marker = self.start_waiter()
        second, second_marker = self.start_waiter()

        first.terminate()
        first.wait(timeout=2)
        self.assertFalse(first_marker.exists())
        self.assertTrue(second_marker.exists())

        second.terminate()
        second.wait(timeout=2)
        self.assertFalse(second_marker.exists())

    def test_uncollected_settled_worker_blocks_until_registry_is_collected(self):
        self.start_waiter()
        row = "meta\tw1:p1\tmeta-terminal\tgate-task\tgate-worker\tworker-terminal\tw2:t2\tw2:p2\tstarted\n"
        self.registry.write_text(row)
        self.set_worker_status("done")

        self.assert_blocked(self.run_hook(), "gate-worker")

        self.registry.write_text(row.replace("\tstarted\n", "\tcollected\n"))
        result = self.run_hook()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")

    def test_working_worker_with_started_record_does_not_block(self):
        self.start_waiter()
        self.registry.write_text(
            "meta\tw1:p1\tmeta-terminal\tgate-task\tgate-worker\tworker-terminal\tw2:t2\tw2:p2\tstarted\n"
        )
        self.set_worker_status("working")

        result = self.run_hook()

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")

    def test_open_inbox_tasks_with_any_warning_block(self):
        self.start_waiter()
        statuses = ("queued", "working", "waits-on-other")
        warnings = (
            "owner-idle-15m", "owner-finished-task-open",
            "pr-merged-task-open", "status-conflict",
        )
        for status in statuses:
            for warning in warnings:
                with self.subTest(status=status, warning=warning):
                    self.write_task_tree([self.task_fixture(
                        status=status, warnings=[warning],
                    )])
                    result = self.run_hook()
                    self.assert_blocked(result, "task-1 'Review gate'")
                    reason = json.loads(result.stdout)["reason"]
                    self.assertIn(warning, reason)
                    self.assertIn("Inbox tasks tool", reason)

    def test_stale_working_inbox_task_blocks_and_recent_task_does_not(self):
        self.start_waiter()
        old = datetime.now(timezone.utc) - timedelta(minutes=61)
        self.write_task_tree([self.task_fixture(status="working", updated_at=old)])
        self.assert_blocked(self.run_hook(), "over 60 minutes")

        self.write_task_tree([self.task_fixture(status="working")])
        result = self.run_hook()
        self.assertEqual((result.returncode, result.stdout), (0, ""))

    def test_closed_inbox_tasks_do_not_block_for_warnings_or_age(self):
        self.start_waiter()
        old = datetime.now(timezone.utc) - timedelta(days=1)
        for status in ("done", "dropped"):
            with self.subTest(status=status):
                self.write_task_tree([self.task_fixture(
                    status=status, updated_at=old, warnings=["status-conflict"],
                    pr="not a validated URL",
                )])
                result = self.run_hook()
                self.assertEqual((result.returncode, result.stdout), (0, ""))

        self.write_task_tree([self.task_fixture(pr=42)])
        self.assert_blocked(self.run_hook(), "invalid pr")

    def test_inbox_export_parent_id_needs_no_tree_validation(self):
        self.start_waiter()
        tasks = [
            self.task_fixture(
                task_id=f"task-{index}", status="done",
                parent_id=(
                    "task-1" if index == 0 else
                    "task-0" if index == 1 else
                    "" if index == 2 else f"missing-parent-{index}"
                ),
            )
            for index in range(201)
        ]
        self.write_task_tree(tasks)
        result = self.run_hook()
        self.assertEqual((result.returncode, result.stdout), (0, ""))

    def test_missing_inbox_task_tree_export_blocks_after_identity(self):
        self.start_waiter()
        (self.task_tree_dir / "session-under-test.json").unlink()
        for attempt in range(4):
            with self.subTest(attempt=attempt + 1):
                result = self.run_hook(active=attempt > 0, include_task_export=False)
                if attempt < 3:
                    self.assert_blocked(result, "inbox task-tree export missing: update inbox")
                else:
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertIn("allowed this turn to end", json.loads(result.stdout)["systemMessage"])

    def test_malformed_inbox_task_tree_export_blocks(self):
        self.start_waiter()
        path = self.write_task_tree([self.task_fixture()])
        document = json.loads(path.read_text())
        document["tasks"][0]["warnings"] = ["unexpected-warning"]
        path.write_text(json.dumps(document))
        result = self.run_hook()
        self.assert_blocked(result, "gate cannot verify: Inbox task-tree export")
        self.assertIn("recovery:", json.loads(result.stdout)["reason"])

    def test_block_lists_each_open_task_by_id_title_and_reason(self):
        self.start_waiter()
        self.write_task_tree([
            self.task_fixture(task_id="stale-a", title="Review Alpha", status="working",
                              updated_at=datetime.now(timezone.utc) - timedelta(hours=2)),
            self.task_fixture(task_id="warn-b", title="Review Beta", warnings=["status-conflict"]),
        ])
        result = self.run_hook()
        self.assert_blocked(result, "stale-a")
        reason = json.loads(result.stdout)["reason"]
        self.assertIn("stale-a 'Review Alpha'", reason)
        self.assertIn("warn-b 'Review Beta'", reason)
        self.assertIn("over 60 minutes", reason)
        self.assertIn("status-conflict", reason)

    def test_done_worker_in_protected_tab_asks_user_instead_of_collect_command(self):
        self.start_waiter()
        self.registry.write_text(
            "meta\tw1:p1\tmeta-terminal\tgate-task\tgate-worker\tworker-terminal\tw2:t2\tw2:p2\tstarted\n"
        )
        self.set_worker_status("done")
        tabs = json.loads(self.tabs_file.read_text())
        tabs["result"]["tabs"][1]["label"] = "⛔ protected worker"
        self.tabs_file.write_text(json.dumps(tabs))

        result = self.run_hook()

        self.assert_blocked(result, "protected tab: ask the user")
        reason = json.loads(result.stdout)["reason"]
        self.assertIn("recovery: protected tab: ask the user.", reason)
        self.assertNotIn("herdr-worker-lifecycle.sh collect", reason)

    def test_lifecycle_registry_accepts_writer_row_shapes_and_launch_modes(self):
        self.start_waiter()
        writer_fields = [
            "meta", "w1:p1", "meta-terminal", "gate-task", "gate-worker",
            "worker-terminal", "w2:t2", "w2:p2", "started",
        ]
        cases = [
            ("legacy 9-field row", writer_fields),
            ("tab launch row", [*writer_fields, "tab"]),
            ("root-pane launch row", [*writer_fields, "root"]),
        ]

        for name, fields in cases:
            with self.subTest(row=name):
                self.registry.write_text("\t".join(fields) + "\n")
                self.assert_blocked(self.run_hook(), "gate-worker")

    def test_lifecycle_registry_rejects_unrecognized_launch_mode(self):
        self.start_waiter()
        fields = [
            "meta", "w1:p1", "meta-terminal", "gate-task", "gate-worker",
            "worker-terminal", "w2:t2", "w2:p2", "started", "other",
        ]
        self.registry.write_text("\t".join(fields) + "\n")
        self.assert_blocked(self.run_hook(), "registry is unparsable")

    def test_unexpected_worker_status_blocks_for_reconciliation(self):
        self.start_waiter()
        row = "meta\tw1:p1\tmeta-terminal\tgate-task\tgate-worker\tworker-terminal\tw2:t2\tw2:p2\tstarted\n"
        self.registry.write_text(row)
        agents = json.loads(self.agents_file.read_text())
        agents["result"]["agents"][1]["agent_status"] = "unknown"
        self.agents_file.write_text(json.dumps(agents))

        self.assert_blocked(
            self.run_hook(), "gate cannot verify: worker 'gate-worker' has unexpected status 'unknown'"
        )

    def test_other_claude_session_is_not_gated(self):
        self.run_queue("add", "--from", "gate-test", "unread record")
        result = self.run_hook(env={"HERDR_PANE_ID": "w9:p9"})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")

    def test_ambiguous_pane_with_meta_and_other_agent_is_not_gated(self):
        self.run_queue("add", "--from", "gate-test", "unread record")
        agents = json.loads(self.agents_file.read_text())
        agents["result"]["agents"].append({
            "name": "other-agent", "pane_id": "w1:p1", "tab_id": "w9:t9",
            "terminal_id": "other-terminal", "agent_status": "working",
        })
        self.agents_file.write_text(json.dumps(agents))

        result = self.run_hook()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")

    def test_multiple_json_documents_in_herdr_output_do_not_prove_identity(self):
        herdr = self.bin / "herdr"
        herdr.write_text(
            "#!/bin/sh\n"
            "[ \"$1 $2\" = 'agent list' ] || exit 2\n"
            "cat \"$HOME/agents.json\"\n"
            "printf '{}\\n'\n"
        )
        herdr.chmod(0o755)

        result = self.run_hook()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")

    def test_multiple_json_documents_in_stop_payload_fail_closed(self):
        payload = json.dumps({
            "stop_hook_active": False,
            "session_id": "session-under-test",
        }) + "\n{}\n"
        result = self.run_hook_raw(payload)
        self.assert_blocked(result, "gate cannot verify: the Claude Stop payload is not a JSON object")

    def test_multiple_json_documents_in_queue_response_fail_closed(self):
        env = self.configure_queue_response(
            {"malformed_line_count": 0, "unread_record_count": 0}
        )
        response = self.root / "strict-queue-response.json"
        response.write_text(response.read_text() + "{}\n")

        result = self.run_hook(env=env)
        self.assert_blocked(
            result,
            "gate cannot verify: the patrol queue returned an unparsable or malformed strict response",
        )

    def test_multiple_json_documents_in_retry_state_fail_closed(self):
        self.start_waiter()
        self.run_queue("add", "--from", "gate-test", "unread record")
        self.assert_blocked(self.run_hook(), "unread records")
        state_file = self.gate_state_dir / f"{self.session_key()}.json"
        state_file.write_text(state_file.read_text() + "{}\n")

        self.assert_blocked(
            self.run_hook(active=True), "gate cannot verify: retry state"
        )

    def test_unique_meta_pane_without_terminal_id_blocks_for_reconciliation(self):
        agents = json.loads(self.agents_file.read_text())
        del agents["result"]["agents"][0]["terminal_id"]
        self.agents_file.write_text(json.dumps(agents))

        self.assert_blocked(
            self.run_hook(), "Meta has a missing, empty, or non-string terminal_id"
        )

    def test_non_string_meta_terminal_id_blocks_worker_reconciliation(self):
        self.start_waiter()
        row = "meta\tw1:p1\tmeta-terminal\tgate-task\tgate-worker\tworker-terminal\tw2:t2\tw2:p2\tstarted\n"
        self.registry.write_text(row)

        agents = json.loads(self.agents_file.read_text())
        agents["result"]["agents"][0]["terminal_id"] = 123
        self.agents_file.write_text(json.dumps(agents))
        self.assert_blocked(
            self.run_hook(), "Meta has a missing, empty, or non-string terminal_id"
        )

        agents["result"]["agents"][0]["terminal_id"] = {"unexpected": "object"}
        self.agents_file.write_text(json.dumps(agents))
        self.assert_blocked(
            self.run_hook(), "Meta has a missing, empty, or non-string terminal_id"
        )

    def test_missing_malformed_and_dangling_registry_paths_fail_closed(self):
        self.start_waiter()
        self.registry.unlink()
        self.registry.parent.rmdir()
        self.registry.parent.write_text("not a directory")

        self.assert_blocked(self.run_hook(), "gate cannot verify: the worker lifecycle registry directory")

        self.registry.parent.unlink()
        self.assert_blocked(self.run_hook(), "gate cannot verify: the worker lifecycle registry directory")

        self.state.rmdir()
        self.state.symlink_to(self.root / "missing-registry-parent")
        self.assert_blocked(self.run_hook(), "gate cannot verify: the worker lifecycle parent")

    def test_stop_hook_active_attempt_still_blocks(self):
        self.run_queue("add", "--from", "gate-test", "unread record")
        self.assert_blocked(self.run_hook(), "unread records")
        self.assert_blocked(self.run_hook(active=True), "unread records")

    def test_missing_or_non_boolean_stop_hook_active_fails_closed(self):
        self.assert_blocked(
            self.run_hook(include_active=False),
            "gate cannot verify: stop_hook_active is missing or invalid",
        )
        self.assert_blocked(
            self.run_hook(active="false"),
            "gate cannot verify: stop_hook_active is missing or invalid",
        )

    def test_fourth_same_reason_attempt_allows_and_audits_warning(self):
        self.run_queue("add", "--from", "gate-test", "unread record")
        for attempt in range(3):
            self.assert_blocked(
                self.run_hook(active=attempt > 0), "unread records"
            )

        result = self.run_hook(active=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        output = json.loads(result.stdout)
        self.assertIn("systemMessage", output)
        self.assertIn("three times", output["systemMessage"])
        audit = self.gate_state_dir / "audit.log"
        audit_record = json.loads(audit.read_text().splitlines()[-1])
        self.assertEqual(audit_record["consecutive_blocks"], 3)
        self.assertEqual(audit_record["action"], "allow")

    def test_fresh_stop_attempt_starts_a_new_retry_count(self):
        self.run_queue("add", "--from", "gate-test", "unread record")
        self.assert_blocked(self.run_hook(), "unread records")
        self.assert_blocked(self.run_hook(active=True), "unread records")

        self.assert_blocked(self.run_hook(active=False), "unread records")
        self.assert_blocked(self.run_hook(active=True), "unread records")
        self.assert_blocked(self.run_hook(active=True), "unread records")
        result = self.run_hook(active=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("systemMessage", json.loads(result.stdout))

    def test_changed_reason_starts_a_new_retry_count(self):
        self.run_queue("add", "--from", "gate-test", "unread record")
        self.assert_blocked(self.run_hook(), "unread records")
        state_file = self.gate_state_dir / f"{self.session_key()}.json"
        previous = json.loads(state_file.read_text())

        self.run_queue("ack", "1")
        self.assert_blocked(self.run_hook(active=True), "no queue waiter marker exists")
        current = json.loads(state_file.read_text())
        self.assertEqual(current["consecutive_blocks"], 1)
        self.assertRegex(current["reason_fingerprint"], r"^[0-9]+$")
        self.assertNotEqual(current["reason_fingerprint"], previous["reason_fingerprint"])

    def test_missing_session_id_uses_a_stable_pane_scoped_retry_key(self):
        self.run_queue("add", "--from", "gate-test", "unread record")
        self.assert_blocked(
            self.run_hook(session_id=None), "gate cannot verify: session_id is missing"
        )
        self.assert_blocked(
            self.run_hook(session_id="../invalid"), "gate cannot verify: session_id has an invalid format"
        )
        self.assert_blocked(
            self.run_hook(session_id=123), "gate cannot verify: session_id is missing"
        )
        self.assert_blocked(
            self.run_hook(session_id=True), "gate cannot verify: session_id is missing"
        )
        state_files = list(self.gate_state_dir.glob("*.json"))
        self.assertEqual(len(state_files), 1)
        self.assertTrue(state_files[0].name.startswith("pane-"))
        self.assert_blocked(self.run_hook(active=True, session_id="../invalid"), "unread records")

    def test_non_string_session_ids_are_isolated_between_meta_panes(self):
        self.run_queue("add", "--from", "gate-test", "unread record")
        self.assert_blocked(self.run_hook(session_id=123), "unread records")

        agents = json.loads(self.agents_file.read_text())
        agents["result"]["agents"][0]["pane_id"] = "w9:p9"
        self.agents_file.write_text(json.dumps(agents))
        self.assert_blocked(
            self.run_hook(active=False, session_id=123, env={"HERDR_PANE_ID": "w9:p9"}),
            "gate cannot verify: session_id is missing",
        )

        state_files = list(self.gate_state_dir.glob("*.json"))
        self.assertEqual(len(state_files), 2)
        self.assertEqual(
            [json.loads(path.read_text())["consecutive_blocks"] for path in state_files],
            [1, 1],
        )

    def test_retry_counts_are_scoped_to_each_session(self):
        self.run_queue("add", "--from", "gate-test", "unread record")
        self.assert_blocked(self.run_hook(session_id="first-session"), "unread records")
        self.assert_blocked(self.run_hook(session_id="second-session"), "unread records")
        state_files = list(self.gate_state_dir.glob("*.json"))
        self.assertEqual(len(state_files), 2)
        self.assertEqual(
            [json.loads(path.read_text())["consecutive_blocks"] for path in state_files],
            [1, 1],
        )

    def test_retry_counts_are_isolated_for_legacy_checksum_collision_ids(self):
        self.start_waiter()
        self.run_queue("add", "--from", "gate-test", "unread record")
        first_session = "session-49KCsYe3oaQD"
        second_session = "session-GrHzgYWuiIHw"
        self.assertEqual(
            self.legacy_session_key(first_session), self.legacy_session_key(second_session)
        )

        self.assert_blocked(self.run_hook(session_id=first_session), "unread records")
        self.assert_blocked(
            self.run_hook(active=True, session_id=first_session), "unread records"
        )
        first_state = self.gate_state_dir / f"{self.session_key(first_session)}.json"
        self.assertEqual(json.loads(first_state.read_text())["consecutive_blocks"], 2)

        self.assert_blocked(self.run_hook(session_id=second_session), "unread records")
        second_state = self.gate_state_dir / f"{self.session_key(second_session)}.json"
        self.assertNotEqual(first_state, second_state)
        self.assertEqual(json.loads(first_state.read_text())["consecutive_blocks"], 2)
        self.assertEqual(json.loads(second_state.read_text())["consecutive_blocks"], 1)

    def test_retry_key_generation_uses_python_standard_library(self):
        for name in ("shasum", "sha256sum"):
            command = self.bin / name
            command.write_text("#!/bin/sh\nexit 1\n")
            command.chmod(0o755)

        result = self.run_hook()
        self.assert_blocked(result, "no queue waiter marker exists")
        state_file = self.gate_state_dir / f"{self.session_key()}.json"
        self.assertTrue(state_file.is_file())
        self.assertRegex(
            json.loads(state_file.read_text())["reason_fingerprint"], r"^[0-9]+$"
        )

    def test_unwritable_retry_state_allows_with_visible_warning(self):
        self.run_queue("add", "--from", "gate-test", "unread record")
        (self.queue_state / "stop-gate").write_text("not a directory")
        temporary_dir = self.root / "tmp-is-a-file"
        temporary_dir.write_text("not a directory")

        result = self.run_hook(env={"TMPDIR": str(temporary_dir)})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("retry state write failed:", json.loads(result.stdout)["systemMessage"])

    def test_malformed_retry_state_fails_closed_with_recovery_guidance(self):
        self.run_queue("add", "--from", "gate-test", "unread record")
        self.assert_blocked(self.run_hook(), "unread records")
        state_file = self.gate_state_dir / f"{self.session_key()}.json"
        state_file.write_text("not-json\n")

        result = self.run_hook(active=True)
        self.assert_blocked(result, "gate cannot verify: retry state")
        self.assertIn("recovery:", json.loads(result.stdout)["reason"])

    def test_clean_active_retry_requires_valid_retry_state(self):
        self.start_waiter()
        self.assert_blocked(
            self.run_hook(active=True), "gate cannot verify: retry state is missing"
        )

        state_file = self.gate_state_dir / f"{self.session_key()}.json"
        state_file.write_text("not-json\n")
        self.assert_blocked(
            self.run_hook(active=True), "gate cannot verify: retry state"
        )

    def test_retry_state_requires_exact_schema(self):
        self.start_waiter()
        cases = [
            ("reason fingerprint missing", "reason_fingerprint", "missing", None),
            ("reason fingerprint empty", "reason_fingerprint", "value", ""),
            ("reason fingerprint wrong type", "reason_fingerprint", "value", 123),
            ("block count missing", "consecutive_blocks", "missing", None),
            ("block count empty", "consecutive_blocks", "value", None),
            ("block count wrong type", "consecutive_blocks", "value", "1"),
            ("block count above maximum", "consecutive_blocks", "value", 4),
            ("extra field", "unexpected", "value", True),
        ]
        for index, (name, field, action, value) in enumerate(cases):
            with self.subTest(schema_case=name):
                session_id = f"retry-schema-{index}"
                state = {"reason_fingerprint": "123456", "consecutive_blocks": 1}
                if action == "missing":
                    del state[field]
                else:
                    state[field] = value
                state_file = self.gate_state_dir / f"{self.session_key(session_id)}.json"
                state_file.parent.mkdir(parents=True, exist_ok=True)
                state_file.write_text(json.dumps(state) + "\n")

                result = self.run_hook(active=True, session_id=session_id)
                self.assert_blocked(result, "gate cannot verify: retry state")
                self.assertIn("recovery:", json.loads(result.stdout)["reason"])

    def test_queue_envelope_requires_exact_schema(self):
        self.start_waiter()
        cases = [
            ("malformed count missing", "malformed_line_count", "missing", None),
            ("malformed count empty", "malformed_line_count", "value", None),
            ("malformed count wrong type", "malformed_line_count", "value", "0"),
            ("unread count missing", "unread_record_count", "missing", None),
            ("unread count empty", "unread_record_count", "value", None),
            ("unread count wrong type", "unread_record_count", "value", "0"),
            ("extra field", "unexpected", "value", True),
        ]
        for index, (name, field, action, value) in enumerate(cases):
            with self.subTest(schema_case=name):
                response = {"malformed_line_count": 0, "unread_record_count": 0}
                if action == "missing":
                    del response[field]
                else:
                    response[field] = value
                env = self.configure_queue_response(response)

                result = self.run_hook(session_id=f"queue-schema-{index}", env=env)
                self.assert_blocked(
                    result, "gate cannot verify: the patrol queue returned an unparsable or malformed strict response"
                )
                self.assertIn("recovery:", json.loads(result.stdout)["reason"])

    def test_strict_queue_rejects_unverifiable_queue_and_ack_inputs(self):
        queue_path = self.queue_state / "queue.jsonl"
        ack_path = self.queue_state / "queue.ack"
        target = self.root / "queue-target"

        def reset_path(path):
            if path.is_symlink() or path.is_file():
                path.unlink()
            elif path.is_dir():
                path.rmdir()

        cases = [
            ("missing queue", "queue", "missing", "queue.jsonl is missing"),
            ("directory queue", "queue", "directory", "queue.jsonl is not a regular file"),
            ("queue symlink", "queue", "symlink", "queue.jsonl is a symbolic link"),
            ("dangling queue symlink", "queue", "dangling", "queue.jsonl is a symbolic link"),
            ("empty ack", "ack", "empty", "queue.ack is not a non-negative integer"),
            ("negative ack", "ack", "negative", "queue.ack is not a non-negative integer"),
            ("nonnumeric ack", "ack", "nonnumeric", "queue.ack is not a non-negative integer"),
            ("multiline ack", "ack", "multiline", "queue.ack must contain exactly one integer line"),
            ("directory ack", "ack", "directory", "queue.ack is not a regular file"),
            ("ack symlink", "ack", "symlink", "queue.ack is a symbolic link"),
            ("dangling ack symlink", "ack", "dangling", "queue.ack is a symbolic link"),
        ]

        for name, kind, value, diagnostic in cases:
            with self.subTest(input=name):
                reset_path(queue_path)
                reset_path(ack_path)
                target.unlink(missing_ok=True)
                path = queue_path if kind == "queue" else ack_path
                if kind == "ack":
                    queue_path.touch()
                if value == "missing":
                    path.unlink(missing_ok=True)
                elif value == "directory":
                    path.mkdir()
                elif value == "symlink":
                    target.write_text("0\n")
                    path.symlink_to(target)
                elif value == "dangling":
                    path.symlink_to(self.root / "absent-target")
                elif value == "empty":
                    path.write_text("")
                elif value == "negative":
                    path.write_text("-1\n")
                elif value == "nonnumeric":
                    path.write_text("invalid\n")
                elif value == "multiline":
                    path.write_text("0\n\n")

                result = self.run_queue("read", "--strict")
                self.assertNotEqual(result.returncode, 0, result.stdout)
                self.assertIn(f"queue unverifiable: {diagnostic}", result.stderr)

        reset_path(queue_path)
        reset_path(ack_path)
        queue_path.touch()
        self.assertEqual(self.run_queue("read", "--strict").returncode, 0)
        ack_path.write_text("0002\n")
        valid_ack = self.run_queue("read", "--strict")
        self.assertEqual(valid_ack.returncode, 0, valid_ack.stderr)

    def test_invalid_meta_pane_id_fails_closed_before_waiter_lookup(self):
        invalid_pane_id = "w1:p1/../../*"
        agents = json.loads(self.agents_file.read_text())
        agents["result"]["agents"][0]["pane_id"] = invalid_pane_id
        self.agents_file.write_text(json.dumps(agents))
        self.assert_blocked(
            self.run_hook(env={"HERDR_PANE_ID": invalid_pane_id}),
            "gate cannot verify: the Meta pane ID has an invalid format",
        )

    def test_retry_fingerprint_is_numeric(self):
        self.assert_blocked(self.run_hook(), "no queue waiter marker exists")
        state_file = self.gate_state_dir / f"{self.session_key()}.json"
        self.assertRegex(
            json.loads(state_file.read_text())["reason_fingerprint"], r"^[0-9]+$"
        )

    def test_retry_state_uses_temporary_fallback_when_primary_is_unavailable(self):
        self.run_queue("add", "--from", "gate-test", "unread record")
        (self.queue_state / "stop-gate").write_text("not a directory")
        temporary_dir = self.root / "tmp"
        temporary_dir.mkdir()
        expected_state_dir = temporary_dir / f"herdr-meta-turn-gate-{os.getuid()}"

        self.assert_blocked(
            self.run_hook(env={"TMPDIR": str(temporary_dir)}), "unread records"
        )
        self.assertTrue((expected_state_dir / f"{self.session_key()}.json").is_file())
        self.assert_blocked(
            self.run_hook(active=True, env={"TMPDIR": str(temporary_dir)}),
            "unread records",
        )

    def test_retry_state_write_failure_uses_temporary_fallback(self):
        self.run_queue("add", "--from", "gate-test", "unread record")
        temporary_dir = self.root / "tmp"
        temporary_dir.mkdir()
        fallback_state_dir = temporary_dir / f"herdr-meta-turn-gate-{os.getuid()}"
        marker = self.root / "replace-failed-once"
        sitecustomize = self.root / "sitecustomize.py"
        sitecustomize.write_text(
            "import os\n"
            f"marker = {str(marker)!r}\n"
            "replace = os.replace\n"
            "def fail_primary_once(source, destination):\n"
            "    if '/stop-gate/' in str(destination) and not os.path.exists(marker):\n"
            "        open(marker, 'w').close()\n"
            "        raise OSError('simulated primary state rename failure')\n"
            "    return replace(source, destination)\n"
            "os.replace = fail_primary_once\n"
        )

        self.assert_blocked(
            self.run_hook(env={
                "TMPDIR": str(temporary_dir),
                "PYTHONPATH": str(self.root),
            }), "unread records"
        )
        self.assertTrue(marker.exists())
        state_file = fallback_state_dir / f"{self.session_key()}.json"
        self.assertTrue(state_file.exists(), state_file)
        self.assertEqual(json.loads(state_file.read_text())["consecutive_blocks"], 1)
        self.assert_blocked(
            self.run_hook(active=True, env={
                "TMPDIR": str(temporary_dir),
                "PYTHONPATH": str(self.root),
            }),
            "unread records",
        )
        self.assertEqual(json.loads(state_file.read_text())["consecutive_blocks"], 2)

    def test_fourth_attempt_warning_survives_audit_log_failure(self):
        self.run_queue("add", "--from", "gate-test", "unread record")
        (self.gate_state_dir / "audit.log").mkdir(parents=True)
        for attempt in range(3):
            self.assert_blocked(self.run_hook(active=attempt > 0), "unread records")

        result = self.run_hook(active=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        message = json.loads(result.stdout)["systemMessage"]
        self.assertIn(
            f"audit log write failed: {self.gate_state_dir / 'audit.log'}",
            message,
        )

    def test_same_unhandled_gate_error_fourth_attempt_allows_with_warning(self):
        payloads = [
            {"hook_event_name": "Stop", "stop_hook_active": index > 0,
             "session_id": "same-gate-error"}
            for index in range(4)
        ]
        for index, payload in enumerate(payloads):
            with self.subTest(attempt=index + 1):
                output = io.StringIO()
                with (
                    mock.patch.dict(os.environ, self.env),
                    mock.patch.object(
                        GATE_MODULE, "identify_meta",
                        return_value=("meta-terminal", []),
                    ),
                    mock.patch.object(
                        GATE_MODULE, "evaluate_after_identity",
                        side_effect=GATE_MODULE.GateError("same injected gate error"),
                    ),
                    mock.patch.object(
                        GATE_MODULE.sys, "stdin", io.StringIO(json.dumps(payload))
                    ),
                    contextlib.redirect_stdout(output),
                ):
                    GATE_MODULE.main()
                result = json.loads(output.getvalue())
                if index < 3:
                    self.assertEqual(result["decision"], "block")
                    self.assertIn("same injected gate error", result["reason"])
                else:
                    self.assertIn("systemMessage", result)
                    self.assertIn("allowed this turn to end", result["systemMessage"])

    def session_key(self, value="session-under-test"):
        return hashlib.sha256(value.encode()).hexdigest()

    def legacy_session_key(self, value):
        result = subprocess.run(
            ["cksum"], input=value, text=True,
            capture_output=True, check=True,
        )
        checksum, length, *_ = result.stdout.split()
        return f"{checksum}-{length}"

    def test_queue_failure_blocks_for_retry_after_meta_is_identified(self):
        result = self.run_hook(env={
            "HERDR_META_PATROL_QUEUE_COMMAND": str(self.root / "missing-queue"),
        })
        self.assert_blocked(result, "gate cannot verify: queue unverifiable:")

    def test_malformed_queue_lines_are_reported_and_block_the_gate(self):
        self.start_waiter()
        self.run_queue("add", "--from", "gate-test", "valid record")
        with (self.queue_state / "queue.jsonl").open("a") as queue_file:
            queue_file.write("not-json\n")

        result = self.run_hook()
        self.assert_blocked(
            result,
            "gate cannot verify: queue unverifiable: queue.jsonl contains 1 malformed or invalid record(s)",
        )

    def test_check_errors_fail_closed_with_recovery_guidance(self):
        malformed_queue = self.bin / "malformed-queue"
        malformed_queue.write_text("#!/bin/sh\nprintf '%s\\n' 'not-json'\n")
        malformed_queue.chmod(0o755)
        waiter_dir = self.queue_state / "waiters"

        def no_change():
            return lambda: None

        def hide_waiter_dir():
            shutil.rmtree(waiter_dir)
            waiter_dir.write_text("not a directory")

            def restore():
                waiter_dir.unlink()
                waiter_dir.mkdir()

            return restore

        def hide_registry():
            self.registry.unlink()
            return lambda: self.registry.write_text("")

        def corrupt_registry():
            self.registry.write_text("malformed lifecycle row\\n")
            return lambda: self.registry.write_text("")

        cases = [
            (
                "queue command failure",
                no_change,
                {"HERDR_META_PATROL_QUEUE_COMMAND": str(self.root / "missing-queue")},
                "queue unverifiable:",
            ),
            (
                "malformed queue data",
                no_change,
                {"HERDR_META_PATROL_QUEUE_COMMAND": str(malformed_queue)},
                "patrol queue returned an unparsable",
            ),
            ("malformed waiter directory", hide_waiter_dir, {}, "queue waiter directory"),
            ("missing lifecycle registry", hide_registry, {}, "worker lifecycle registry"),
            ("malformed lifecycle registry", corrupt_registry, {}, "registry is unparsable"),
        ]

        for index, (name, prepare, env, expected) in enumerate(cases):
            with self.subTest(check=name):
                restore = prepare()
                try:
                    result = self.run_hook(session_id=f"check-error-{index}", env=env)
                    self.assert_blocked(result, "gate cannot verify:")
                    reason = json.loads(result.stdout)["reason"]
                    self.assertIn(expected, reason)
                    self.assertIn("recovery:", reason)
                finally:
                    restore()

    def test_ack_and_rearmed_wait_allow_a_clean_stop(self):
        self.start_waiter()
        self.run_queue("add", "--from", "gate-test", "unread record")
        self.assert_blocked(self.run_hook(), "unread records")

        self.run_queue("ack", "1")
        self.start_waiter()
        result = self.run_hook()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")


if __name__ == "__main__":
    unittest.main()
