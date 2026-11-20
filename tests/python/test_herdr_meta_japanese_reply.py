"""Tests for Meta's Japanese-reply Claude Stop hook."""

import contextlib
import importlib.util
import io
import json
import os
import subprocess
import unittest
from pathlib import Path
from unittest import mock

HOOK = Path(__file__).parents[2] / "home/dot_claude/hooks/executable_herdr-meta-japanese-reply.py"
SPEC = importlib.util.spec_from_file_location("meta_japanese_reply", HOOK)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class JapaneseReplyTest(unittest.TestCase):
    def test_blocks_english_prose(self):
        payload = {
            "hook_event_name": "Stop",
            "last_assistant_message": (
                "I checked the implementation and found the cause. "
                "The setting is missing, so the command exits before it can run."
            ),
        }
        output = io.StringIO()
        agent_list = json.dumps({
            "result": {"agents": [{"name": "meta", "pane_id": "w1:p1"}]}
        })
        with mock.patch.dict(os.environ, {"HERDR_ENV": "1", "HERDR_PANE_ID": "w1:p1"}):
            with mock.patch.object(
                MODULE.subprocess,
                "run",
                return_value=subprocess.CompletedProcess([], 0, agent_list, ""),
            ):
                with mock.patch("sys.stdin", io.StringIO(json.dumps(payload))):
                    with contextlib.redirect_stdout(output):
                        MODULE.main()
        self.assertEqual(json.loads(output.getvalue()), {
            "decision": "block",
            "reason": MODULE.BLOCK_REASON,
        })

    def test_japanese_with_code_urls_paths_and_commands_passes(self):
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
            + "C:\\Users\\example\\" + english + ".txt\n"
            + "git status --short  # " + english + "\n"
            + "- git status --short  # " + english + "\n"
            + "make test  # " + english + "\n"
            + "set -e  # " + english + "\n"
            + "export PATH=/bin  # " + english + "\n"
            + "find . -name '*.py'  # " + english + "\n"
            + "python3 tests/python/test_file.py --quiet  # " + english + "\n"
            + "source ~/.bashrc  # " + english
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

    def test_command_syntax_is_removed_without_discarding_prose(self):
        command = (
            'custom-tool --message "The requested implementation is complete '
            'and validation passed successfully."'
        )
        plain_executable = (
            'customtool --message "The requested implementation is complete '
            'and validation passed successfully."'
        )
        short_flag_executable = (
            'customtool -m "The requested implementation is complete '
            'and validation passed successfully."'
        )
        lines = (
            command,
            plain_executable,
            short_flag_executable,
            "$ " + command,
            "MODE=fast " + command,
            "./custom-tool --message 'The requested implementation is complete.'",
            "git status",
            "make test",
        )
        for line in lines:
            with self.subTest(line=line):
                self.assertTrue(MODULE.is_command_line(line))
                self.assertNotIn(line, MODULE.visible_prose(line))

        prose = (
            "make sure this explanation remains visible to the reader.",
            "Find the relevant result and explain what changed.",
            "Set the configuration so the requested behavior works.",
            "source files describe how the application works.",
        )
        for line in prose:
            with self.subTest(line=line):
                self.assertFalse(MODULE.is_command_line(line))
                self.assertIn(line, MODULE.visible_prose(line))

    def test_attached_urls_and_paths_with_arbitrary_extensions_are_removed(self):
        url = "www.superlongenglishdomainnameandpath.example/日本語"
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

    def test_second_attempt_passes(self):
        payload = {
            "hook_event_name": "Stop",
            "stop_hook_active": True,
            "last_assistant_message": "This English reply has enough alphabetic prose to trigger the hook.",
        }
        with mock.patch.dict(os.environ, {"HERDR_ENV": "1", "HERDR_PANE_ID": "w1:p1"}):
            with mock.patch.object(MODULE.subprocess, "run") as run:
                with mock.patch("sys.stdin", io.StringIO(json.dumps(payload))):
                    output = io.StringIO()
                    with contextlib.redirect_stdout(output):
                        MODULE.main()
                run.assert_not_called()
        self.assertEqual(output.getvalue(), "")

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
