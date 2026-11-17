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

    def run_hook(self, *, active=False, env=None):
        payload = {
            "hook_event_name": "Stop",
            "session_id": "session-under-test",
            "stop_hook_active": active,
        }
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
        self.registry.parent.mkdir(parents=True)
        row = "meta\tw1:p1\tmeta-terminal\tgate-task\tgate-worker\tworker-terminal\tw2:t2\tw2:p2\tstarted\n"
        self.registry.write_text(row)

        self.assert_blocked(self.run_hook(), "gate-worker")

        self.registry.write_text(row.replace("\tstarted\n", "\tcollected\n"))
        result = self.run_hook()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")

    def test_other_claude_session_is_not_gated(self):
        self.run_queue("add", "--from", "gate-test", "unread record")
        result = self.run_hook(env={"HERDR_PANE_ID": "w9:p9"})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")

    def test_stop_hook_active_allows_to_prevent_a_repeat_loop(self):
        self.run_queue("add", "--from", "gate-test", "unread record")
        result = self.run_hook(active=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")

    def test_queue_failure_blocks_for_retry_after_meta_is_identified(self):
        result = self.run_hook(env={
            "HERDR_META_PATROL_QUEUE_COMMAND": str(self.root / "missing-queue"),
        })
        self.assert_blocked(result, "queue")

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
