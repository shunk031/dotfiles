#!/usr/bin/env python3
"""Block non-Japanese final replies from the Meta Claude session."""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import unicodedata

BLOCK_REASON = "Reply to the user in Japanese; rewrite the whole reply in Japanese."
PANE_PATTERN = re.compile(r"^[A-Za-z0-9_-]+:[A-Za-z0-9_-]+$")
FENCE_OPEN = re.compile(r"^ {0,3}(`{3,}|~{3,})(.*)$")
FENCE_CLOSE = re.compile(r"^ {0,3}(`+|~+)[ \t]*$")
INLINE_CODE = re.compile(r"(?<!`)(`+)(?!`)[\s\S]*?(?<!`)\1(?!`)")
URL = re.compile(
    r"\b(?:[A-Za-z][A-Za-z0-9+.-]*://|mailto:|www\.)[^\s<>]+", re.IGNORECASE
)
UNIX_PATH = re.compile(r"(?<![\w:])(?:~|\.{1,2})?/(?:[^\s<>\"'`]+)")
WINDOWS_PATH = re.compile(r"\b[A-Za-z]:\\(?:[^\\\s<>\"'`]+\\?)+")
RELATIVE_PATH = re.compile(
    r"(?<![\w./-])(?:\.\.?/|[A-Za-z0-9_.-]+/)+[A-Za-z0-9_.-]+"
    r"(?:\.[A-Za-z0-9_.-]+)*(?![\w./-])"
)
FILE_NAME = re.compile(
    r"(?<![\w./-])[A-Za-z0-9_.-]+\.(?:py|sh|md|txt|json|jsonl|toml|yaml|yml|"
    r"ini|cfg|conf|html|css|js|ts|tsx|jsx|go|rs|rb|java|c|cc|cpp|h|hpp)(?![\w./-])",
    re.IGNORECASE,
)
COMMAND_LINE = re.compile(
    r"^\s*(?:(?:[-*+]\s+|\d+[.)]\s+))?(?:(?:\$|%|❯|➜)\s*)?"
    r"(?:command|sudo|env|export|set|source|exec|git|gh|make|pytest|"
    r"python(?:\d+(?:\.\d+)*)?|uv|mise|npm|npx|node|bash|zsh|sh|cat|sed|"
    r"awk|rg|grep|find|ls|cd|pwd|date|curl|wget|jq|brew|docker|ssh|scp|op|"
    r"chmod|chown|mkdir|rm|cp|mv|touch|printf|echo|tar|zip|unzip|pip|pipx|"
    r"go|cargo|rustc|gcc|herdr(?:-[a-z0-9-]+)*)(?:\s|$)",
    re.IGNORECASE,
)
META_AGENT_LIST_TIMEOUT = 3


def remove_verbatim_markers(text: str) -> str:
    return re.sub(
        r"(?s)---BEGIN---.*?(?:---END---|\Z)",
        " ",
        text,
    )


def remove_fenced_code(text: str) -> str:
    visible: list[str] = []
    fence: tuple[str, int] | None = None
    for line in text.splitlines():
        if fence:
            closing = FENCE_CLOSE.fullmatch(line)
            if (
                closing
                and closing.group(1)[0] == fence[0]
                and len(closing.group(1)) >= fence[1]
            ):
                fence = None
            continue

        opening = FENCE_OPEN.match(line)
        if opening and (opening.group(1)[0] != "`" or "`" not in opening.group(2)):
            fence = (opening.group(1)[0], len(opening.group(1)))
            continue
        visible.append(line)
    return "\n".join(visible)


def visible_prose(message: str) -> str:
    text = remove_fenced_code(remove_verbatim_markers(message))
    text = INLINE_CODE.sub(" ", text)
    text = URL.sub(" ", text)
    text = UNIX_PATH.sub(" ", text)
    text = WINDOWS_PATH.sub(" ", text)
    text = RELATIVE_PATH.sub(" ", text)
    text = FILE_NAME.sub(" ", text)
    return "\n".join(
        line for line in text.splitlines() if not COMMAND_LINE.match(line)
    )


def is_japanese_letter(character: str) -> bool:
    if not character.isalpha():
        return False
    codepoint = ord(character)
    if (
        0x3040 <= codepoint <= 0x30FF
        or 0x31F0 <= codepoint <= 0x31FF
        or 0xFF66 <= codepoint <= 0xFF9D
    ):
        return True
    name = unicodedata.name(character, "")
    return name.startswith(
        ("HIRAGANA", "KATAKANA", "CJK UNIFIED IDEOGRAPH", "CJK COMPATIBILITY IDEOGRAPH")
    )


def should_block(message: str) -> bool:
    letters = [character for character in visible_prose(message) if character.isalpha()]
    if len(letters) < 40:
        return False
    japanese = sum(is_japanese_letter(character) for character in letters)
    return japanese * 10 < len(letters) * 3


def unique_object(pairs: list[tuple[str, object]]) -> dict[str, object]:
    result = dict(pairs)
    if len(result) != len(pairs):
        raise ValueError("duplicate JSON key")
    return result


def reject_constant(value: str) -> None:
    raise ValueError(f"invalid JSON constant {value}")


def evaluate(payload: object) -> dict[str, str] | None:
    if not isinstance(payload, dict) or payload.get("hook_event_name") != "Stop":
        return None
    if payload.get("stop_hook_active") is True:
        return None
    message = payload.get("last_assistant_message")
    if isinstance(message, str) and should_block(message):
        return {"decision": "block", "reason": BLOCK_REASON}
    return None


def is_meta_session() -> bool:
    if os.environ.get("HERDR_ENV") != "1":
        return False
    pane_id = os.environ.get("HERDR_PANE_ID", "")
    if not PANE_PATTERN.fullmatch(pane_id):
        return False
    try:
        result = subprocess.run(
            ["herdr", "agent", "list"],
            capture_output=True,
            check=False,
            text=True,
            timeout=META_AGENT_LIST_TIMEOUT,
        )
        if result.returncode != 0:
            return False
        document = json.loads(
            result.stdout,
            object_pairs_hook=unique_object,
            parse_constant=reject_constant,
        )
        agents = document.get("result", {}).get("agents")
        if not isinstance(agents, list):
            return False
        pane_rows = [
            row for row in agents if isinstance(row, dict) and row.get("pane_id") == pane_id
        ]
        return len(pane_rows) == 1 and pane_rows[0].get("name") == "meta"
    except Exception:
        return False


def main() -> None:
    try:
        payload = json.loads(sys.stdin.read(), parse_constant=reject_constant)
        if (
            not isinstance(payload, dict)
            or payload.get("hook_event_name") != "Stop"
            or payload.get("stop_hook_active") is True
        ):
            return
        result = evaluate(payload) if is_meta_session() else None
        if result is not None:
            print(json.dumps(result, ensure_ascii=False, separators=(",", ":")))
    except Exception:
        return


if __name__ == "__main__":
    main()
