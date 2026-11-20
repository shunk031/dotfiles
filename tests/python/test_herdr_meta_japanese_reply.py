"""Tests for Meta's Japanese-reply Claude Stop hook."""

import contextlib
import importlib.util
import io
import json
import os
import subprocess
import tempfile
import unittest
from datetime import datetime
from pathlib import Path
from unittest import mock

HOOK = Path(__file__).parents[2] / "home/dot_claude/hooks/executable_herdr-meta-japanese-reply.py"
SPEC = importlib.util.spec_from_file_location("meta_japanese_reply", HOOK)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class JapaneseReplyTest(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)
        state_dir = mock.patch.object(MODULE, "STATE_DIR", Path(self.temp_dir.name))
        state_dir.start()
        self.addCleanup(state_dir.stop)

    def run_meta_hook(self, payload):
        agent_list = json.dumps({
            "result": {"agents": [{"name": "meta", "pane_id": "w1:p1"}]}
        })
        output = io.StringIO()
        with mock.patch.dict(os.environ, {"HERDR_ENV": "1", "HERDR_PANE_ID": "w1:p1"}):
            with mock.patch.object(
                MODULE.subprocess,
                "run",
                return_value=subprocess.CompletedProcess([], 0, agent_list, ""),
            ):
                with mock.patch("sys.stdin", io.StringIO(json.dumps(payload))):
                    with contextlib.redirect_stdout(output):
                        MODULE.main()
        return output.getvalue()

    def test_blocks_english_prose(self):
        payload = {
            "hook_event_name": "Stop",
            "session_id": "session-1",
            "last_assistant_message": (
                "I checked the implementation and found the cause. "
                "The setting is missing, so the command exits before it can run."
            ),
        }
        self.assertEqual(json.loads(self.run_meta_hook(payload)), {
            "decision": "block",
            "reason": MODULE.BLOCK_REASON,
        })

    def test_japanese_with_code_urls_and_paths_passes(self):
        japanese = "変更内容と確認結果を日本語で説明し、次の作業も利用者に伝えます。" * 2
        english = "EnglishWord" * 14
        message = (
            japanese
            + "\n`" + english + "`\n"
            + "```text\n" + english + "\n```\n"
            + "https://example.com/" + english + "\n"
            + "/Users/example/" + english + ".txt\n"
            + "./src/" + english + ".py\n"
            + "tests/python/" + english + ".py\n"
            + "C:\\Users\\example\\" + english + ".txt"
        )
        visible = MODULE.visible_prose(message)
        self.assertNotIn("EnglishWord", visible)
        letters = [character for character in visible if character.isalpha()]
        self.assertGreaterEqual(len(letters), 40)
        self.assertGreaterEqual(
            sum(MODULE.is_japanese_letter(character) for character in letters) * 10,
            len(letters) * 3,
        )
        self.assertFalse(MODULE.should_block(message))

    def test_command_words_at_sentence_start_are_not_discarded(self):
        message = "\n".join(
            [
                "Set the configuration as shown. This change resolves the missing setting and completes the requested work.",
                "Make sure the results are checked after running the validation.",
                "Find the relevant details in the report before updating the plan.",
                "Go through each step and explain why the implementation works.",
                "Python is used to validate the implementation and return results.",
                "Command output includes a useful summary of the current status.",
                "Git is used to track the source and review each change.",
                "Source files contain the relevant definitions and examples.",
                "Export options are documented for every supported environment.",
                "make sure the implementation covers every requested behavior and explains the result to the user.",
                "find the relevant details in the report before updating the plan.",
                "set the configuration as shown and complete the requested work.",
                "go through the steps to verify the implementation.",
                "source files contain the relevant definitions and examples.",
                "export options are documented for every supported environment.",
                "python is used to validate the implementation and return results.",
                "git is used to track the source and review each change.",
                "echo the result after checking every section for clarity.",
                "date ranges show when the process starts and ends.",
                "cat behavior can vary across different contexts.",
            ]
        )
        visible = MODULE.visible_prose(message)
        self.assertIn("Set the configuration", visible)
        self.assertIn("Find the relevant details", visible)
        self.assertTrue(MODULE.should_block(message))

    def test_command_lines_remain_countable_as_english(self):
        message = (
            'customtool payload --message "The requested implementation is complete '
            'and validation passed successfully."'
        )

        self.assertIn(message, MODULE.visible_prose(message))
        self.assertTrue(MODULE.should_block(message))

    def test_attached_urls_and_paths_with_arbitrary_extensions_are_removed(self):
        url = "www.superlongenglishdomainnameandpath.example/path"
        absolute_path = "/Users/alice/verylongenglishprojectname.csv"
        relative_path = "reports/verylongenglishfilename.csv"
        windows_path = r"C:\Users\alice\verylongenglishfilename.csv"
        filename = "verylongenglishfilename.csv"
        message = (
            "確認します"
            + url
            + " を確認します。 保存先は"
            + absolute_path
            + "を確認します。 相対パスは"
            + relative_path
            + "を確認します。 Windows側は"
            + windows_path
            + "を確認します。 ファイル名は"
            + filename
            + "を確認します。"
        )

        visible = MODULE.visible_prose(message)
        for value in (url, absolute_path, relative_path, windows_path, filename):
            with self.subTest(value=value):
                self.assertNotIn(value, visible)
        for japanese_suffix in ("確認します", "を確認します。"):
            with self.subTest(japanese_suffix=japanese_suffix):
                self.assertIn(japanese_suffix, visible)
        self.assertFalse(MODULE.should_block(message))

    def test_japanese_suffix_after_url_remains_countable(self):
        prefix = "日" * 10
        url = "www.example.com"
        suffix = "語" * 20
        english = "English" * 9
        message = prefix + url + suffix + " " + english

        visible = MODULE.visible_prose(message)
        self.assertNotIn(url, visible)
        self.assertIn(prefix, visible)
        self.assertIn(suffix, visible)
        self.assertFalse(MODULE.should_block(message))

    def test_slash_compounds_are_not_discarded_as_relative_paths(self):
        messages = (
            "Input/output and request/response are valid distinctions.",
            "Read/write/execute are common access permissions.",
        )
        for message in messages:
            with self.subTest(message=message):
                visible = MODULE.visible_prose(message)
                self.assertIn(message.split()[0], visible)
                self.assertTrue(MODULE.should_block(message))

    def test_verbatim_relay_is_excluded(self):
        message = (
            "---BEGIN---\n"
            + "This is a verbatim relay with English content. " * 6
            + "---END---\n"
            + "上記は引用した文章です。今回の回答では、現在の状態と対応内容を日本語で説明します。"
            "確認結果を整理し、必要な変更を最後まで実施します。"
        )
        visible = MODULE.visible_prose(message)
        letters = [character for character in visible if character.isalpha()]
        self.assertGreaterEqual(len(letters), 40)
        self.assertGreaterEqual(
            sum(MODULE.is_japanese_letter(character) for character in letters) * 10,
            len(letters) * 3,
        )
        self.assertFalse(MODULE.should_block(message))

    def test_english_reply_after_another_hook_blocks(self):
        payload = {
            "hook_event_name": "Stop",
            "session_id": "session-1",
            "stop_hook_active": True,
            "last_assistant_message": (
                "This English reply has enough alphabetic prose "
                "to trigger the hook."
            ),
        }
        self.assertEqual(json.loads(self.run_meta_hook(payload)), {
            "decision": "block",
            "reason": MODULE.BLOCK_REASON,
        })

    def test_japanese_reply_passes_and_resets_the_block_counter(self):
        english = "This English reply has enough alphabetic prose to trigger the hook."
        japanese = (
            "変更内容と確認結果を日本語で説明し、"
            "次の作業も利用者に伝えます。"
        ) * 2
        base_payload = {"hook_event_name": "Stop", "session_id": "session-1"}

        first = self.run_meta_hook({**base_payload, "last_assistant_message": english})
        self.assertEqual(json.loads(first)["decision"], "block")
        self.assertEqual(
            self.run_meta_hook({**base_payload, "last_assistant_message": japanese}),
            "",
        )
        after_reset = self.run_meta_hook({**base_payload, "last_assistant_message": english})
        self.assertEqual(json.loads(after_reset)["decision"], "block")

    def test_fourth_consecutive_block_allows_and_logs_without_reply_text(self):
        message = "This English reply has enough alphabetic prose to trigger the hook."
        payload = {
            "hook_event_name": "Stop",
            "session_id": "session-1",
            "last_assistant_message": message,
        }

        outputs = [
            self.run_meta_hook({**payload, "stop_hook_active": index > 0})
            for index in range(4)
        ]
        self.assertEqual([json.loads(value)["decision"] for value in outputs[:3]], ["block"] * 3)
        self.assertEqual(outputs[3], "")

        log_lines = (Path(self.temp_dir.name) / "japanese-reply.log").read_text().splitlines()
        entries = [json.loads(line) for line in log_lines]
        self.assertEqual([entry["decision"] for entry in entries], ["block"] * 3 + ["allow"])
        self.assertEqual(entries[3]["reason"], "block-limit")
        self.assertEqual(
            entries[3]["letter_count"],
            sum(character.isalpha() for character in message),
        )
        self.assertEqual(entries[3]["japanese_letter_count"], 0)
        for entry in entries:
            self.assertIsNotNone(datetime.fromisoformat(entry["at"]).tzinfo)
            self.assertIsInstance(entry["letter_count"], int)
            self.assertIsInstance(entry["japanese_letter_count"], int)
        self.assertNotIn(message, "\n".join(log_lines))

    def test_block_limit_allows_retries_until_a_reply_passes(self):
        english = "This English reply has enough alphabetic prose to trigger the hook."
        japanese = (
            "変更内容と確認結果を日本語で説明し、"
            "次の作業も利用者に伝えます。"
        ) * 2
        base_payload = {"hook_event_name": "Stop", "session_id": "session-1"}

        for index in range(3):
            payload = {
                **base_payload,
                "stop_hook_active": index > 0,
                "last_assistant_message": english,
            }
            self.assertEqual(json.loads(self.run_meta_hook(payload))["decision"], "block")
        retry_payload = {
            **base_payload,
            "stop_hook_active": True,
            "last_assistant_message": english,
        }
        self.assertEqual(self.run_meta_hook(retry_payload), "")
        self.assertEqual(self.run_meta_hook(retry_payload), "")
        self.assertEqual(
            self.run_meta_hook({**retry_payload, "last_assistant_message": japanese}),
            "",
        )
        self.assertEqual(json.loads(self.run_meta_hook(retry_payload))["decision"], "block")

    def test_malformed_input_passes(self):
        result = subprocess.run(
            [str(HOOK)],
            input="{not valid json",
            text=True,
            capture_output=True,
            check=True,
        )
        self.assertEqual(result.stdout, "")
        self.assertEqual(result.stderr, "")

    def test_nonstandard_json_constant_passes(self):
        payload = (
            '{"hook_event_name":"Stop",'
            '"last_assistant_message":"This English reply has enough alphabetic prose to trigger a block.",'
            '"extra":NaN}'
        )
        agent_list = json.dumps({
            "result": {"agents": [{"name": "meta", "pane_id": "w1:p1"}]}
        })
        output = io.StringIO()
        error = io.StringIO()
        with mock.patch.dict(os.environ, {"HERDR_ENV": "1", "HERDR_PANE_ID": "w1:p1"}):
            with mock.patch.object(
                MODULE.subprocess,
                "run",
                return_value=subprocess.CompletedProcess([], 0, agent_list, ""),
            ) as run:
                with mock.patch("sys.stdin", io.StringIO(payload)):
                    with contextlib.redirect_stdout(output), contextlib.redirect_stderr(error):
                        MODULE.main()
                run.assert_not_called()
        self.assertEqual(output.getvalue(), "")
        self.assertEqual(error.getvalue(), "")

    def test_letter_threshold_and_japanese_percentage(self):
        self.assertFalse(MODULE.should_block("a" * 39))
        self.assertTrue(MODULE.should_block("a" * 40))
        self.assertFalse(MODULE.should_block("あ" * 12 + "a" * 28))

    def test_non_meta_session_does_not_run_identity_lookup(self):
        with mock.patch.dict(os.environ, {"HERDR_ENV": "0", "HERDR_PANE_ID": "w1:p1"}):
            payload = {
                "hook_event_name": "Stop",
                "last_assistant_message": "This English reply has enough letters to trigger a block.",
            }
            output = io.StringIO()
            with mock.patch.object(MODULE.subprocess, "run") as run:
                with mock.patch("sys.stdin", io.StringIO(json.dumps(payload))):
                    with contextlib.redirect_stdout(output):
                        MODULE.main()
                run.assert_not_called()
            self.assertEqual(output.getvalue(), "")

    def test_meta_identity_uses_herdr_agent_list(self):
        output = json.dumps({"result": {"agents": [{"name": "meta", "pane_id": "w1:p1"}]}})
        with mock.patch.dict(os.environ, {"HERDR_ENV": "1", "HERDR_PANE_ID": "w1:p1"}):
            with mock.patch.object(
                MODULE.subprocess,
                "run",
                return_value=subprocess.CompletedProcess([], 0, output, ""),
            ) as run:
                self.assertTrue(MODULE.is_meta_session())
                run.assert_called_once_with(
                    ["herdr", "agent", "list"],
                    capture_output=True,
                    check=False,
                    text=True,
                    timeout=MODULE.META_AGENT_LIST_TIMEOUT,
                )


if __name__ == "__main__":
    unittest.main()
