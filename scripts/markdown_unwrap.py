#!/usr/bin/env python3

"""Join accidental Markdown soft wraps without inserting spaces into CJK text."""

from __future__ import annotations

import argparse
import re
import sys
import unicodedata
from dataclasses import dataclass
from pathlib import Path

_HEADING_RE = re.compile(r"^ {0,3}#{1,6}(?:[ \t]+|$)")
_LIST_RE = re.compile(
    r"^(?P<indent> {0,3})(?:[*+-]|\d{1,9}[.)])(?:[ \t]+(?P<content>.*)|$)"
)
_LINK_REFERENCE_RE = re.compile(r"^ {0,3}\[[^\]]+\]:[ \t]+")
_TABLE_CELL_RE = re.compile(r"^:?-{3,}:?$")
_HTML_START_RE = re.compile(
    r"^ {0,3}(?:<!--|<\?|<!\[CDATA\[|<![A-Z]|"
    r"</?(?:address|article|aside|base|blockquote|body|caption|center|col|"
    r"colgroup|dd|details|dialog|dir|div|dl|dt|fieldset|figcaption|figure|"
    r"footer|form|h[1-6]|head|header|hr|html|iframe|legend|li|link|main|"
    r"menu|menuitem|nav|ol|p|pre|script|section|summary|table|tbody|td|"
    r"tfoot|th|thead|title|tr|track|ul)(?:[ >]|$))",
    re.IGNORECASE,
)
_HTML_CLOSE_RE = re.compile(r"(?:</[A-Za-z][^>]*>|-->|\?>)\s*$")
_BREAK_TAG_RE = re.compile(r"<br\s*/?>\s*$", re.IGNORECASE)
_SENTENCE_END = frozenset("。！？.!?")
_CLOSING_AFTER_SENTENCE = frozenset("」』】》〉〕］）｝\"'”’")
_CJK_RE = re.compile(
    r"[\u1100-\u11ff\u2e80-\u2fff\u3000-\u303f\u3040-\u30ff"
    r"\u3130-\u318f\u31a0-\u31bf\u3200-\u32ff\u3400-\u4dbf"
    r"\u4e00-\u9fff\ua960-\ua97f\uac00-\ud7ff\uf900-\ufaff"
    r"\ufe10-\ufe1f\ufe30-\ufe4f\uff00-\uffef"
    r"\U00020000-\U0002ffff\U00030000-\U0003ffff]"
)
_MARKDOWN_STRUCTURAL_END = frozenset("*_~`#>|+-=[](){}\\")


@dataclass(frozen=True)
class _LineContext:
    body: str
    quote_depth: int
    list_indent: int | None
    list_content: str | None


@dataclass(frozen=True)
class HardWrap:
    """A CJK continuation split by a Markdown soft line break."""

    line_number: int
    excerpt: str


def is_cjk(character: str) -> bool:
    """Return whether one character belongs to a CJK writing system or block."""
    return bool(character) and _CJK_RE.fullmatch(character) is not None


def _split_quote_prefix(line: str) -> tuple[str, str, int]:
    match = re.match(r"^( {0,3}(?:>[ \t]?)+)", line)
    if match is None:
        return "", line, 0
    prefix = match.group(1)
    return prefix, line[len(prefix) :], prefix.count(">")


def _line_context(line: str) -> _LineContext:
    _prefix, body, quote_depth = _split_quote_prefix(line)
    match = _LIST_RE.match(body)
    if match is None:
        return _LineContext(body, quote_depth, None, None)
    return _LineContext(
        body,
        quote_depth,
        len(match.group("indent")),
        match.group("content") or "",
    )


def _fence_start(line: str) -> tuple[str, int] | None:
    match = re.match(r"^ {0,3}(?P<run>`{3,}|~{3,})", line)
    if match is None:
        return None
    run = match.group("run")
    return run[0], len(run)


def _fence_end(line: str, marker: tuple[str, int]) -> bool:
    char, length = marker
    return re.match(rf"^ {{0,3}}{re.escape(char)}{{{length},}}[ \t]*$", line)


def _is_indented_code(context: _LineContext) -> bool:
    return context.body.startswith("\t") or context.body.startswith("    ")


def _is_thematic_break(line: str) -> bool:
    content = line.strip()
    return (
        bool(content)
        and (
            re.fullmatch(r"(?:\*\s*){3,}", content) is not None
            or re.fullmatch(r"(?:-\s*){3,}", content) is not None
            or re.fullmatch(r"(?:_\s*){3,}", content) is not None
        )
    )


def _is_table_delimiter(line: str) -> bool:
    content = line.strip()
    if content.startswith("|"):
        content = content[1:]
    if content.endswith("|"):
        content = content[:-1]
    cells = [cell.strip() for cell in content.split("|")]
    return len(cells) >= 2 and all(_TABLE_CELL_RE.fullmatch(cell) for cell in cells)


def _could_be_table_row(line: str) -> bool:
    return "|" in line and bool(line.strip())


def _is_html_block_start(line: str) -> bool:
    return _HTML_START_RE.match(line) is not None


def _protected_lines(lines: list[str]) -> set[int]:
    """Return source-line indexes that must not participate in unwrapping."""
    protected: set[int] = set()

    if lines and lines[0].lstrip("\ufeff") == "---":
        for index in range(1, len(lines)):
            if lines[index].strip() in {"---", "..."}:
                protected.update(range(index + 1))
                break

    index = 0
    while index < len(lines):
        if index in protected:
            index += 1
            continue
        marker = _fence_start(lines[index])
        if marker is not None:
            protected.add(index)
            index += 1
            while index < len(lines):
                protected.add(index)
                if _fence_end(lines[index], marker):
                    index += 1
                    break
                index += 1
            continue
        if _is_indented_code(_line_context(lines[index])):
            protected.add(index)
        index += 1

    for index in range(len(lines) - 1):
        if (
            index in protected
            or index + 1 in protected
            or not _could_be_table_row(lines[index])
            or not _is_table_delimiter(lines[index + 1])
        ):
            continue
        row = index
        while row < len(lines) and _could_be_table_row(lines[row]):
            protected.add(row)
            row += 1

    index = 0
    while index < len(lines):
        if index in protected or not _is_html_block_start(lines[index]):
            index += 1
            continue
        while index < len(lines):
            protected.add(index)
            if not lines[index].strip() or _HTML_CLOSE_RE.search(lines[index]):
                index += 1
                break
            index += 1

    return protected


def _has_explicit_break(line: str) -> bool:
    """Return whether a line deliberately requests a Markdown hard break."""
    return (
        line.endswith("  ")
        or _BREAK_TAG_RE.search(line) is not None
        or line.rstrip().endswith("\\")
    )


def _ends_sentence(line: str) -> bool:
    content = _content_for_boundary(line)
    while content and content[-1] in _CLOSING_AFTER_SENTENCE:
        content = content[:-1]
    return bool(content) and content[-1] in _SENTENCE_END


def _is_block_boundary(line: str) -> bool:
    context = _line_context(line)
    return (
        _HEADING_RE.match(context.body) is not None
        or _is_thematic_break(context.body)
        or _LINK_REFERENCE_RE.match(context.body) is not None
        or _fence_start(context.body) is not None
    )


def _can_join(left: str, right: str, right_index: int, protected: set[int]) -> bool:
    if right_index in protected:
        return False
    left_context = _line_context(left)
    right_context = _line_context(right)
    if not left.strip() or not right.strip():
        return False
    if _has_explicit_break(left) or _ends_sentence(left) or _is_block_boundary(left):
        return False
    if _is_block_boundary(right):
        return False
    if left_context.quote_depth != right_context.quote_depth:
        return False
    if _is_indented_code(right_context):
        return False
    if left_context.list_indent is not None:
        if right_context.list_indent is not None:
            return False
        right_indent = len(right_context.body) - len(right_context.body.lstrip(" "))
        return right_indent > left_context.list_indent
    return right_context.list_indent is None


def _content_for_boundary(line: str) -> str:
    context = _line_context(line)
    if context.list_content is not None:
        return context.list_content.strip()
    return context.body.strip()


def _continuation_text(line: str) -> str:
    return _line_context(line).body.lstrip()


def _join_lines(left: str, right: str) -> str:
    left_content = left.rstrip()
    right_content = _continuation_text(right)
    left_boundary = _content_for_boundary(left_content)
    right_boundary = _content_for_boundary(right_content)
    separator = "" if left_boundary and right_boundary and is_cjk(left_boundary[-1]) and is_cjk(right_boundary[0]) else " "
    return f"{left_content}{separator}{right_content}"


def _split_text(text: str) -> tuple[list[str], str, bool]:
    lines = text.splitlines()
    newline = "\r\n" if "\r\n" in text else "\n"
    return lines, newline, text.endswith(("\n", "\r"))


def _render_text(lines: list[str], newline: str, final_newline: bool) -> str:
    rendered = newline.join(lines)
    if final_newline and lines:
        rendered += newline
    return rendered


def unwrap_markdown(text: str) -> str:
    """Join Markdown paragraph continuations while retaining semantic breaks."""
    lines, newline, final_newline = _split_text(text)
    protected = _protected_lines(lines)
    output: list[str] = []
    index = 0
    while index < len(lines):
        line = lines[index]
        next_index = index + 1
        while next_index < len(lines) and _can_join(
            line, lines[next_index], next_index, protected
        ):
            line = _join_lines(line, lines[next_index])
            next_index += 1
        output.append(line)
        index = next_index
    return _render_text(output, newline, final_newline)


def _is_hard_wrap_end(character: str) -> bool:
    return (
        is_cjk(character)
        and character not in _MARKDOWN_STRUCTURAL_END
        and not unicodedata.category(character).startswith("P")
    )


def find_hard_wraps(text: str) -> list[HardWrap]:
    """Find unpunctuated CJK paragraph continuations split across source lines."""
    lines, _newline, _final_newline = _split_text(text)
    protected = _protected_lines(lines)
    findings: list[HardWrap] = []
    for index in range(len(lines) - 1):
        if not _can_join(lines[index], lines[index + 1], index + 1, protected):
            continue
        left = _content_for_boundary(lines[index])
        right = _content_for_boundary(_continuation_text(lines[index + 1]))
        if left and right and _is_hard_wrap_end(left[-1]) and is_cjk(right[0]):
            findings.append(
                HardWrap(
                    line_number=index + 1,
                    excerpt=f"{lines[index]}\n{lines[index + 1]}",
                )
            )
    return findings


def _read_text(path: Path) -> str:
    with path.open("r", encoding="utf-8", newline="") as stream:
        return stream.read()


def _write_text(path: Path, text: str) -> None:
    with path.open("w", encoding="utf-8", newline="") as stream:
        stream.write(text)


def main(argv: list[str] | None = None) -> int:
    """Rewrite the Markdown paths supplied by a pre-commit invocation."""
    parser = argparse.ArgumentParser(
        description="Join accidental Markdown soft wraps without changing code blocks."
    )
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument(
        "--fix",
        action="store_true",
        help="rewrite files in place",
    )
    mode.add_argument(
        "--check",
        action="store_true",
        help="exit nonzero when a file would be rewritten",
    )
    parser.add_argument("paths", nargs="+", type=Path)
    args = parser.parse_args(argv)
    would_change = False
    for path in args.paths:
        try:
            source = _read_text(path)
            rewritten = unwrap_markdown(source)
            if rewritten != source and args.fix:
                _write_text(path, rewritten)
            would_change = would_change or rewritten != source
        except OSError as error:
            print(f"markdown unwrap failed for {path}: {error}", file=sys.stderr)
            return 1
    return 1 if args.check and would_change else 0


if __name__ == "__main__":
    raise SystemExit(main())
