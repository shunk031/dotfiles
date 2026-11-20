#!/usr/bin/env python3
"""Block non-Japanese final replies from the Meta Claude session."""

from __future__ import annotations

import fcntl
import hashlib
import json
import os
import re
import subprocess
import sys
import unicodedata
from datetime import datetime
from pathlib import Path

BLOCK_REASON = "Reply to the user in Japanese; rewrite the whole reply in Japanese."
PANE_PATTERN = re.compile(r"^[A-Za-z0-9_-]+:[A-Za-z0-9_-]+$")
FENCE_OPEN = re.compile(r"^ {0,3}(`{3,}|~{3,})(.*)$")
FENCE_CLOSE = re.compile(r"^ {0,3}(`+|~+)[ \t]*$")
INLINE_CODE = re.compile(r"(?<!`)(`+)(?!`)[\s\S]*?(?<!`)\1(?!`)")
URL = re.compile(
    r"(?<![A-Za-z0-9+.-])(?:[A-Za-z][A-Za-z0-9+.-]*://|mailto:|www\.)"
    r"[A-Za-z0-9_.~:/?#\[\]@!$&'()*+,;=%-]+",
    re.IGNORECASE,
)
UNIX_PATH = re.compile(
    r"(?<![A-Za-z0-9_:])(?:~|\.{1,2})?/"
    r"[A-Za-z0-9_.~+-]+(?:/[A-Za-z0-9_.~+-]+)*"
)
WINDOWS_PATH = re.compile(
    r"(?<![A-Za-z0-9_])[A-Za-z]:\\[A-Za-z0-9_.~+-]+"
    r"(?:\\[A-Za-z0-9_.~+-]+)*\\?"
)
RELATIVE_PATH = re.compile(
    r"(?<![A-Za-z0-9_./-])(?:"
    r"(?:\.\.?|~)/[A-Za-z0-9_.-]+(?:/[A-Za-z0-9_.-]+)*"
    r"|[A-Za-z0-9_.-]+/(?:[A-Za-z0-9_.-]+/)*[A-Za-z0-9_.-]+"
    r"\.[A-Za-z0-9]{1,16}"
    r")(?![A-Za-z0-9_./-])",
    re.IGNORECASE,
)
FILE_NAME = re.compile(
    r"(?<![A-Za-z0-9_./-])[A-Za-z0-9_.-]+\.[A-Za-z0-9]{1,16}"
    r"(?![A-Za-z0-9_./-])",
    re.IGNORECASE,
)
META_AGENT_LIST_TIMEOUT = 3
MAX_CONSECUTIVE_BLOCKS = 3
STATE_DIR = Path.home() / ".local" / "state" / "meta"


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
    return text


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


def letter_counts(message: str) -> tuple[int, int]:
    letters = [character for character in visible_prose(message) if character.isalpha()]
    return len(letters), sum(is_japanese_letter(character) for character in letters)


def should_block(message: str) -> bool:
    return should_block_counts(*letter_counts(message))


def should_block_counts(letter_count: int, japanese_letter_count: int) -> bool:
    if letter_count < 40:
        return False
    return japanese_letter_count * 10 < letter_count * 3


def unique_object(pairs: list[tuple[str, object]]) -> dict[str, object]:
    result = dict(pairs)
    if len(result) != len(pairs):
        raise ValueError("duplicate JSON key")
    return result


def reject_constant(value: str) -> None:
    raise ValueError(f"invalid JSON constant {value}")


def read_block_count(counter_path: Path) -> int:
    try:
        state = json.loads(counter_path.read_text(encoding="utf-8"))
        count = state.get("count")
        if type(count) is int and count >= 0:
            return count
    except (OSError, ValueError, AttributeError):
        pass
    return 0


def write_block_count(counter_path: Path, count: int) -> None:
    temporary_path = counter_path.with_name(counter_path.name + ".tmp")
    temporary_path.write_text(
        json.dumps({"count": count}, separators=(",", ":")) + "\n",
        encoding="utf-8",
    )
    os.chmod(temporary_path, 0o600)
    os.replace(temporary_path, counter_path)


def record_decision(
    session_id: object,
    stop_hook_active: bool,
    blocked_by_language: bool,
    letter_count: int,
    japanese_letter_count: int,
) -> bool:
    STATE_DIR.mkdir(mode=0o700, parents=True, exist_ok=True)
    counter_dir = STATE_DIR / "japanese-reply-counters"
    counter_dir.mkdir(mode=0o700, exist_ok=True)
    session_text = session_id if isinstance(session_id, str) else ""
    session_key = hashlib.sha256(session_text.encode("utf-8")).hexdigest()
    counter_path = counter_dir / f"{session_key}.json"
    lock_path = STATE_DIR / "japanese-reply-counter.lock"
    log_path = STATE_DIR / "japanese-reply.log"

    with lock_path.open("a", encoding="utf-8") as lock_file:
        fcntl.flock(lock_file.fileno(), fcntl.LOCK_EX)
        try:
            consecutive_blocks = read_block_count(counter_path)
            if not stop_hook_active:
                consecutive_blocks = 0
            reason = None
            if blocked_by_language and consecutive_blocks < MAX_CONSECUTIVE_BLOCKS:
                decision = "block"
                write_block_count(counter_path, consecutive_blocks + 1)
            elif blocked_by_language:
                decision = "allow"
                reason = "block-limit"
                write_block_count(counter_path, consecutive_blocks)
            else:
                decision = "allow"
                counter_path.unlink(missing_ok=True)

            entry = {
                "at": datetime.now().astimezone().isoformat(timespec="seconds"),
                "decision": decision,
                "letter_count": letter_count,
                "japanese_letter_count": japanese_letter_count,
            }
            if reason:
                entry["reason"] = reason
            with log_path.open("a", encoding="utf-8") as log_file:
                os.chmod(log_path, 0o600)
                log_file.write(json.dumps(entry, ensure_ascii=False, separators=(",", ":")) + "\n")
            return decision == "block"
        finally:
            fcntl.flock(lock_file.fileno(), fcntl.LOCK_UN)


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
        ):
            return
        if not is_meta_session():
            return
        message = payload.get("last_assistant_message")
        if not isinstance(message, str):
            message = ""
        letter_count, japanese_letter_count = letter_counts(message)
        blocked = record_decision(
            payload.get("session_id"),
            payload.get("stop_hook_active") is True,
            should_block_counts(letter_count, japanese_letter_count),
            letter_count,
            japanese_letter_count,
        )
        if blocked:
            print(
                json.dumps(
                    {"decision": "block", "reason": BLOCK_REASON},
                    ensure_ascii=False,
                    separators=(",", ":"),
                )
            )
    except Exception:
        return


if __name__ == "__main__":
    main()
