#!/usr/bin/env python3
"""Block a final reply that leaves an unchecked caveat unresolved."""

import json
import re
import sys

CAVEAT = re.compile(
    r"(?:まだ確かめていません|確認していません|未確認|確かめていない)(?!でした|ませんでした)"
    r"|\b(?:not yet verified|haven['’]t checked|unverified)\b",
    re.IGNORECASE,
)
BLOCK_REASON = (
    "Run the check now and report its result. If you cannot, rewrite this as an "
    "explicit blocker naming who must do what and why you cannot do it."
)


def visible_text(message: str) -> str:
    lines = []
    fence = None
    for line in message.splitlines():
        stripped = line.lstrip()
        opening = re.match(r"(`{3,}|~{3,})", stripped)
        if fence:
            closing = re.fullmatch(r"(`+|~+)[ \t]*", stripped)
            if (
                closing
                and closing.group(1)[0] == fence[0]
                and len(closing.group(1)) >= fence[1]
            ):
                fence = None
            continue
        if opening:
            fence = (opening.group(1)[0], len(opening.group(1)))
            continue
        if line.startswith(("    ", "\t")):
            continue
        if stripped.startswith(">"):
            continue
        lines.append(line)
    text = "\n".join(lines)
    text = re.sub(r"(`+)[^\n]*?\1", " ", text)
    quotes = r'''"[^"\n]*"|“[^”\n]*”|‘[^’\n]*’|「[^」\n]*」|『[^』\n]*』|(?<!\w)'(?:[^'\n]|(?<=\w)'(?=\w))*'(?!\w)'''
    return re.sub(quotes, " ", text)


def evaluate(payload: object) -> dict[str, str] | None:
    if not isinstance(payload, dict) or payload.get("hook_event_name") != "Stop":
        return None
    if payload.get("stop_hook_active") is True:
        return None
    message = payload.get("last_assistant_message")
    if isinstance(message, str) and CAVEAT.search(visible_text(message)):
        return {"decision": "block", "reason": BLOCK_REASON}
    return None


def main() -> None:
    try:
        result = evaluate(json.loads(sys.stdin.read()))
    except (json.JSONDecodeError, UnicodeDecodeError):
        return
    if result is not None:
        print(json.dumps(result, ensure_ascii=False, separators=(",", ":")))


if __name__ == "__main__":
    main()
