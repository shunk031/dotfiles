from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT_PATH = REPO_ROOT / "scripts/markdown_unwrap.py"
FIXTURE_DIR = REPO_ROOT / "tests/fixtures/markdown"


def load_module():
    spec = importlib.util.spec_from_file_location("markdown_unwrap", SCRIPT_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Failed to load module from {SCRIPT_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class MarkdownUnwrapTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.module = load_module()

    def test_fixture_joins_japanese_english_and_mixed_prose(self) -> None:
        source = (FIXTURE_DIR / "unwrap_input.txt").read_text(encoding="utf-8")
        expected = (FIXTURE_DIR / "unwrap_expected.txt").read_text(encoding="utf-8")

        self.assertEqual(self.module.unwrap_markdown(source), expected)

    def test_cjk_boundaries_do_not_insert_a_space(self) -> None:
        self.assertEqual(
            self.module.unwrap_markdown("日本語の途中\n続きです。\n"),
            "日本語の途中続きです。\n",
        )

    def test_non_cjk_boundaries_insert_one_space(self) -> None:
        self.assertEqual(
            self.module.unwrap_markdown("English\ncontinuation\n"),
            "English continuation\n",
        )

    def test_hard_wrap_finder_excludes_sentence_punctuation(self) -> None:
        self.assertEqual(
            self.module.find_hard_wraps("日本語の文。\n次の文です。\n"),
            [],
        )

    def test_check_reports_and_fix_rewrites_in_place(self) -> None:
        with tempfile.TemporaryDirectory() as tempdir:
            path = Path(tempdir) / "note.md"
            path.write_text("日本語の途中\n続きです。\n", encoding="utf-8")

            self.assertEqual(self.module.main(["--check", str(path)]), 1)
            self.assertEqual(
                path.read_text(encoding="utf-8"), "日本語の途中\n続きです。\n"
            )
            self.assertEqual(self.module.main(["--fix", str(path)]), 0)
            self.assertEqual(
                path.read_text(encoding="utf-8"), "日本語の途中続きです。\n"
            )
            self.assertEqual(self.module.main(["--check", str(path)]), 0)
