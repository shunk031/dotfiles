from __future__ import annotations

import argparse
import importlib.util
import json
import re
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch


SCRIPT_PATH = (
    Path(__file__).resolve().parents[2]
    / "home/dot_agents/skills/gh-comment-attach-files/scripts/attach_comment_files.py"
)
SPEC = importlib.util.spec_from_file_location("attach_comment_files", SCRIPT_PATH)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


class ParseArgsTests(unittest.TestCase):
    def parse_args(self, *args: str) -> argparse.Namespace:
        with patch.object(sys, "argv", ["attach_comment_files.py", *args]):
            return MODULE.parse_args()

    def test_parse_args_accepts_direct_url(self) -> None:
        args = self.parse_args("--url", "https://github.com/owner/repo/pull/1", "note.md")
        self.assertEqual(args.url, "https://github.com/owner/repo/pull/1")
        self.assertEqual(args.files, ["note.md"])

    def test_parse_args_requires_issue_or_pr_with_repo(self) -> None:
        with self.assertRaises(SystemExit) as context:
            self.parse_args("--repo", "owner/repo", "note.md")
        self.assertEqual(context.exception.code, 2)

    def test_parse_args_requires_repo_with_issue_or_pr(self) -> None:
        with self.assertRaises(SystemExit) as context:
            self.parse_args("--url", "https://github.com/owner/repo/pull/1", "--issue", "1", "note.md")
        self.assertEqual(context.exception.code, 2)


class HelperFunctionTests(unittest.TestCase):
    def test_ensure_command_raises_for_missing_binary(self) -> None:
        with patch.object(MODULE.shutil, "which", return_value=None):
            with self.assertRaises(SystemExit) as context:
                MODULE.ensure_command("npx")
        self.assertEqual(str(context.exception), "Required command not found: npx")

    def test_ensure_command_accepts_existing_binary(self) -> None:
        with patch.object(MODULE.shutil, "which", return_value="/usr/bin/npx"):
            MODULE.ensure_command("npx")

    def test_validate_source_files_accepts_real_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            source_path = Path(tmpdir) / "report.md"
            source_path.write_text("ok", encoding="utf-8")
            MODULE.validate_source_files([source_path])

    def test_validate_source_files_rejects_missing_or_directory(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            missing_path = Path(tmpdir) / "missing.md"
            with self.assertRaises(SystemExit) as context:
                MODULE.validate_source_files([missing_path])
            self.assertIn("File not found", str(context.exception))

            with self.assertRaises(SystemExit) as context:
                MODULE.validate_source_files([Path(tmpdir)])
            self.assertIn("Not a file", str(context.exception))

    def test_resolve_target_url_returns_direct_url(self) -> None:
        args = argparse.Namespace(url="https://github.com/owner/repo/pull/1", repo=None, issue=None, pr=None)
        self.assertEqual(MODULE.resolve_target_url(args), "https://github.com/owner/repo/pull/1")

    def test_resolve_target_url_uses_gh_for_issue(self) -> None:
        args = argparse.Namespace(url=None, repo="owner/repo", issue=7, pr=None)
        completed = subprocess.CompletedProcess(["gh"], 0, stdout="https://github.com/owner/repo/issues/7\n")
        with patch.object(MODULE, "run", return_value=completed) as run_mock:
            target_url = MODULE.resolve_target_url(args)

        run_mock.assert_called_once_with(
            [
                "gh",
                "issue",
                "view",
                "7",
                "--repo",
                "owner/repo",
                "--json",
                "url",
                "--jq",
                ".url",
            ]
        )
        self.assertEqual(target_url, "https://github.com/owner/repo/issues/7")

    def test_resolve_target_url_uses_gh_for_pr(self) -> None:
        args = argparse.Namespace(url=None, repo="owner/repo", issue=None, pr=9)
        completed = subprocess.CompletedProcess(["gh"], 0, stdout="https://github.com/owner/repo/pull/9\n")
        with patch.object(MODULE, "run", return_value=completed) as run_mock:
            target_url = MODULE.resolve_target_url(args)

        run_mock.assert_called_once_with(
            [
                "gh",
                "pr",
                "view",
                "9",
                "--repo",
                "owner/repo",
                "--json",
                "url",
                "--jq",
                ".url",
            ]
        )
        self.assertEqual(target_url, "https://github.com/owner/repo/pull/9")

    def test_resolve_profile_dir_handles_relative_and_absolute_paths(self) -> None:
        absolute = Path("/tmp/profile-dir")
        with patch.object(MODULE.Path, "cwd", return_value=Path("/repo")):
            self.assertEqual(MODULE.resolve_profile_dir(".profiles/test"), Path("/repo/.profiles/test"))
            self.assertEqual(MODULE.resolve_profile_dir(str(absolute)), absolute)

    def test_build_staged_name_sanitizes_and_disambiguates(self) -> None:
        used_names: set[str] = set()
        first = MODULE.build_staged_name(Path("/tmp/My report.md"), used_names)
        second = MODULE.build_staged_name(Path("/tmp/My report.md"), used_names)

        self.assertRegex(first, r"^My-report--[0-9a-f]{8}\.md$")
        self.assertRegex(second, r"^My-report--[0-9a-f]{8}-2\.md$")

    def test_stage_files_copies_sources(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_path = Path(tmpdir)
            uploads_dir = tmp_path / "uploads"
            uploads_dir.mkdir()

            first = tmp_path / "docs" / "report.md"
            second = tmp_path / "assets" / "report.md"
            first.parent.mkdir()
            second.parent.mkdir()
            first.write_text("first", encoding="utf-8")
            second.write_text("second", encoding="utf-8")

            staged_files = MODULE.stage_files([first, second], uploads_dir)

            self.assertEqual(len(staged_files), 2)
            self.assertNotEqual(staged_files[0].staged_name, staged_files[1].staged_name)
            self.assertEqual(staged_files[0].staged_path.read_text(encoding="utf-8"), "first")
            self.assertEqual(staged_files[1].staged_path.read_text(encoding="utf-8"), "second")

    def test_sanitize_component_normalizes_filename_stems(self) -> None:
        sanitized = MODULE.sanitize_component("   report / 2026 . draft !!! ")
        self.assertEqual(sanitized, "report-2026-.-draft")

    def test_extract_attachment_links_filters_non_attachment_urls(self) -> None:
        text = "\n".join(
            [
                "![chart](https://github.com/user-attachments/assets/123)",
                "[doc](https://github.com/attachments/abc)",
                "[other](https://example.com/file.png)",
            ]
        )
        links = MODULE.extract_attachment_links(text)
        self.assertEqual(
            links,
            [
                {"label": "chart", "url": "https://github.com/user-attachments/assets/123"},
                {"label": "doc", "url": "https://github.com/attachments/abc"},
            ],
        )

    def test_find_attachment_url_prefers_new_matching_label(self) -> None:
        before_text = "[old](https://github.com/user-attachments/assets/old)"
        after_text = "\n".join(
            [
                before_text,
                "[chart--deadbeef.png](https://github.com/user-attachments/assets/new)",
            ]
        )
        self.assertEqual(
            MODULE.find_attachment_url(
                staged_name="chart--deadbeef.png",
                before_texts=[before_text],
                after_texts=[after_text],
            ),
            "https://github.com/user-attachments/assets/new",
        )

    def test_find_attachment_url_falls_back_to_last_new_url(self) -> None:
        before_text = "[old](https://github.com/user-attachments/assets/old)"
        after_text = "\n".join(
            [
                before_text,
                "[one](https://github.com/user-attachments/assets/new-1)",
                "[two](https://github.com/user-attachments/assets/new-2)",
            ]
        )
        self.assertEqual(
            MODULE.find_attachment_url(
                staged_name="missing.png",
                before_texts=[before_text],
                after_texts=[after_text],
            ),
            "https://github.com/user-attachments/assets/new-2",
        )

    def test_find_attachment_url_returns_existing_label_when_needed(self) -> None:
        before_text = "[chart--deadbeef.png](https://github.com/user-attachments/assets/existing)"
        after_text = before_text
        self.assertEqual(
            MODULE.find_attachment_url(
                staged_name="chart--deadbeef.png",
                before_texts=[before_text],
                after_texts=[after_text],
            ),
            "https://github.com/user-attachments/assets/existing",
        )

    def test_open_browser_passes_browser_flag_when_requested(self) -> None:
        run_dir = Path("/tmp/run")
        profile_dir = Path("/tmp/profile")
        with patch.object(MODULE, "run") as run_mock:
            MODULE.open_browser("https://github.com/owner/repo/pull/1", run_dir, profile_dir, "chrome")

        run_mock.assert_called_once_with(
            [
                "npx",
                "@playwright/cli",
                "open",
                "https://github.com/owner/repo/pull/1",
                "--headed",
                "--profile",
                str(profile_dir),
                "--browser",
                "chrome",
            ],
            cwd=run_dir,
        )

    def test_open_browser_omits_browser_flag_when_not_requested(self) -> None:
        run_dir = Path("/tmp/run")
        profile_dir = Path("/tmp/profile")
        with patch.object(MODULE, "run") as run_mock:
            MODULE.open_browser("https://github.com/owner/repo/pull/1", run_dir, profile_dir, None)

        run_mock.assert_called_once_with(
            [
                "npx",
                "@playwright/cli",
                "open",
                "https://github.com/owner/repo/pull/1",
                "--headed",
                "--profile",
                str(profile_dir),
            ],
            cwd=run_dir,
        )

    def test_close_browser_ignores_playwright_close_failures(self) -> None:
        error = subprocess.CalledProcessError(1, ["npx", "@playwright/cli", "close"])
        with patch.object(MODULE, "run", side_effect=error):
            MODULE.close_browser(Path("/tmp/run"))

    def test_wait_for_comment_composer_retries_until_found(self) -> None:
        with (
            patch.object(
                MODULE,
                "prepare_comment_composer",
                side_effect=[{"found": False}, {"found": True}],
            ) as prepare_mock,
            patch.object(MODULE.time, "monotonic", side_effect=[0.0, 0.5]),
            patch.object(MODULE.time, "sleep") as sleep_mock,
        ):
            MODULE.wait_for_comment_composer(Path("/tmp/run"), ready_timeout=1, poll_interval=0.1)

        self.assertEqual(prepare_mock.call_count, 2)
        sleep_mock.assert_called_once_with(0.1)

    def test_wait_for_comment_composer_times_out(self) -> None:
        with (
            patch.object(
                MODULE,
                "prepare_comment_composer",
                return_value={"found": False, "pageTitle": "Title", "pageUrl": "https://github.com"},
            ),
            patch.object(MODULE.time, "monotonic", side_effect=[0.0, 2.0]),
        ):
            with self.assertRaises(SystemExit) as context:
                MODULE.wait_for_comment_composer(Path("/tmp/run"), ready_timeout=1, poll_interval=0.1)

        self.assertIn("Timed out waiting for a GitHub comment composer", str(context.exception))
        self.assertIn("Title", str(context.exception))

    def test_prepare_comment_composer_passes_selector_payload(self) -> None:
        with patch.object(MODULE, "run_playwright_json", return_value={"found": True}) as runner:
            result = MODULE.prepare_comment_composer(Path("/tmp/run"))

        call_args = runner.call_args.args[0]
        self.assertEqual(call_args[:2], ["--raw", "run-code"])
        self.assertIn("textareaSelectors", call_args[2])
        self.assertIn("inputSelectors", call_args[2])
        self.assertEqual(result, {"found": True})

    def test_perform_upload_returns_result_when_ok(self) -> None:
        staged = MODULE.StagedFile(
            source_path=Path("/tmp/source.md"),
            staged_path=Path("/tmp/run/uploads/source--deadbeef.md"),
            staged_name="source--deadbeef.md",
        )
        payload = {"ok": True, "after": "![x](https://github.com/user-attachments/assets/1)"}
        with patch.object(MODULE, "run_playwright_json", return_value=payload) as runner:
            result = MODULE.perform_upload(Path("/tmp/run"), staged, timeout_ms=5000)

        call_args = runner.call_args.args[0]
        self.assertEqual(call_args[:2], ["--raw", "run-code"])
        self.assertIn(staged.staged_name, call_args[2])
        self.assertEqual(result, payload)

    def test_perform_upload_raises_when_playwright_returns_error(self) -> None:
        staged = MODULE.StagedFile(
            source_path=Path("/tmp/source.md"),
            staged_path=Path("/tmp/run/uploads/source--deadbeef.md"),
            staged_name="source--deadbeef.md",
        )
        with patch.object(MODULE, "run_playwright_json", return_value={"ok": False, "error": "bad-upload"}):
            with self.assertRaises(SystemExit) as context:
                MODULE.perform_upload(Path("/tmp/run"), staged, timeout_ms=5000)

        self.assertIn("Upload failed for source--deadbeef.md", str(context.exception))

    def test_upload_files_collects_attachment_urls(self) -> None:
        first = MODULE.StagedFile(
            source_path=Path("/tmp/source-1.md"),
            staged_path=Path("/tmp/run/uploads/source-1--deadbeef.md"),
            staged_name="source-1--deadbeef.md",
        )
        second = MODULE.StagedFile(
            source_path=Path("/tmp/source-2.md"),
            staged_path=Path("/tmp/run/uploads/source-2--deadbeef.md"),
            staged_name="source-2--deadbeef.md",
        )
        upload_results = [
            {"after": f"[{first.staged_name}](https://github.com/user-attachments/assets/1)"},
            {"after": f"[{second.staged_name}](https://github.com/user-attachments/assets/2)"},
        ]
        snapshots = [
            "",
            "",
            "",
            "",
        ]
        with (
            patch.object(MODULE, "get_composer_markdown", side_effect=["", ""]),
            patch.object(MODULE, "capture_snapshot", side_effect=snapshots),
            patch.object(MODULE, "perform_upload", side_effect=upload_results),
        ):
            attachments = MODULE.upload_files(Path("/tmp/run"), [first, second], timeout_ms=5000)

        self.assertEqual(
            attachments,
            [
                (first, "https://github.com/user-attachments/assets/1"),
                (second, "https://github.com/user-attachments/assets/2"),
            ],
        )

    def test_upload_files_raises_when_attachment_url_is_missing(self) -> None:
        staged = MODULE.StagedFile(
            source_path=Path("/tmp/source.md"),
            staged_path=Path("/tmp/run/uploads/source--deadbeef.md"),
            staged_name="source--deadbeef.md",
        )
        with (
            patch.object(MODULE, "get_composer_markdown", return_value=""),
            patch.object(MODULE, "capture_snapshot", return_value=""),
            patch.object(MODULE, "perform_upload", return_value={"after": "no attachment here"}),
        ):
            with self.assertRaises(SystemExit) as context:
                MODULE.upload_files(Path("/tmp/run"), [staged], timeout_ms=5000)

        self.assertIn("Failed to find an attachment URL", str(context.exception))

    def test_get_composer_markdown_returns_stringified_value(self) -> None:
        with patch.object(MODULE, "run_playwright_value", return_value=123):
            self.assertEqual(MODULE.get_composer_markdown(Path("/tmp/run")), "123")

    def test_capture_snapshot_returns_stdout(self) -> None:
        completed = subprocess.CompletedProcess(["npx"], 0, stdout="snapshot text", stderr="")
        with patch.object(MODULE, "run_playwright", return_value=completed):
            self.assertEqual(MODULE.capture_snapshot(Path("/tmp/run")), "snapshot text")

    def test_run_playwright_json_returns_mapping_only_for_objects(self) -> None:
        with patch.object(MODULE, "run_playwright_value", return_value={"ok": True}):
            self.assertEqual(MODULE.run_playwright_json(["snapshot"], Path("/tmp/run")), {"ok": True})
        with patch.object(MODULE, "run_playwright_value", return_value="not-a-dict"):
            self.assertEqual(MODULE.run_playwright_json(["snapshot"], Path("/tmp/run")), {})

    def test_run_playwright_value_handles_empty_and_json_stdout(self) -> None:
        empty = subprocess.CompletedProcess(["npx"], 0, stdout="   ", stderr="")
        payload = subprocess.CompletedProcess(["npx"], 0, stdout=json.dumps({"ok": True}), stderr="")
        with patch.object(MODULE, "run_playwright", return_value=empty):
            self.assertEqual(MODULE.run_playwright_value(["snapshot"], Path("/tmp/run")), "")
        with patch.object(MODULE, "run_playwright", return_value=payload):
            self.assertEqual(MODULE.run_playwright_value(["snapshot"], Path("/tmp/run")), {"ok": True})

    def test_run_playwright_delegates_to_run(self) -> None:
        with patch.object(MODULE, "run", return_value="result") as run_mock:
            result = MODULE.run_playwright(["snapshot"], Path("/tmp/run"))

        run_mock.assert_called_once_with(["npx", "@playwright/cli", "snapshot"], cwd=Path("/tmp/run"))
        self.assertEqual(result, "result")

    def test_run_passes_expected_subprocess_options(self) -> None:
        completed = subprocess.CompletedProcess(["echo", "ok"], 0, stdout="ok", stderr="")
        with patch.object(MODULE.subprocess, "run", return_value=completed) as run_mock:
            result = MODULE.run(["echo", "ok"], cwd=Path("/tmp/run"))

        self.assertEqual(result, completed)
        kwargs = run_mock.call_args.kwargs
        self.assertEqual(run_mock.call_args.args[0], ["echo", "ok"])
        self.assertEqual(kwargs["cwd"], "/tmp/run")
        self.assertTrue(kwargs["check"])
        self.assertTrue(kwargs["capture_output"])
        self.assertTrue(kwargs["text"])
        self.assertIn("PATH", kwargs["env"])


class MainTests(unittest.TestCase):
    def test_script_formats_called_process_error_message(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_path = Path(tmpdir)
            source_path = tmp_path / "report.md"
            source_path.write_text("payload", encoding="utf-8")

            fake_npx = tmp_path / "npx"
            fake_npx.write_text("#!/bin/sh\necho boom >&2\nexit 42\n", encoding="utf-8")
            fake_npx.chmod(0o755)

            env = dict(MODULE.os.environ)
            env["PATH"] = f"{tmp_path}:{env['PATH']}"
            env["PYTHONDONTWRITEBYTECODE"] = "1"

            result = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT_PATH),
                    "--url",
                    "https://github.com/owner/repo/pull/1",
                    str(source_path),
                ],
                cwd=tmpdir,
                capture_output=True,
                text=True,
                env=env,
            )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Command failed: npx @playwright/cli open", result.stderr)
        self.assertIn("stderr:", result.stderr)
        self.assertIn("boom", result.stderr)

    def test_main_runs_full_flow_and_cleans_up_run_dir(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_path = Path(tmpdir)
            source_path = tmp_path / "docs" / "report.md"
            source_path.parent.mkdir()
            source_path.write_text("payload", encoding="utf-8")

            run_dir = tmp_path / ".playwright-cli" / "gh-comment-attach-files" / "run-20260416-000000"
            staged = MODULE.StagedFile(
                source_path=source_path.resolve(),
                staged_path=run_dir / "uploads" / "report--deadbeef.md",
                staged_name="report--deadbeef.md",
            )
            args = SimpleNamespace(
                url="https://github.com/owner/repo/pull/1",
                repo="owner/repo",
                issue=None,
                pr=1,
                browser="chrome",
                profile_dir=".profiles/test",
                ready_timeout=5,
                poll_interval=0.5,
                leave_open=False,
                keep_run_dir=False,
                files=[str(source_path)],
            )

            fake_now = SimpleNamespace(strftime=lambda _: "20260416-000000")
            fake_datetime = SimpleNamespace(now=lambda: fake_now)

            with (
                patch.object(MODULE, "parse_args", return_value=args),
                patch.object(MODULE.Path, "cwd", return_value=tmp_path),
                patch.object(MODULE, "datetime", fake_datetime),
                patch.object(MODULE, "ensure_command") as ensure_command_mock,
                patch.object(MODULE, "resolve_target_url", return_value=args.url),
                patch.object(MODULE, "stage_files", return_value=[staged]),
                patch.object(MODULE, "open_browser") as open_browser_mock,
                patch.object(MODULE, "wait_for_comment_composer") as wait_mock,
                patch.object(MODULE, "upload_files", return_value=[(staged, "https://github.com/user-attachments/assets/1")]),
                patch.object(MODULE, "close_browser") as close_browser_mock,
                patch.object(MODULE.shutil, "rmtree") as rmtree_mock,
                patch("builtins.print") as print_mock,
            ):
                exit_code = MODULE.main()

        self.assertEqual(exit_code, 0)
        self.assertEqual(ensure_command_mock.call_args_list[0].args, ("npx",))
        self.assertEqual(ensure_command_mock.call_args_list[1].args, ("gh",))
        open_browser_mock.assert_called_once()
        wait_mock.assert_called_once_with(run_dir, 5, 0.5)
        close_browser_mock.assert_called_once_with(run_dir)
        rmtree_mock.assert_called_once_with(run_dir, ignore_errors=True)

        payload = json.loads(print_mock.call_args.args[0])
        self.assertEqual(payload["target_url"], args.url)
        self.assertEqual(payload["attachments"][0]["staged_name"], staged.staged_name)

    def test_main_skips_cleanup_when_leave_open_is_requested(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_path = Path(tmpdir)
            source_path = tmp_path / "report.md"
            source_path.write_text("payload", encoding="utf-8")

            run_dir = tmp_path / ".playwright-cli" / "gh-comment-attach-files" / "run-20260416-000001"
            staged = MODULE.StagedFile(
                source_path=source_path.resolve(),
                staged_path=run_dir / "uploads" / "report--deadbeef.md",
                staged_name="report--deadbeef.md",
            )
            args = SimpleNamespace(
                url="https://github.com/owner/repo/pull/1",
                repo=None,
                issue=None,
                pr=None,
                browser=None,
                profile_dir=".profiles/test",
                ready_timeout=5,
                poll_interval=0.5,
                leave_open=True,
                keep_run_dir=False,
                files=[str(source_path)],
            )

            fake_now = SimpleNamespace(strftime=lambda _: "20260416-000001")
            fake_datetime = SimpleNamespace(now=lambda: fake_now)

            with (
                patch.object(MODULE, "parse_args", return_value=args),
                patch.object(MODULE.Path, "cwd", return_value=tmp_path),
                patch.object(MODULE, "datetime", fake_datetime),
                patch.object(MODULE, "ensure_command"),
                patch.object(MODULE, "resolve_target_url", return_value=args.url),
                patch.object(MODULE, "stage_files", return_value=[staged]),
                patch.object(MODULE, "open_browser"),
                patch.object(MODULE, "wait_for_comment_composer"),
                patch.object(MODULE, "upload_files", return_value=[(staged, "https://github.com/user-attachments/assets/1")]),
                patch.object(MODULE, "close_browser") as close_browser_mock,
                patch.object(MODULE.shutil, "rmtree") as rmtree_mock,
                patch("builtins.print"),
            ):
                MODULE.main()

        close_browser_mock.assert_not_called()
        rmtree_mock.assert_not_called()


if __name__ == "__main__":
    unittest.main()
