#!/usr/bin/env bash

# @file sweep-codex-lanes.sh
# @brief Classify Herdr-hosted Codex delegate lanes after a restart.
# @description
#   Scans Herdr tabs labeled impl:* or consult:* and reports whether each lane
#   looks alive, dead at a shell prompt, or stuck in a disconnected Codex TUI.

set -euo pipefail

find_python() {
    if command -v python3 > /dev/null 2>&1; then
        command -v python3
        return 0
    fi
    command -v python
}

emit_hook_context() {
    local output
    local status
    set +e
    output="$("$0" 2>&1)"
    status=$?
    set -e

    [ -n "$output" ] || exit 0

    local python
    python="$(find_python)" || exit 0
    LANE_SWEEP_OUTPUT="$output" LANE_SWEEP_STATUS="$status" "$python" - << 'PY'
import json
import os

output = os.environ["LANE_SWEEP_OUTPUT"]
status = int(os.environ.get("LANE_SWEEP_STATUS", "0"))
summary = (
    "Codex lane sweep found DEAD/ZOMBIE lanes."
    if status
    else "Codex lane sweep found no stale lanes."
)
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": f"{summary}\n{output}",
    }
}))
PY
}

usage() {
    cat << 'EOF'
Usage: sweep-codex-lanes.sh [--hook]

Reports one line per Herdr tab labeled impl:* or consult:*. Exits 1 when any
lane is classified as DEAD or ZOMBIE. With --hook, emits Claude Code hook JSON
for SessionStart additionalContext and exits 0.
EOF
}

case "${1:-}" in
-h | --help)
    usage
    exit 0
    ;;
--hook)
    emit_hook_context
    exit 0
    ;;
"") ;;
*)
    usage >&2
    exit 2
    ;;
esac

[ "${HERDR_ENV:-}" = "1" ] || exit 0
command -v herdr > /dev/null 2>&1 || exit 0

PYTHON="$(find_python)" || exit 0
TMPDIR_SWEEP="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_SWEEP"' EXIT

HERDR_ARGS=()
if [ -n "${HERDR_WORKSPACE_ID:-}" ]; then
    HERDR_ARGS=(--workspace "$HERDR_WORKSPACE_ID")
fi

TABS_JSON="$TMPDIR_SWEEP/tabs.json"
PANES_JSON="$TMPDIR_SWEEP/panes.json"
LANES_TSV="$TMPDIR_SWEEP/lanes.tsv"

herdr tab list "${HERDR_ARGS[@]}" > "$TABS_JSON" 2> /dev/null || exit 0
herdr pane list "${HERDR_ARGS[@]}" > "$PANES_JSON" 2> /dev/null || exit 0

"$PYTHON" - "$TABS_JSON" "$PANES_JSON" > "$LANES_TSV" << 'PY'
import json
import sys

tabs_path, panes_path = sys.argv[1:3]
with open(tabs_path, encoding="utf-8") as fh:
    tabs = json.load(fh)["result"]["tabs"]
with open(panes_path, encoding="utf-8") as fh:
    panes = json.load(fh)["result"]["panes"]

panes_by_tab = {}
for pane in panes:
    panes_by_tab.setdefault(pane.get("tab_id"), []).append(pane)

for tab in tabs:
    label = tab.get("label") or ""
    if not (label.startswith("impl:") or label.startswith("consult:")):
        continue
    tab_id = tab["tab_id"]
    for pane in panes_by_tab.get(tab_id, []):
        print("\t".join([
            label,
            tab_id,
            pane["pane_id"],
            pane.get("agent_status") or tab.get("agent_status") or "unknown",
        ]))
PY

classify_transcript() {
    local agent_status="$1"
    local transcript_path="$2"

    "$PYTHON" - "$agent_status" "$transcript_path" << 'PY'
import re
import sys

agent_status, transcript_path = sys.argv[1:3]
with open(transcript_path, encoding="utf-8", errors="replace") as fh:
    text = fh.read()

ansi = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")
clean = ansi.sub("", text)
lines = [line.rstrip() for line in clean.splitlines()]
nonempty = [line for line in lines if line.strip()]
last = nonempty[-1].strip() if nonempty else ""

if "No saved session found" in clean:
    print("DEAD\tNo saved session found")
    raise SystemExit

shell_prompt = re.compile(
    r"^(?:[A-Za-z0-9._-]+@[^:]+:.+[#$]|[^ ]+@[^ ]+\s+.+[#$]|[#$%]|❯)\s*$"
)
if last and shell_prompt.match(last):
    print(f"DEAD\tshell prompt: {last}")
    raise SystemExit

if "stream disconnected before completion" in clean:
    print("ZOMBIE\tstream disconnected before completion")
    raise SystemExit

def elapsed_seconds(value):
    total = 0
    for amount, unit in re.findall(r"(\d+)\s*([hms])", value):
        amount = int(amount)
        if unit == "h":
            total += amount * 3600
        elif unit == "m":
            total += amount * 60
        else:
            total += amount
    return total

working_ages = [
    (match.group(1), elapsed_seconds(match.group(1)))
    for match in re.finditer(r"Working \(([^)]*)\)", clean)
]
if working_ages:
    label, seconds = max(working_ages, key=lambda item: item[1])
    if seconds > 1800:
        print(f"ZOMBIE\tWorking {label} (>30m)")
        raise SystemExit
    print(f"ALIVE\t{agent_status}; Working {label}")
    raise SystemExit

print(f"ALIVE\t{agent_status}")
PY
}

has_stale=0
while IFS=$'\t' read -r label tab_id pane_id agent_status; do
    [ -n "$pane_id" ] || continue
    transcript="$TMPDIR_SWEEP/$pane_id.txt"
    herdr pane read "$pane_id" --source recent-unwrapped > "$transcript" 2>&1 || true
    result="$(classify_transcript "$agent_status" "$transcript")"
    state="${result%%$'\t'*}"
    reason="${result#*$'\t'}"
    printf '%s label="%s" tab=%s pane=%s status=%s reason="%s"\n' \
        "$state" "$label" "$tab_id" "$pane_id" "$agent_status" "$reason"
    case "$state" in
    DEAD | ZOMBIE) has_stale=1 ;;
    esac
done < "$LANES_TSV"

exit "$has_stale"
