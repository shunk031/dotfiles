from __future__ import annotations

import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT_PATH = REPO_ROOT / "scripts/markdown_unwrap.py"
CONFIG_PATH = (
    REPO_ROOT / "home/dot_config/textlint/markdown_unwrap.textlintrc.json"
)
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

        self.assert_wrapper_matches(source, expected)

    def test_cjk_boundaries_do_not_insert_a_space(self) -> None:
        self.assert_wrapper_matches(
            "日本語の途中\n続きです。\n", "日本語の途中続きです。\n"
        )

    def test_non_cjk_boundaries_insert_one_space(self) -> None:
        self.assert_wrapper_matches(
            "English\ncontinuation\n", "English continuation\n"
        )

    def test_explicit_breaks_are_preserved(self) -> None:
        source = "日本語  \n続きです。\n日本語<br>\n次の段落です。\n"
        self.assert_wrapper_matches(source, source)

    def test_spacing_rule_side_effect_is_pinned(self) -> None:
        source = (FIXTURE_DIR / "spacing_side_effect_input.txt").read_text(
            encoding="utf-8"
        )
        expected = (FIXTURE_DIR / "spacing_side_effect_expected.txt").read_text(
            encoding="utf-8"
        )

        self.assert_wrapper_matches(source, expected)

    def test_blockquotes_are_left_unchanged(self) -> None:
        source = (FIXTURE_DIR / "blockquote_input.txt").read_text(encoding="utf-8")
        expected = (FIXTURE_DIR / "blockquote_expected.txt").read_text(
            encoding="utf-8"
        )

        self.assert_wrapper_matches(source, expected)

    def test_config_contains_only_the_two_hybrid_rules(self) -> None:
        config = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))

        self.assertEqual(
            set(config["rules"]),
            {
                "@cffnpwr/textlint-rule-no-arbitrary-line-break",
                "ja-space-between-half-and-full-width",
            },
        )
        self.assertEqual(
            config["rules"]["ja-space-between-half-and-full-width"],
            {"space": ["alphabets", "numbers"]},
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

    def assert_wrapper_matches(self, source: str, expected: str) -> None:
        with tempfile.TemporaryDirectory() as tempdir:
            path = Path(tempdir) / "note.md"
            path.write_text(source, encoding="utf-8")

            self.assertEqual(self.module.main(["--fix", str(path)]), 0)
            self.assertEqual(path.read_text(encoding="utf-8"), expected)

            self.assertEqual(self.module.main(["--check", str(path)]), 0)
