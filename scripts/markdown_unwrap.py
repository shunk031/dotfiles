#!/usr/bin/env python3

"""Run the pinned textlint hybrid that fixes accidental Markdown soft wraps."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[1]
_TEXTLINT_PATH = _REPO_ROOT / "node_modules" / ".bin" / "textlint"
_TEXTLINT_CONFIG_PATH = (
    _REPO_ROOT
    / "home"
    / "dot_config"
    / "textlint"
    / "markdown_unwrap.textlintrc.json"
)
_PROTECTED_BREAK_MARKER = "<!-- markdown-unwrap-protected-break -->"


def _line_body(line: str) -> str:
    if line.endswith("\r\n"):
        return line[:-2]
    if line.endswith(("\n", "\r")):
        return line[:-1]
    return line


def _is_explicit_break(line: str) -> bool:
    body = _line_body(line).rstrip()
    return (
        _line_body(line).endswith("  ")
        or body.endswith("\\")
        or body.lower().endswith(("<br>", "<br/>", "<br />"))
    )


def _protect_explicit_breaks(text: str) -> tuple[str, list[int]]:
    """Separate intentional hard breaks so textlint does not rewrite them."""
    lines = text.splitlines(keepends=True)
    prepared: list[str] = []
    protected_lines: list[int] = []
    for line_number, line in enumerate(lines, start=1):
        prepared.append(line)
        if line_number >= len(lines) or not _is_explicit_break(line):
            continue
        newline = "\r\n" if line.endswith("\r\n") else "\n"
        prepared.extend([newline, f"{_PROTECTED_BREAK_MARKER}{newline}"])
        protected_lines.append(line_number)
    return "".join(prepared), protected_lines


def _restore_explicit_breaks(text: str) -> str:
    for newline in ("\r\n", "\n"):
        text = text.replace(
            f"{newline}{newline}{_PROTECTED_BREAK_MARKER}{newline}", newline
        )
    return text


def _original_line_number(line_number: int, protected_lines: list[int]) -> int:
    return line_number - 2 * sum(line < line_number for line in protected_lines)


def _restore_json_locations(payload: list[object], protected_lines: list[int]) -> None:
    """Map textlint's temporary-file line numbers back to the source file."""
    for result in payload:
        if not isinstance(result, dict):
            continue
        messages = result.get("messages")
        if not isinstance(messages, list):
            continue
        for message in messages:
            if not isinstance(message, dict):
                continue
            line_number = message.get("line")
            if isinstance(line_number, int):
                message["line"] = _original_line_number(line_number, protected_lines)
            location = message.get("loc")
            if not isinstance(location, dict):
                continue
            for side in ("start", "end"):
                point = location.get(side)
                if isinstance(point, dict) and isinstance(point.get("line"), int):
                    point["line"] = _original_line_number(
                        point["line"], protected_lines
                    )


def _run_textlint(
    target: Path, *, fix: bool, as_json: bool
) -> subprocess.CompletedProcess[str]:
    command = [str(_TEXTLINT_PATH), "--config", str(_TEXTLINT_CONFIG_PATH)]
    if as_json:
        command.extend(["--format", "json"])
    if fix:
        command.append("--fix")
    command.append(str(target.resolve()))
    return subprocess.run(
        command,
        cwd=_REPO_ROOT,
        capture_output=as_json,
        text=as_json,
        check=False,
    )


def main(argv: list[str] | None = None) -> int:
    """Run textlint in fix or check mode for the supplied Markdown paths."""
    parser = argparse.ArgumentParser(
        description="Fix or check Markdown soft wraps with the pinned textlint rules."
    )
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--fix", action="store_true", help="rewrite files in place")
    mode.add_argument(
        "--check", action="store_true", help="exit nonzero when a file would be rewritten"
    )
    parser.add_argument(
        "--json", action="store_true", help="emit textlint's machine-readable output"
    )
    parser.add_argument("paths", nargs="+", type=Path)
    args = parser.parse_args(argv)
    if not _TEXTLINT_PATH.is_file():
        print(
            "markdown unwrap requires the repo-local textlint dependencies; "
            "run `make setup` from the dotfiles checkout first",
            file=sys.stderr,
        )
        return 2
    if not _TEXTLINT_CONFIG_PATH.is_file():
        print(
            f"markdown unwrap config is missing: {_TEXTLINT_CONFIG_PATH}",
            file=sys.stderr,
        )
        return 2

    overall_status = 0
    json_results: list[object] = []
    with tempfile.TemporaryDirectory(prefix="markdown-unwrap-") as tempdir:
        for index, path in enumerate(args.paths):
            try:
                source = path.read_text(encoding="utf-8")
            except OSError as error:
                print(f"markdown unwrap failed for {path}: {error}", file=sys.stderr)
                return 2
            prepared, protected_lines = _protect_explicit_breaks(source)
            target = path
            if prepared != source:
                target = Path(tempdir) / f"document-{index}.md"
                target.write_text(prepared, encoding="utf-8")
            try:
                completed = _run_textlint(target, fix=args.fix, as_json=args.json)
            except OSError as error:
                print(f"markdown unwrap failed: {error}", file=sys.stderr)
                return 2
            overall_status = max(overall_status, completed.returncode)
            if args.json:
                try:
                    result = json.loads(completed.stdout)
                except json.JSONDecodeError as error:
                    detail = (completed.stderr or completed.stdout).strip()
                    print(
                        "markdown unwrap failed: textlint returned invalid JSON"
                        + (f": {detail}" if detail else ""),
                        file=sys.stderr,
                    )
                    return 2
                if not isinstance(result, list):
                    print(
                        "markdown unwrap failed: textlint returned non-list JSON",
                        file=sys.stderr,
                    )
                    return 2
                _restore_json_locations(result, protected_lines)
                json_results.extend(result)
            if args.fix and target != path and completed.returncode in {0, 1}:
                try:
                    path.write_text(
                        _restore_explicit_breaks(target.read_text(encoding="utf-8")),
                        encoding="utf-8",
                    )
                except OSError as error:
                    print(f"markdown unwrap failed for {path}: {error}", file=sys.stderr)
                    return 2
    if args.json:
        print(json.dumps(json_results, ensure_ascii=False))
    return overall_status


if __name__ == "__main__":
    raise SystemExit(main())
