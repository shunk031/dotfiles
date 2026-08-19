from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT_PATH = REPO_ROOT / "scripts/doc_slop_review.py"
FIXTURE_PATH = REPO_ROOT / "tests/fixtures/markdown/hard_wraps.txt"


def load_module():
    spec = importlib.util.spec_from_file_location("doc_slop_review", SCRIPT_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Failed to load module from {SCRIPT_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class MarkdownHardWrapTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.module = load_module()
        cls.rubric = cls.module.load_rubric()

    def test_deterministic_tier_delegates_to_textlint(self) -> None:
        document = self.module.Document(
            name=str(FIXTURE_PATH),
            text=FIXTURE_PATH.read_text(encoding="utf-8"),
        )

        findings = self.module.run_prechecks(document, self.rubric)
        hard_wraps = [finding for finding in findings if finding.detector == "textlint"]

        self.assertEqual(len(hard_wraps), 2)
        self.assertEqual(
            {finding.excerpt for finding in hard_wraps},
            {
                "日本語の途中",
                "- 箇条書きの途中",
            },
        )
        for finding in hard_wraps:
            self.assertEqual(finding.severity, "high")
            self.assertTrue(finding.category.startswith("markdown-textlint:"))
            self.assertEqual(finding.detector, "textlint")
            self.assertIn(
                "run: uv run python scripts/markdown_unwrap.py --fix <file>",
                finding.why,
            )

    def test_unavailable_textlint_is_a_review_error(self) -> None:
        original = self.module.MARKDOWN_UNWRAP_SCRIPT_PATH
        self.module.MARKDOWN_UNWRAP_SCRIPT_PATH = Path("/does/not/exist.py")
        try:
            with self.assertRaises(self.module.ReviewError) as context:
                self.module.run_prechecks(
                    self.module.Document(name="note.md", text="日本語の文。\n"),
                    self.rubric,
                )
        finally:
            self.module.MARKDOWN_UNWRAP_SCRIPT_PATH = original

        self.assertIn("textlint check could not run", str(context.exception))

        original = self.module.MARKDOWN_UNWRAP_SCRIPT_PATH
        self.module.MARKDOWN_UNWRAP_SCRIPT_PATH = Path("/does/not/exist.py")
        try:
            with tempfile.TemporaryDirectory() as tempdir:
                path = Path(tempdir) / "note.md"
                path.write_text("日本語の文。\n", encoding="utf-8")
                self.assertEqual(self.module.main([str(path), "--skip-model"]), 2)
        finally:
            self.module.MARKDOWN_UNWRAP_SCRIPT_PATH = original

    def test_clean_and_protected_markdown_has_no_hard_wrap_finding(self) -> None:
        document = self.module.Document(
            name="clean.md",
            text=(
                "日本語の文。\n次の文です。\n"
                "日本語  \n続きです。\n"
                "日本語<br>\n続きです。\n"
                "```text\n日本語\n続き\n```\n"
            ),
        )

        findings = self.module.run_prechecks(document, self.rubric)

        self.assertEqual(findings, [])
