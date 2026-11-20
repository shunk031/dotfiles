"""Tests for the Claude unchecked-caveat Stop hook."""

import json
import subprocess
import unittest
from pathlib import Path

HOOK = Path(__file__).parents[2] / "home/dot_claude/hooks/executable_unchecked-caveat-check.py"


class UncheckedCaveatCheckTest(unittest.TestCase):
    def run_hook(self, message, *, active=False):
        payload = {
            "hook_event_name": "Stop",
            "stop_hook_active": active,
            "last_assistant_message": message,
        }
        return subprocess.run(
            ["python3", str(HOOK)], input=json.dumps(payload), text=True,
            capture_output=True, check=True,
        )

    def test_blocks_present_tense_caveats(self):
        messages = (
            "私は確かめていません。", "どちらなのかは確かめていません。",
            "まだ確認していません。", "まだ確認できていません。", "条件を調べていません。",
            "境界を検証していません。", "未確認です。", "確かめていない。",
            "This is not yet verified.", "I haven't checked.", "This is unverified.",
        )
        for message in messages:
            with self.subTest(message=message):
                output = json.loads(self.run_hook(message).stdout)
                self.assertEqual(output["decision"], "block")
                self.assertIn("run the check now", output["reason"].lower())
                self.assertIn("who must do what", output["reason"])

    def test_allows_past_tense_caveat(self):
        messages = (
            "事前に確かめていませんでした。", "確認していませんでした。",
            "確認できていませんでした。", "調べていませんでした。",
            "検証していませんでした。", "未確認でした。",
        )
        for message in messages:
            with self.subTest(message=message):
                self.assertEqual(self.run_hook(message).stdout, "")

    def test_allows_reentered_stop(self):
        self.assertEqual(self.run_hook("まだ確かめていません。", active=True).stdout, "")

    def test_ignores_code_and_quoted_text(self):
        messages = (
            "```text\n未確認\n```",
            "````text\n```\nunverified\n````",
            "    unverified",
            "引用: “unverified” and 'haven't checked'",
        )
        for message in messages:
            with self.subTest(message=message):
                self.assertEqual(self.run_hook(message).stdout, "")

    def test_allows_message_without_caveat(self):
        self.assertEqual(self.run_hook("確認が完了しました。").stdout, "")


if __name__ == "__main__":
    unittest.main()
