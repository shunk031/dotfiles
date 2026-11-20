#!/usr/bin/env python3
"""Block a final reply that leaves an unchecked caveat unresolved."""

import json
import re
import sys

CAVEAT = re.compile(
    r"(?:確かめていません|確かめていない|確認していません|確認できていません|"
    r"調べていません|検証していません|未確認)(?!でした|ませんでした)"
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
    quote_continuation = False
    for line in message.splitlines():
        stripped = line.lstrip()
        if fence:
            closing = re.fullmatch(r" {0,3}(`+|~+)[ \t]*", line)
            if (
                closing
                and closing.group(1)[0] == fence[0]
                and len(closing.group(1)) >= fence[1]
            ):
                fence = None
            continue
        if not stripped:
            quote_continuation = False
            lines.append(line)
            continue
        if line.startswith(("    ", "\t")):
            continue
        if stripped.startswith(">"):
            quote_continuation = True
            continue
        if quote_continuation:
            continue
        opening = re.match(r"(`{3,}|~{3,})", stripped)
        if opening:
            fence = (opening.group(1)[0], len(opening.group(1)))
            continue
        lines.append(line)
    text = "\n".join(lines)
    text = re.sub(r"(?<!`)(`+)(?!`)[\s\S]*?(?<!`)\1(?!`)", " ", text)
    quotes = r'''"[^"]*"|“[^”]*”|‘[^’]*’|「[\s\S]*?」|『[\s\S]*?』|(?<!\w)'(?:[^']|(?<=\w)'(?=\w))*'(?!\w)'''
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
        if result is not None:
            print(json.dumps(result, ensure_ascii=False, separators=(",", ":")))
    except Exception:
        return


if __name__ == "__main__":
    main()
