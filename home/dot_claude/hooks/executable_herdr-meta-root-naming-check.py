#!/usr/bin/env python3
"""Block Meta text that identifies a root only by its agent name."""

from concurrent.futures import ThreadPoolExecutor
from datetime import datetime
import json
import os
import re
import subprocess
import sys
from pathlib import Path
STATE = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state"))
ROOTS, LOG = STATE / "meta/roots.tsv", STATE / "meta/root-naming-check.log"
EXEMPT = re.compile(r"(?<!`)(?P<ticks>`+)(?!`).*?(?<!`)(?P=ticks)(?!`)|(?<!\w)(?:~?/|\.{1,2}/|[\w.-]+/)[^\s]+", re.S)
LABEL = re.compile(
    r"(?:[^\n.!?。！？;；]*?\S[^\n.!?。！？;；]*?[ \t]*担当の[ \t]+Orchestrator|Orchestrator[ \t]+(?:for|handling|responsible for)[ \t]+[\w][^.!?。！？;；\n]*)\s*$",
    re.I,
)
MESSAGE = (
    "Use <what it handles> followed by the agent name in parentheses. "
    "Take the label from the root's Herdr workspace label, tab title, or stated task."
)

def warning(reason):
    try:
        LOG.parent.mkdir(parents=True, exist_ok=True)
        with LOG.open("a", encoding="utf-8") as stream:
            row = {"time": datetime.now().astimezone().isoformat(), "warning": reason}
            stream.write(json.dumps(row) + "\n")
    except OSError:
        print("Meta root-naming check warning could not be logged.", file=sys.stderr)


def root_registry():
    rows = [line.split("\t") for line in ROOTS.read_text(encoding="utf-8").splitlines() if line and not line.startswith("#")]
    return {m: {n for machine, n in rows if machine == m} for m, _ in rows}


def bare_names(text, names):
    text, found = EXEMPT.sub("", text), set()
    for name in names:
        pattern = rf"(?<![\w.-]){re.escape(name)}(?![\w-]|\.[\w-])"
        for match in re.finditer(pattern, text):
            start, end = match.span()
            pair = text[start - 1 : end + 1] if start else ""
            if pair in (f"({name})", f"（{name}）") and LABEL.search(text[:start - 1]):
                continue
            found.add(name)
    return found


def text_values(value):
    if isinstance(value, str):
        return [value]
    items = value.values() if isinstance(value, dict) else value if isinstance(value, list) else []
    return sum(map(text_values, items), [])


def live_agents(machine):
    command = ["herdr"] + ([] if machine == "Local" else ["--machine", machine]) + ["agent", "list"]
    try:
        result = subprocess.run(command, capture_output=True, text=True, timeout=2, check=False)
        rows = json.loads(result.stdout).get("result", {}).get("agents") if result.returncode == 0 else None
        return [row for row in rows if isinstance(row, dict)] if isinstance(rows, list) else None
    except Exception:
        return None


def evaluate(payload, inventory=live_agents):
    if not isinstance(payload, dict):
        return None
    if payload.get("hook_event_name") != "PreToolUse" or payload.get("tool_name") != "mcp__inbox__record":
        return None
    text = "\n".join(text_values(payload.get("tool_input", {})))
    if os.environ.get("HERDR_ENV") != "1" or not os.environ.get("HERDR_PANE_ID"):
        return None
    try:
        roots = root_registry()
        candidates = bare_names(text, set().union(*roots.values()))
    except Exception:
        warning("patrol root list unavailable; allowed")
        return None
    if not candidates:
        return None
    local = inventory("Local")
    if local is None:
        warning("Herdr local inventory unavailable; allowed")
        return None
    pane = [row for row in local if row.get("pane_id") == os.environ["HERDR_PANE_ID"]]
    if len(pane) != 1 or pane[0].get("name") != "meta":
        return None
    blocked = {"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny",
                                       "permissionDecisionReason": MESSAGE}}
    if candidates & roots.get("Local", set()) & {row.get("name") for row in local}:
        return blocked
    machines = [m for m, group in roots.items() if m != "Local" and candidates & group]
    with ThreadPoolExecutor(max_workers=max(1, len(machines))) as pool:
        inventories = list(pool.map(inventory, machines))
    unavailable = False
    for machine, rows in zip(machines, inventories):
        if rows is None:
            unavailable = True
        elif candidates & roots[machine] & {row.get("name") for row in rows}:
            return blocked
    if unavailable:
        warning("Herdr saved-machine inventory unavailable; allowed")
    return None


def main():
    try:
        result = evaluate(json.loads(sys.stdin.read()))
    except Exception:
        warning("check failed; allowed")
        return
    if result:
        sys.stdout.write(json.dumps(result, ensure_ascii=False, separators=(",", ":")) + "\n")


if __name__ == "__main__":
    main()
