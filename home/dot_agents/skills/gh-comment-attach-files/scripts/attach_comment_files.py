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
      return value.includes(stagedName) || urlHints.some((hint) => value.includes(hint));
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
    issue_pr_group.add_argument("--issue", type=int, help="Issue number to resolve with gh")
    issue_pr_group.add_argument("--pr", type=int, help="Pull request number to resolve with gh")

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
        "--keep-run-dir",
        action="store_true",
        help="Keep the staged Playwright run directory under .playwright-cli",
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

    try:
        open_browser(target_url, run_dir, profile_dir, args.browser)
        wait_for_comment_composer(run_dir, args.ready_timeout, args.poll_interval)
        attachments = upload_files(run_dir, staged_files, timeout_ms=args.ready_timeout * 1000)
    finally:
        if not args.leave_open:
            close_browser(run_dir)
        if not args.keep_run_dir and not args.leave_open:
            shutil.rmtree(run_dir, ignore_errors=True)

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


def open_browser(target_url: str, run_dir: Path, profile_dir: Path, browser: str | None) -> None:
    """Open the target page in a persistent Playwright CLI browser session."""

    command = [
        "npx",
        "@playwright/cli",
        "open",
        target_url,
        "--headed",
        "--profile",
        str(profile_dir),
    ]
    if browser:
        command.extend(["--browser", browser])
    run(command, cwd=run_dir)


def close_browser(run_dir: Path) -> None:
    """Close the Playwright CLI browser session if it is still running."""

    try:
        run(["npx", "@playwright/cli", "close"], cwd=run_dir)
    except subprocess.CalledProcessError:
        return


def wait_for_comment_composer(run_dir: Path, ready_timeout: int, poll_interval: float) -> None:
    """Poll until a visible GitHub comment composer is ready for uploads."""

    started_at = time.monotonic()
    while True:
        result = prepare_comment_composer(run_dir)
        if result.get("found"):
            return
        if time.monotonic() - started_at >= ready_timeout:
            page_url = result.get("pageUrl", "")
            page_title = result.get("pageTitle", "")
            raise SystemExit(
                "Timed out waiting for a GitHub comment composer. "
                f"Last page: {page_title} {page_url}".strip()
            )
        time.sleep(poll_interval)


def prepare_comment_composer(run_dir: Path) -> dict[str, object]:
    """Tag the active comment textarea and file input in the page DOM."""

    payload = {
        "textareaSelectors": TEXTAREA_SELECTORS,
        "inputSelectors": FILE_INPUT_SELECTORS,
    }
    return run_playwright_json(
        ["--raw", "run-code", PREPARE_COMPOSER_CODE.replace("__PAYLOAD__", json.dumps(payload))],
        cwd=run_dir,
    )


def upload_files(run_dir: Path, staged_files: Sequence[StagedFile], timeout_ms: int) -> list[tuple[StagedFile, str]]:
    """Upload staged files one by one and collect their hosted URLs."""

    attachments: list[tuple[StagedFile, str]] = []
    for staged_file in staged_files:
        composer_before = get_composer_markdown(run_dir)
        snapshot_before = capture_snapshot(run_dir)
        upload_result = perform_upload(run_dir, staged_file, timeout_ms)
        composer_after = str(upload_result.get("after", ""))
        snapshot_after = capture_snapshot(run_dir)
        attachment_url = find_attachment_url(
            staged_name=staged_file.staged_name,
            before_texts=[composer_before, snapshot_before],
            after_texts=[composer_after, snapshot_after],
        )
        if not attachment_url:
            raise SystemExit(
                f"Failed to find an attachment URL for staged file: {staged_file.staged_name}"
            )
        attachments.append((staged_file, attachment_url))
    return attachments


def perform_upload(run_dir: Path, staged_file: StagedFile, timeout_ms: int) -> dict[str, object]:
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
        ["--raw", "run-code", UPLOAD_CODE_TEMPLATE.replace("__PAYLOAD__", json.dumps(payload))],
        cwd=run_dir,
    )
    if not result.get("ok"):
        raise SystemExit(
            f"Upload failed for {staged_file.staged_name}: {result.get('error', 'unknown-error')}"
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


def find_attachment_url(staged_name: str, before_texts: Sequence[str], after_texts: Sequence[str]) -> str | None:
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


def extract_attachment_links(text: str) -> list[dict[str, str]]:
    """Extract GitHub attachment Markdown links from arbitrary text."""

    links: list[dict[str, str]] = []
    for match in MARKDOWN_LINK_RE.finditer(text):
        url = match.group("url")
        if not any(hint in url for hint in ATTACHMENT_URL_HINTS):
            continue
        links.append({"label": match.group("label"), "url": url})
    return links


def run_playwright(arguments: Sequence[str], cwd: Path) -> subprocess.CompletedProcess[str]:
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
    if not stdout:
        return ""
    return json.loads(stdout)


def run(command: Sequence[str], cwd: Path | None = None) -> subprocess.CompletedProcess[str]:
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
