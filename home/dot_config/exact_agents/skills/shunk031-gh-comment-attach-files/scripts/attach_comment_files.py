#!/usr/bin/env python3
"""Attach local files to a GitHub comment draft and return hosted URLs."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import time
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Sequence

TEXTAREA_SELECTORS = [
    "textarea#new_comment_field",
    "textarea#pull_request_review_body",
    "textarea[name='comment[body]']",
    "textarea[name='pull_request_review[body]']",
    "textarea.js-comment-field",
]

FILE_INPUT_SELECTORS = [
    "file-attachment input[type='file']",
    "input.js-upload-markdown-image[type='file']",
    "input[type='file'][data-upload-policy-url]",
    "input[type='file'][multiple]",
]

ATTACHMENT_URL_HINTS = ("/user-attachments/", "/attachments/")
MARKDOWN_LINK_RE = re.compile(r"!?\[(?P<label>[^\]]*)\]\((?P<url>https?://[^)\s]+)\)")

PREPARE_COMPOSER_CODE = """
async (page) => {
  const payload = __PAYLOAD__;
  return await page.evaluate(({ textareaSelectors, inputSelectors }) => {
    const visible = (element) => {
      if (!element) return false;
      const style = window.getComputedStyle(element);
      if (!style) return false;
      if (style.visibility === "hidden" || style.display === "none") return false;
      return element.offsetWidth > 0 || element.offsetHeight > 0 || element.getClientRects().length > 0;
    };

    for (const element of document.querySelectorAll("[data-gh-comment-attach]")) {
      element.removeAttribute("data-gh-comment-attach");
    }

    const textareaCandidates = [];
    for (const selector of textareaSelectors) {
      textareaCandidates.push(...document.querySelectorAll(selector));
    }

    const seen = new Set();
    const textareas = textareaCandidates.filter((element) => {
      if (seen.has(element)) return false;
      seen.add(element);
      return visible(element);
    });

    for (const textarea of textareas) {
      const roots = [
        textarea.closest("form"),
        textarea.closest(".previewable-comment-form"),
        textarea.closest(".js-previewable-comment-form"),
        document,
      ].filter(Boolean);

      let input = null;
      for (const root of roots) {
        for (const selector of inputSelectors) {
          input = Array.from(root.querySelectorAll(selector)).find(
            (element) => element instanceof HTMLInputElement,
          );
          if (input) break;
        }
        if (input) break;
      }

      if (!input) continue;

      textarea.setAttribute("data-gh-comment-attach", "textarea");
      input.setAttribute("data-gh-comment-attach", "input");
      textarea.scrollIntoView({ block: "center" });
      return {
        found: true,
        pageTitle: document.title,
        pageUrl: window.location.href,
      };
    }

    return {
      found: false,
      pageTitle: document.title,
      pageUrl: window.location.href,
    };
  }, payload);
}
""".strip()

UPLOAD_CODE_TEMPLATE = """
async (page) => {
  const payload = __PAYLOAD__;
  const prepared = await page.evaluate(({ textareaSelectors, inputSelectors }) => {
    const visible = (element) => {
      if (!element) return false;
      const style = window.getComputedStyle(element);
      if (!style) return false;
      if (style.visibility === "hidden" || style.display === "none") return false;
      return element.offsetWidth > 0 || element.offsetHeight > 0 || element.getClientRects().length > 0;
    };

    for (const element of document.querySelectorAll("[data-gh-comment-attach]")) {
      element.removeAttribute("data-gh-comment-attach");
    }

    const textareaCandidates = [];
    for (const selector of textareaSelectors) {
      textareaCandidates.push(...document.querySelectorAll(selector));
    }

    const seen = new Set();
    const textareas = textareaCandidates.filter((element) => {
      if (seen.has(element)) return false;
      seen.add(element);
      return visible(element);
    });

    for (const textarea of textareas) {
      const roots = [
        textarea.closest("form"),
        textarea.closest(".previewable-comment-form"),
        textarea.closest(".js-previewable-comment-form"),
        document,
      ].filter(Boolean);

      let input = null;
      for (const root of roots) {
        for (const selector of inputSelectors) {
          input = Array.from(root.querySelectorAll(selector)).find(
            (element) => element instanceof HTMLInputElement,
          );
          if (input) break;
        }
        if (input) break;
      }

      if (!input) continue;

      textarea.setAttribute("data-gh-comment-attach", "textarea");
      input.setAttribute("data-gh-comment-attach", "input");
      return { found: true };
    }

    return { found: false };
  }, { textareaSelectors: payload.textareaSelectors, inputSelectors: payload.inputSelectors });

  if (!prepared.found) {
    return {
      ok: false,
      error: "comment-composer-not-found",
      pageTitle: await page.title(),
      pageUrl: page.url(),
    };
  }

  const textarea = page.locator("[data-gh-comment-attach='textarea']").first();
  const input = page.locator("[data-gh-comment-attach='input']").first();
  const before = await textarea.inputValue();

  await input.setInputFiles(payload.filePath);

  await page.waitForFunction(
    ({ selector, previous, stagedName, urlHints }) => {
      const element = document.querySelector(selector);
      if (!(element instanceof HTMLTextAreaElement)) return false;
      const value = element.value || "";
      if (value === previous) return false;
      // Count URL hint occurrences rather than checking stagedName, which would
      // falsely trigger on the "![Uploading stagedName…]()" placeholder GitHub
      // inserts before the real URL is assigned.
      const countHints = (text) => urlHints.reduce(
        (sum, h) => sum + (text.split(h).length - 1), 0
      );
      return countHints(value) > countHints(previous);
    },
    {
      selector: "[data-gh-comment-attach='textarea']",
      previous: before,
      stagedName: payload.stagedName,
      urlHints: payload.urlHints,
    },
    { timeout: payload.timeoutMs },
  );

  const after = await textarea.inputValue();
  return {
    ok: true,
    before,
    after,
    pageTitle: await page.title(),
    pageUrl: page.url(),
  };
}
""".strip()


@dataclass(frozen=True)
class StagedFile:
    """Map one source file to its staged upload path and generated name."""

    source_path: Path
    staged_path: Path
    staged_name: str


def parse_args() -> argparse.Namespace:
    """Parse CLI arguments and validate target selection combinations."""

    parser = argparse.ArgumentParser(
        description="Attach files to a GitHub issue or pull request comment and return hosted URLs.",
    )
    target_group = parser.add_mutually_exclusive_group(required=True)
    target_group.add_argument("--url", help="Direct issue or pull request URL")
    target_group.add_argument("--repo", help="GitHub repo in [HOST/]OWNER/REPO form")

    issue_pr_group = parser.add_mutually_exclusive_group()
    issue_pr_group.add_argument(
        "--issue", type=int, help="Issue number to resolve with gh"
    )
    issue_pr_group.add_argument(
        "--pr", type=int, help="Pull request number to resolve with gh"
    )

    parser.add_argument(
        "--browser",
        choices=["chrome", "firefox", "webkit", "msedge"],
        help="Browser or channel passed to Playwright CLI",
    )
    parser.add_argument(
        "--profile-dir",
        default=".playwright-cli/gh-comment-attach-files/profile",
        help="Persistent Playwright CLI profile directory (default: %(default)s)",
    )
    parser.add_argument(
        "--ready-timeout",
        type=int,
        default=180,
        help="Seconds to wait for a usable GitHub comment composer (default: %(default)s)",
    )
    parser.add_argument(
        "--poll-interval",
        type=float,
        default=2.0,
        help="Seconds between readiness checks (default: %(default)s)",
    )
    parser.add_argument(
        "--leave-open",
        action="store_true",
        help="Leave the Playwright CLI browser open after collecting URLs",
    )
    parser.add_argument(
        "--headed",
        action="store_true",
        help="Run browser in headed (visible) mode. Use when login is required; headless is the default.",
    )
    parser.add_argument(
        "--keep-run-dir",
        action="store_true",
        help="Keep the staged Playwright run directory under .playwright-cli",
    )
    parser.add_argument(
        "--resume-manifest",
        help=(
            "JSONL manifest used to resume large uploads. Existing source_path "
            "entries are skipped and new successes are appended."
        ),
    )
    parser.add_argument(
        "--sleep-between-files",
        type=float,
        default=0.0,
        help="Seconds to sleep after each successful upload (default: %(default)s)",
    )
    parser.add_argument(
        "--max-files-per-run",
        type=int,
        help="Upload at most this many pending files in one invocation",
    )
    parser.add_argument(
        "files",
        nargs="+",
        help="One or more local files to attach",
    )

    args = parser.parse_args()
    if args.repo and not (args.issue or args.pr):
        parser.error("--repo requires either --issue or --pr")
    if not args.repo and (args.issue or args.pr):
        parser.error("--issue/--pr requires --repo")
    if args.sleep_between_files < 0:
        parser.error("--sleep-between-files must be >= 0")
    if args.max_files_per_run is not None and args.max_files_per_run < 1:
        parser.error("--max-files-per-run must be >= 1")
    return args


def main() -> int:
    """Run the full attachment workflow and print JSON results."""

    args = parse_args()
    ensure_command("npx")
    if args.repo:
        ensure_command("gh")

    source_files = [Path(value).expanduser().resolve() for value in args.files]
    validate_source_files(source_files)

    target_url = resolve_target_url(args)

    base_dir = Path.cwd() / ".playwright-cli" / "gh-comment-attach-files"
    run_dir = base_dir / f"run-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
    uploads_dir = run_dir / "uploads"
    profile_dir = resolve_profile_dir(args.profile_dir)

    uploads_dir.mkdir(parents=True, exist_ok=True)
    profile_dir.mkdir(parents=True, exist_ok=True)

    staged_files = stage_files(source_files, uploads_dir)
    resume_manifest = resolve_optional_path(args.resume_manifest)
    resumed_urls = load_resume_manifest(resume_manifest)
    resumed_attachments, pending_staged_files = partition_staged_files(
        staged_files,
        resumed_urls,
        args.max_files_per_run,
    )

    uploaded_attachments: list[tuple[StagedFile, str]] = []
    if pending_staged_files:
        workflow_failed = False
        try:
            open_browser(
                target_url, run_dir, profile_dir, args.browser, headed=args.headed
            )
            wait_for_comment_composer(
                run_dir, args.ready_timeout, args.poll_interval, headed=args.headed
            )
            uploaded_attachments = upload_files(
                run_dir,
                pending_staged_files,
                timeout_ms=args.ready_timeout * 1000,
                target_url=target_url,
                ready_timeout=args.ready_timeout,
                poll_interval=args.poll_interval,
                profile_dir=profile_dir,
                browser=getattr(args, "browser", None),
                headed=args.headed,
                resume_manifest=resume_manifest,
                sleep_between_files=args.sleep_between_files,
            )
        except BaseException:
            workflow_failed = True
            raise
        finally:
            if not args.leave_open:
                close_browser(run_dir)
            if not workflow_failed and not args.keep_run_dir and not args.leave_open:
                shutil.rmtree(run_dir, ignore_errors=True)
    elif not args.keep_run_dir:
        shutil.rmtree(run_dir, ignore_errors=True)

    attachments = order_completed_attachments(
        staged_files, resumed_attachments + uploaded_attachments
    )
    payload = {
        "target_url": target_url,
        "attachments": [
            {
                "source_path": str(item.source_path),
                "staged_name": item.staged_name,
                "attachment_url": url,
            }
            for item, url in attachments
        ],
    }
    print(json.dumps(payload, ensure_ascii=False, indent=2))
    return 0


def ensure_command(name: str) -> None:
    """Fail fast when a required command is missing from PATH."""

    if shutil.which(name):
        return
    raise SystemExit(f"Required command not found: {name}")


def validate_source_files(source_files: Sequence[Path]) -> None:
    """Ensure each requested upload exists and is a regular file."""

    for path in source_files:
        if not path.exists():
            raise SystemExit(f"File not found: {path}")
        if not path.is_file():
            raise SystemExit(f"Not a file: {path}")


def resolve_target_url(args: argparse.Namespace) -> str:
    """Resolve the target issue or pull request URL from CLI input."""

    if args.url:
        return args.url

    if args.issue:
        command = [
            "gh",
            "issue",
            "view",
            str(args.issue),
            "--repo",
            args.repo,
            "--json",
            "url",
            "--jq",
            ".url",
        ]
    else:
        command = [
            "gh",
            "pr",
            "view",
            str(args.pr),
            "--repo",
            args.repo,
            "--json",
            "url",
            "--jq",
            ".url",
        ]
    return run(command).stdout.strip()


def resolve_profile_dir(profile_dir: str) -> Path:
    """Resolve the Playwright profile directory against the current working tree."""

    candidate = Path(profile_dir).expanduser()
    if candidate.is_absolute():
        return candidate
    return (Path.cwd() / candidate).resolve()


def resolve_optional_path(path: str | None) -> Path | None:
    """Resolve an optional path argument against the current working tree."""

    if path is None:
        return None
    candidate = Path(path).expanduser()
    if candidate.is_absolute():
        return candidate
    return (Path.cwd() / candidate).resolve()


def stage_files(source_files: Sequence[Path], uploads_dir: Path) -> list[StagedFile]:
    """Copy source files into the upload workspace with unique staged names."""

    staged_files: list[StagedFile] = []
    used_names: set[str] = set()
    for source_path in source_files:
        staged_name = build_staged_name(source_path, used_names)
        staged_path = uploads_dir / staged_name
        shutil.copy2(source_path, staged_path)
        staged_files.append(
            StagedFile(
                source_path=source_path,
                staged_path=staged_path,
                staged_name=staged_name,
            )
        )
    return staged_files


def build_staged_name(source_path: Path, used_names: set[str]) -> str:
    """Generate a stable staged filename that stays unique within one run."""

    stem = sanitize_component(source_path.stem) or "attachment"
    suffix = "".join(source_path.suffixes)
    digest = hashlib.sha1(str(source_path).encode("utf-8")).hexdigest()[:8]
    candidate = f"{stem}--{digest}{suffix}"
    counter = 2
    while candidate in used_names:
        candidate = f"{stem}--{digest}-{counter}{suffix}"
        counter += 1
    used_names.add(candidate)
    return candidate


def sanitize_component(value: str) -> str:
    """Normalize a filename fragment for use in staged upload names."""

    sanitized = re.sub(r"[^A-Za-z0-9._-]+", "-", value).strip("-._")
    return sanitized[:80]


def load_resume_manifest(manifest_path: Path | None) -> dict[str, str]:
    """Load previously uploaded attachment URLs from a JSONL resume manifest."""

    if manifest_path is None or not manifest_path.exists():
        return {}

    completed: dict[str, str] = {}
    with manifest_path.open(encoding="utf-8") as manifest:
        for line_number, line in enumerate(manifest, start=1):
            if not line.strip():
                continue
            try:
                entry = json.loads(line)
            except json.JSONDecodeError as exc:
                raise SystemExit(
                    f"Invalid JSON in resume manifest line {line_number}: {manifest_path}"
                ) from exc
            source_path = entry.get("source_path")
            attachment_url = entry.get("attachment_url")
            if not isinstance(source_path, str) or not isinstance(attachment_url, str):
                raise SystemExit(
                    f"Resume manifest line {line_number} must contain source_path and attachment_url: "
                    f"{manifest_path}"
                )
            completed[source_path] = attachment_url
    return completed


def append_resume_manifest(
    manifest_path: Path | None,
    target_url: str,
    staged_file: StagedFile,
    attachment_url: str,
) -> None:
    """Append one successful upload to the resume manifest."""

    if manifest_path is None:
        return

    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    entry = {
        "target_url": target_url,
        "source_path": str(staged_file.source_path),
        "staged_name": staged_file.staged_name,
        "attachment_url": attachment_url,
    }
    with manifest_path.open("a", encoding="utf-8") as manifest:
        manifest.write(json.dumps(entry, ensure_ascii=False) + "\n")


def partition_staged_files(
    staged_files: Sequence[StagedFile],
    resumed_urls: dict[str, str],
    max_files_per_run: int | None,
) -> tuple[list[tuple[StagedFile, str]], list[StagedFile]]:
    """Split staged files into already completed and pending files for this run."""

    resumed_attachments: list[tuple[StagedFile, str]] = []
    pending_staged_files: list[StagedFile] = []
    for staged_file in staged_files:
        attachment_url = resumed_urls.get(str(staged_file.source_path))
        if attachment_url:
            print(
                f"Skipping already uploaded file: {staged_file.source_path}",
                file=sys.stderr,
            )
            resumed_attachments.append((staged_file, attachment_url))
        else:
            pending_staged_files.append(staged_file)

    if max_files_per_run is not None:
        deferred_count = max(0, len(pending_staged_files) - max_files_per_run)
        pending_staged_files = pending_staged_files[:max_files_per_run]
        if deferred_count:
            print(
                f"Deferring {deferred_count} pending file(s) because --max-files-per-run={max_files_per_run}",
                file=sys.stderr,
            )

    return resumed_attachments, pending_staged_files


def order_completed_attachments(
    staged_files: Sequence[StagedFile],
    attachments: Sequence[tuple[StagedFile, str]],
) -> list[tuple[StagedFile, str]]:
    """Return completed attachments in the same order as the input files."""

    urls_by_source_path = {
        str(staged_file.source_path): url for staged_file, url in attachments
    }
    ordered: list[tuple[StagedFile, str]] = []
    for staged_file in staged_files:
        attachment_url = urls_by_source_path.get(str(staged_file.source_path))
        if attachment_url:
            ordered.append((staged_file, attachment_url))
    return ordered


def open_browser(
    target_url: str,
    run_dir: Path,
    profile_dir: Path,
    browser: str | None,
    headed: bool = False,
) -> None:
    """Open the target page in a persistent Playwright CLI browser session."""

    command = [
        "npx",
        "@playwright/cli",
        "open",
        target_url,
        "--profile",
        str(profile_dir),
    ]
    if headed:
        command.append("--headed")
    if browser:
        command.extend(["--browser", browser])
    run(command, cwd=run_dir)


def close_browser(run_dir: Path) -> None:
    """Close the Playwright CLI browser session if it is still running."""

    try:
        run(["npx", "@playwright/cli", "close"], cwd=run_dir)
    except subprocess.CalledProcessError:
        return


def wait_for_comment_composer(
    run_dir: Path,
    ready_timeout: int,
    poll_interval: float,
    headed: bool = False,
) -> None:
    """Poll until a visible GitHub comment composer is ready for uploads."""

    started_at = time.monotonic()
    while True:
        result = prepare_comment_composer(run_dir)
        if result.get("found"):
            return
        page_url = str(result.get("pageUrl", ""))
        if not headed and ("/login" in page_url or "/session" in page_url):
            raise SystemExit(
                f"GitHub login required (redirected to: {page_url})\n"
                "Re-run with --headed to log in, then re-run without --headed for normal headless use."
            )
        if time.monotonic() - started_at >= ready_timeout:
            page_title = str(result.get("pageTitle", ""))
            raise SystemExit(
                f"Timed out waiting for a GitHub comment composer. Last page: {page_title} {page_url}".strip()
            )
        time.sleep(poll_interval)


def prepare_comment_composer(run_dir: Path) -> dict[str, object]:
    """Tag the active comment textarea and file input in the page DOM."""

    payload = {
        "textareaSelectors": TEXTAREA_SELECTORS,
        "inputSelectors": FILE_INPUT_SELECTORS,
    }
    return run_playwright_json(
        [
            "--raw",
            "run-code",
            PREPARE_COMPOSER_CODE.replace("__PAYLOAD__", json.dumps(payload)),
        ],
        cwd=run_dir,
    )


def upload_files(
    run_dir: Path,
    staged_files: Sequence[StagedFile],
    timeout_ms: int,
    target_url: str = "",
    ready_timeout: int = 180,
    poll_interval: float = 2.0,
    profile_dir: Path | None = None,
    browser: str | None = None,
    headed: bool = False,
    resume_manifest: Path | None = None,
    sleep_between_files: float = 0.0,
) -> list[tuple[StagedFile, str]]:
    """Upload staged files one by one and collect their hosted URLs."""

    attachments: list[tuple[StagedFile, str]] = []
    for staged_file in staged_files:
        attachment_url = None
        for attempt in range(1, 4):
            print(
                f"  Upload attempt {attempt}/3 for {staged_file.staged_name}",
                file=sys.stderr,
            )
            try:
                composer_before = get_composer_markdown(run_dir)
                snapshot_before = capture_snapshot(run_dir)
                upload_result = perform_upload(run_dir, staged_file, timeout_ms)
            except subprocess.CalledProcessError as exc:
                print(
                    f"  Upload attempt {attempt}/3 crashed for {staged_file.staged_name}: {exc}",
                    file=sys.stderr,
                )
                if attempt < 3:
                    print("  Waiting 30s, then reopening browser ...", file=sys.stderr)
                    time.sleep(30)
                    if target_url:
                        try:
                            run_playwright(["goto", target_url], cwd=run_dir)
                        except subprocess.CalledProcessError:
                            if profile_dir:
                                open_browser(
                                    target_url,
                                    run_dir,
                                    profile_dir,
                                    browser,
                                    headed=headed,
                                )
                        wait_for_comment_composer(
                            run_dir, ready_timeout, poll_interval, headed=headed
                        )
                continue
            if not upload_result.get("ok"):
                error = upload_result.get("error", "unknown-error")
                print(
                    f"  Upload attempt {attempt}/3 failed for {staged_file.staged_name}: {error}",
                    file=sys.stderr,
                )
                if attempt < 3:
                    print("  Waiting 60s before retry ...", file=sys.stderr)
                    time.sleep(60)
                    if target_url:
                        run_playwright(["goto", target_url], cwd=run_dir)
                        wait_for_comment_composer(
                            run_dir, ready_timeout, poll_interval, headed=headed
                        )
                continue
            composer_after = str(upload_result.get("after", ""))
            snapshot_after = capture_snapshot(run_dir)
            before_url_count = count_attachment_url_hints(
                composer_before + "\n" + snapshot_before
            )
            after_url_count = count_attachment_url_hints(
                composer_after + "\n" + snapshot_after
            )
            page_title = str(upload_result.get("pageTitle", ""))
            page_url = str(upload_result.get("pageUrl", ""))
            print(
                "  Upload attempt "
                f"{attempt}/3 observed URLs {before_url_count}->{after_url_count} "
                f"for {staged_file.staged_name}; page={page_title!r} {page_url}",
                file=sys.stderr,
            )
            attachment_url = find_attachment_url(
                staged_name=staged_file.staged_name,
                before_texts=[composer_before, snapshot_before],
                after_texts=[composer_after, snapshot_after],
            )
            if attachment_url:
                break
            placeholder_remains = has_upload_placeholder(
                composer_after, staged_file.staged_name
            )
            print(
                f"  Attempt {attempt}/3: URL not found for {staged_file.staged_name}; "
                f"upload placeholder remains={placeholder_remains}",
                file=sys.stderr,
            )
            if attempt < 3:
                print("  Waiting 30s before retry ...", file=sys.stderr)
                time.sleep(30)
        if not attachment_url:
            raise SystemExit(
                f"Failed to upload {staged_file.staged_name} after 3 attempts\nRun directory: {run_dir}"
            )
        append_resume_manifest(resume_manifest, target_url, staged_file, attachment_url)
        attachments.append((staged_file, attachment_url))
        if sleep_between_files > 0:
            print(
                f"  Sleeping {sleep_between_files:g}s before next file ...",
                file=sys.stderr,
            )
            time.sleep(sleep_between_files)
    return attachments


def perform_upload(
    run_dir: Path, staged_file: StagedFile, timeout_ms: int
) -> dict[str, object]:
    """Attach one staged file and return the updated composer state."""

    payload = {
        "filePath": str(staged_file.staged_path),
        "stagedName": staged_file.staged_name,
        "timeoutMs": timeout_ms,
        "textareaSelectors": TEXTAREA_SELECTORS,
        "inputSelectors": FILE_INPUT_SELECTORS,
        "urlHints": list(ATTACHMENT_URL_HINTS),
    }
    result = run_playwright_json(
        [
            "--raw",
            "run-code",
            UPLOAD_CODE_TEMPLATE.replace("__PAYLOAD__", json.dumps(payload)),
        ],
        cwd=run_dir,
    )
    return result


def get_composer_markdown(run_dir: Path) -> str:
    """Read the current Markdown contents from the tagged comment textarea."""

    code = """
async (page) => {
  const textarea = page.locator("[data-gh-comment-attach='textarea']").first();
  if ((await textarea.count()) === 0) {
    return "";
  }
  return await textarea.inputValue();
}
""".strip()
    return str(run_playwright_value(["--raw", "run-code", code], cwd=run_dir))


def capture_snapshot(run_dir: Path) -> str:
    """Capture a Playwright CLI snapshot for later diffing and URL discovery."""

    return run_playwright(["snapshot"], cwd=run_dir).stdout


def find_attachment_url(
    staged_name: str, before_texts: Sequence[str], after_texts: Sequence[str]
) -> str | None:
    """Infer the newly inserted attachment URL from before/after page state."""

    before_links = extract_attachment_links("\n".join(before_texts))
    after_links = extract_attachment_links("\n".join(after_texts))

    before_pairs = {(item["label"], item["url"]) for item in before_links}
    after_pairs = [(item["label"], item["url"]) for item in after_links]

    for label, url in after_pairs:
        if label == staged_name and (label, url) not in before_pairs:
            return url

    before_urls = {item["url"] for item in before_links}
    new_urls = [item["url"] for item in after_links if item["url"] not in before_urls]
    if new_urls:
        return new_urls[-1]

    for item in after_links:
        if item["label"] == staged_name:
            return item["url"]
    return None


def count_attachment_url_hints(text: str) -> int:
    """Count GitHub attachment URL hints in arbitrary text."""

    return sum(text.count(hint) for hint in ATTACHMENT_URL_HINTS)


def has_upload_placeholder(text: str, staged_name: str) -> bool:
    """Return whether GitHub's temporary upload placeholder is still present."""

    return f"![Uploading {staged_name}]" in text


def extract_attachment_links(text: str) -> list[dict[str, str]]:
    """Extract GitHub attachment Markdown links from arbitrary text."""

    links: list[dict[str, str]] = []
    for match in MARKDOWN_LINK_RE.finditer(text):
        url = match.group("url")
        if not any(hint in url for hint in ATTACHMENT_URL_HINTS):
            continue
        links.append({"label": match.group("label"), "url": url})
    return links


def run_playwright(
    arguments: Sequence[str], cwd: Path
) -> subprocess.CompletedProcess[str]:
    """Run a Playwright CLI command inside the temporary workspace."""

    return run(["npx", "@playwright/cli", *arguments], cwd=cwd)


def run_playwright_json(arguments: Sequence[str], cwd: Path) -> dict[str, object]:
    """Run Playwright and coerce a JSON object result when available."""

    value = run_playwright_value(arguments, cwd=cwd)
    if isinstance(value, dict):
        return value
    return {}


def run_playwright_value(arguments: Sequence[str], cwd: Path) -> object:
    """Run Playwright and decode its raw JSON-compatible stdout value."""

    result = run_playwright(arguments, cwd=cwd)
    stdout = result.stdout.strip()
    if not stdout or stdout == "undefined":
        return ""
    try:
        return json.loads(stdout)
    except json.JSONDecodeError:
        return ""


def run(
    command: Sequence[str], cwd: Path | None = None
) -> subprocess.CompletedProcess[str]:
    """Run a subprocess with captured text output and inherited environment."""

    return subprocess.run(
        list(command),
        cwd=str(cwd) if cwd else None,
        check=True,
        capture_output=True,
        text=True,
        env=dict(os.environ),
    )


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except subprocess.CalledProcessError as exc:
        command_text = " ".join(exc.cmd)
        stdout = exc.stdout.strip()
        stderr = exc.stderr.strip()
        message = f"Command failed: {command_text}"
        if stdout:
            message += f"\nstdout:\n{stdout}"
        if stderr:
            message += f"\nstderr:\n{stderr}"
        raise SystemExit(message) from exc
