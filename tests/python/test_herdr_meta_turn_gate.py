"""Tests for the Meta-only Claude Stop hook."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import unittest


REPO_ROOT = Path(__file__).resolve().parents[2]
HOOK = REPO_ROOT / "home" / "dot_claude" / "hooks" / "executable_herdr-meta-turn-gate.sh"
QUEUE_SOURCE = (
    REPO_ROOT / "home" / "private_dot_local" / "private_bin" / "exact_common"
    / "executable_herdr-meta-patrol-queue"
)


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
        (self.queue_state / "waiters").mkdir(parents=True)
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
        (self.bin / "herdr").write_text(
            "#!/bin/sh\n"
            "[ \"$1 $2\" = 'agent list' ] || exit 2\n"
            "cat \"$HOME/agents.json\"\n"
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

    def run_hook(self, *, active=False, include_active=True, env=None, session_id="session-under-test"):
        payload = {"hook_event_name": "Stop"}
        if include_active:
            payload["stop_hook_active"] = active
        if session_id is not None:
            payload["session_id"] = session_id
        try:
            return subprocess.run(
                ["bash", str(HOOK)], input=json.dumps(payload), text=True,
                capture_output=True, env={**self.env, **(env or {})}, check=False,
                timeout=5,
            )
        except subprocess.TimeoutExpired as error:
            self.fail(f"hook timed out: stdout={error.stdout!r}; stderr={error.stderr!r}")

    def run_queue(self, *arguments):
        return subprocess.run(
            [str(self.queue), *arguments], env=self.env, text=True,
            capture_output=True, check=False,
        )

    def assert_blocked(self, result, text):
        self.assertEqual(result.returncode, 0, result.stderr)
        decision = json.loads(result.stdout)
        self.assertEqual(decision["decision"], "block")
        self.assertIn(text, decision["reason"])

    def waiter_marker(self, pid):
        return self.queue_state / "waiters" / f"w1:p1.{pid}.pid"

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

        self.assert_blocked(self.run_hook(), "gate-worker")

        self.registry.write_text(row.replace("\tstarted\n", "\tcollected\n"))
        result = self.run_hook()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")

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

    def test_unique_meta_pane_without_terminal_id_blocks_for_reconciliation(self):
        agents = json.loads(self.agents_file.read_text())
        del agents["result"]["agents"][0]["terminal_id"]
        self.agents_file.write_text(json.dumps(agents))

        self.assert_blocked(self.run_hook(), "Meta has no terminal_id")

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

    def test_unwritable_retry_state_blocks_with_recovery_guidance(self):
        self.run_queue("add", "--from", "gate-test", "unread record")
        (self.queue_state / "stop-gate").write_text("not a directory")
        temporary_dir = self.root / "tmp-is-a-file"
        temporary_dir.write_text("not a directory")

        result = self.run_hook(env={"TMPDIR": str(temporary_dir)})
        self.assert_blocked(result, "gate cannot verify: retry state cannot be created")
        self.assertIn("recovery:", json.loads(result.stdout)["reason"])

    def test_malformed_retry_state_fails_closed_with_recovery_guidance(self):
        self.run_queue("add", "--from", "gate-test", "unread record")
        self.assert_blocked(self.run_hook(), "unread records")
        state_file = self.gate_state_dir / f"{self.session_key()}.json"
        state_file.write_text("not-json\n")

        result = self.run_hook(active=True)
        self.assert_blocked(result, "gate cannot verify: retry state")
        self.assertIn("recovery:", json.loads(result.stdout)["reason"])

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
        real_mv = shutil.which("mv")
        self.assertIsNotNone(real_mv)
        mv_wrapper = self.bin / "mv"
        mv_wrapper.write_text(
            "#!/bin/sh\n"
            'if [ ! -e "$HOME/mv-failed-once" ]; then\n'
            '  : > "$HOME/mv-failed-once"\n'
            "  exit 1\n"
            "fi\n"
            f"exec {real_mv} \"$@\"\n"
        )
        mv_wrapper.chmod(0o755)

        self.assert_blocked(
            self.run_hook(env={"TMPDIR": str(temporary_dir)}), "unread records"
        )
        self.assertTrue((self.root / "mv-failed-once").exists())
        state_file = fallback_state_dir / f"{self.session_key()}.json"
        self.assertTrue(state_file.exists(), state_file)
        self.assertEqual(json.loads(state_file.read_text())["consecutive_blocks"], 1)
        self.assert_blocked(
            self.run_hook(active=True, env={"TMPDIR": str(temporary_dir)}),
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
        self.assertIn("could not append its audit log", message)

    def session_key(self, value="session-under-test"):
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
        self.assert_blocked(result, "gate cannot verify: the patrol queue could not be read")

    def test_check_errors_fail_closed_with_recovery_guidance(self):
        malformed_queue = self.bin / "malformed-queue"
        malformed_queue.write_text("#!/bin/sh\nprintf '%s\\n' 'not-json'\n")
        malformed_queue.chmod(0o755)
        waiter_dir = self.queue_state / "waiters"
        retry_state_path = self.queue_state / "stop-gate"
        invalid_tmp = self.root / "tmp-is-a-file"

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

        def break_retry_storage():
            if retry_state_path.is_dir():
                shutil.rmtree(retry_state_path)
            retry_state_path.write_text("not a directory")
            invalid_tmp.write_text("not a directory")

            def restore():
                retry_state_path.unlink()
                invalid_tmp.unlink()

            return restore

        cases = [
            (
                "queue command failure",
                no_change,
                {"HERDR_META_PATROL_QUEUE_COMMAND": str(self.root / "missing-queue")},
                "patrol queue could not be read",
            ),
            (
                "malformed queue data",
                no_change,
                {"HERDR_META_PATROL_QUEUE_COMMAND": str(malformed_queue)},
                "patrol queue returned unparsable",
            ),
            ("malformed waiter directory", hide_waiter_dir, {}, "queue waiter directory"),
            ("missing lifecycle registry", hide_registry, {}, "worker lifecycle registry"),
            ("malformed lifecycle registry", corrupt_registry, {}, "registry is unparsable"),
            (
                "unavailable retry state",
                break_retry_storage,
                {"TMPDIR": str(invalid_tmp)},
                "retry state cannot be created",
            ),
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
