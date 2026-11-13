"""Behavior checks for the background Herdr tab title hook."""

import importlib.machinery
import importlib.util
import os
import tempfile
import tomllib
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch


SOURCE = (
    Path(__file__).parents[2]
    / "home"
    / "private_dot_local"
    / "private_bin"
    / "exact_common"
    / "executable_herdr-tab-title"
)
LOADER = importlib.machinery.SourceFileLoader("herdr_tab_title", str(SOURCE))
SPEC = importlib.util.spec_from_loader(LOADER.name, LOADER)
assert SPEC is not None
MODULE = importlib.util.module_from_spec(SPEC)
LOADER.exec_module(MODULE)


class HerdrTabTitleTests(unittest.TestCase):
    def test_subagent_cannot_rename_owner_tab(self):
        pane = {"agent_session": {"value": "owner-session"}}
        self.assertTrue(MODULE.is_owner(pane, "owner-session"))
        self.assertFalse(MODULE.is_owner(pane, "subagent-session"))
        self.assertFalse(MODULE.is_owner({"agent_session": None}, "owner-session"))

    def test_plugin_finds_hook_state_without_hook_socket_environment(self):
        with tempfile.TemporaryDirectory() as directory:
            with patch.dict(os.environ, {"XDG_CACHE_HOME": directory, "HERDR_SOCKET_PATH": "hook-socket"}):
                from_hook = MODULE.cache_path("owner-session")
            with patch.dict(os.environ, {"XDG_CACHE_HOME": directory, "HERDR_SOCKET_PATH": ""}):
                from_plugin = MODULE.cache_path("owner-session")
        self.assertEqual(from_hook, from_plugin)

    def test_stale_or_orchestrator_label_is_preserved(self):
        self.assertFalse(MODULE.can_replace("🤖 Orchestrator", None))
        self.assertFalse(MODULE.can_replace("A hand-written name", None))
        self.assertTrue(MODULE.can_replace("2", None))
        self.assertFalse(MODULE.can_replace("User's manual name", "🚧 Old step"))
        self.assertTrue(MODULE.can_replace("🚧 Old step", "🚧 Old step"))

    def test_model_text_cannot_inject_status_or_control_characters(self):
        self.assertEqual(MODULE.clean_text("⛔ Build\n\x1b[31mnow"), "Build now")

    def test_complete_requires_stop_and_merged_pr(self):
        decision = {"state": "complete", "title": "API 更新", "pr_number": 123}
        self.assertEqual(MODULE.make_label("PostToolUse", decision, None), "🚧 API 更新")
        self.assertEqual(MODULE.make_label("Stop", decision, "OPEN"), "⛔ review and merge PR #123")
        self.assertEqual(MODULE.make_label("Stop", decision, "MERGED"), "✅ API 更新 #123")
        self.assertEqual(MODULE.make_label("Stop", decision, None), "⛔ PR #123 の状態確認待ち")

    def test_complete_without_pr_uses_task_name(self):
        decision = {"state": "complete", "title": "調査完了", "pr_number": None}
        self.assertEqual(MODULE.make_label("Stop", decision, None), "✅ 調査完了")

    def test_blocked_uses_next_action(self):
        decision = {"state": "blocked", "title": "調査", "next_action": "利用者の回答待ち"}
        self.assertEqual(MODULE.make_label("Stop", decision, None), "⛔ 利用者の回答待ち")

    def test_open_pr_blocker_keeps_observer_handoff_label(self):
        decision = {"state": "blocked", "title": "Review", "next_action": "Waiting", "pr_number": 123}
        self.assertEqual(MODULE.make_label("Stop", decision, "OPEN"), "⛔ review and merge PR #123")

    def test_herdr_lifecycle_recovers_active_title(self):
        state = {"last_label": "⛔ 承認または入力待ち", "last_active_title": "API 更新"}
        self.assertEqual(MODULE.lifecycle_label("working", state), "🚧 API 更新")
        self.assertIsNone(MODULE.lifecycle_label("blocked", state))
        self.assertIsNone(MODULE.lifecycle_label("done", state))
        self.assertIsNone(MODULE.lifecycle_label("blocked", {"last_label": "✅ API 更新"}))
        self.assertIsNone(MODULE.lifecycle_label("working", {"last_label": "⛔ PR #123 のマージ待ち"}))
        self.assertEqual(MODULE.lifecycle_label("blocked", {"last_label": "🚧 API 更新"}), "⛔ 承認または入力待ち")

    def test_hook_only_queues_detached_work(self):
        with tempfile.TemporaryDirectory() as directory:
            environment = {"HERDR_ENV": "1", "HERDR_SOCKET_PATH": "test-socket", "XDG_CACHE_HOME": directory}
            with patch.dict(os.environ, environment), patch.object(MODULE.subprocess, "Popen") as launch:
                launch.return_value.pid = 12345
                MODULE.enqueue({
                    "hook_event_name": "UserPromptSubmit",
                    "session_id": "test-session",
                    "prompt": "Update a tab title",
                    "cwd": directory,
                })
                state = MODULE.load(MODULE.cache_path("test-session"))
            self.assertEqual(state["prompt"], "Update a tab title")
            self.assertEqual(state["worker_pid"], 12345)
            self.assertEqual(launch.call_count, 1)
            self.assertTrue(launch.call_args.kwargs["start_new_session"])

    def test_subagent_hook_does_not_queue_even_with_parent_session_id(self):
        with tempfile.TemporaryDirectory() as directory:
            with patch.dict(os.environ, {"HERDR_ENV": "1", "XDG_CACHE_HOME": directory}), patch.object(MODULE.subprocess, "Popen") as launch:
                MODULE.enqueue({
                    "hook_event_name": "PostToolUse", "session_id": "owner-session", "agent_id": "child-1",
                })
            launch.assert_not_called()

    def test_late_tool_hook_does_not_replace_stop_event(self):
        with tempfile.TemporaryDirectory() as directory:
            with patch.dict(os.environ, {"HERDR_ENV": "1", "XDG_CACHE_HOME": directory}), patch.object(MODULE.subprocess, "Popen") as launch:
                launch.return_value.pid = 12345
                MODULE.enqueue({"hook_event_name": "Stop", "session_id": "test-session"})
                MODULE.enqueue({"hook_event_name": "PostToolUse", "session_id": "test-session"})
                state = MODULE.load(MODULE.cache_path("test-session"))
            self.assertEqual(state["event"], "Stop")
            self.assertEqual(state["generation"], 1)

    def test_model_call_is_low_effort_and_does_not_run_hooks(self):
        def fake_run(command, **_kwargs):
            Path(command[command.index("-o") + 1]).write_text(
                '{"state":"working","title":"Build","next_action":"","pr_number":null}'
            )
            return SimpleNamespace(returncode=0)

        with patch.object(MODULE.subprocess, "run", side_effect=fake_run) as run:
            answer = MODULE.ask_model({"event": "UserPromptSubmit", "prompt": "Build"})
        command = run.call_args.args[0]
        self.assertEqual(answer["title"], "Build")
        self.assertIn("gpt-6-luna", command)
        self.assertIn("model_reasoning_effort=low", command)
        self.assertIn("features.hooks=false", command)
        self.assertIn("read-only", command)

    def test_stop_worker_renames_live_owner_tab_and_scrubs_prompt(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "state.json"
            MODULE.save(path, {
                "session_id": "owner-session", "worker_pid": os.getpid(), "generation": 1,
                "event": "Stop", "prompt": "Private task", "cwd": directory,
            })
            labels = ["2"]

            def fake_herdr(*args):
                if args[:2] == ("pane", "current"):
                    return {"result": {"pane": {
                        "tab_id": "tab-1", "agent_session": {"value": "owner-session"},
                        "agent_status": "working",
                    }}}
                if args[:2] == ("tab", "get"):
                    return {"result": {"tab": {"label": labels[0]}}}
                if args[:2] == ("tab", "rename"):
                    labels[0] = args[3]
                    return {"result": {"tab": {"tab_id": args[2], "label": labels[0]}}}
                raise AssertionError(args)

            decision = {"state": "blocked", "title": "Build", "next_action": "Review", "pr_number": 123}
            with patch.object(MODULE.time, "sleep"), patch.object(MODULE, "herdr", side_effect=fake_herdr), patch.object(MODULE, "ask_model", return_value=decision), patch.object(MODULE, "pr_state", return_value="OPEN"):
                MODULE.worker(path)
            self.assertEqual(labels[0], "⛔ review and merge PR #123")
            state = MODULE.load(path)
            self.assertEqual(state["last_label"], labels[0])
            self.assertNotIn("prompt", state)

    def test_plugin_watches_agent_status_changes(self):
        manifest = (
            Path(__file__).parents[2]
            / "home"
            / "private_dot_local"
            / "private_share"
            / "herdr-plugins"
            / "herdr-tab-title"
            / "herdr-plugin.toml"
        )
        config = tomllib.loads(manifest.read_text())
        self.assertEqual(config["id"], "shunk031.herdr-tab-title")
        self.assertIn("pane.agent_status_changed", [event["on"] for event in config["events"]])


if __name__ == "__main__":
    unittest.main()
