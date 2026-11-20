"""Tests for the Claude unchecked-caveat Stop hook."""

import json
import subprocess
import unittest
from pathlib import Path

HOOK = Path(__file__).parents[2] / "home/dot_claude/hooks/executable_unchecked-caveat-check.py"


class UncheckedCaveatCheckTest(unittest.TestCase):
    def run_hook(self, message, *, active=False):
        payload = {"hook_event_name": "Stop", "stop_hook_active": active,
                   "last_assistant_message": message}
        return subprocess.run(
            ["python3", str(HOOK)], input=json.dumps(payload), text=True,
            capture_output=True, check=True)

    def test_blocks_present_tense_caveats(self):
        messages = (
            "私は確かめていません。", "どちらなのかは確かめていません。",
            "まだ確認していません。", "まだ確認できていません。", "条件を調べていません。",
            "境界を検証していません。", "未確認です。", "確かめていない。",
            "This is not yet verified.", "I haven't checked.", "This is unverified.", "The result is unverifiedです。",
            "This has `unverified`` with mismatched delimiters.", "```python`invalid-info\n未確認です。\n```", "    ```\n    example\n\n未確認です。", "    > code\n未確認です。",
        )
        for message in messages:
            output = json.loads(self.run_hook(message).stdout)
            self.assertEqual(output["decision"], "block", message)
            self.assertIn("run the check now", output["reason"].lower(), message)
            self.assertIn("who must do what", output["reason"], message)

    def test_allows_past_tense_caveat(self):
        messages = ("事前に確かめていませんでした。", "確認していませんでした。",
                    "確認できていませんでした。", "調べていませんでした。",
                    "検証していませんでした。", "未確認でした。")
        for message in messages:
            self.assertEqual(self.run_hook(message).stdout, "", message)

    def test_allows_reentered_stop(self):
        self.assertEqual(self.run_hook("まだ確かめていません。", active=True).stdout, "")

    def test_ignores_code_and_quoted_text(self):
        messages = (
            "```text\n未確認\n```", "````text\n```\nunverified\n````", "```text\n    ```\nunverified\n```",
            "    unverified", "   \t未確認です。", "This has `unverified` inside code.", "`unverified\ncontinues`",
            "> Quoted example:\nunverified", "「未確認です。\n引用の続き」",
            "引用: “unverified” and 'haven't checked'", "“I haven't checked\nthis yet.”", "He wrote: \"not yet verified\nin the report.\"",
        )
        for message in messages:
            self.assertEqual(self.run_hook(message).stdout, "", message)

    def test_deeply_nested_json_fails_open(self):
        payload = "[" * 2000 + "0" + "]" * 2000
        result = subprocess.run(
            ["python3", str(HOOK)], input=payload, text=True,
            capture_output=True, check=True)
        self.assertEqual(result.stdout, "")

    def test_allows_message_without_caveat(self):
        self.assertEqual(self.run_hook("確認が完了しました。").stdout, "")


if __name__ == "__main__":
    unittest.main()
