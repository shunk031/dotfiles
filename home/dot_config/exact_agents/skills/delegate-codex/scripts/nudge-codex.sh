#!/usr/bin/env bash

# @file nudge-codex.sh
# @brief Safely nudge an idle Codex TUI pane through Herdr.
# @description
#   Refuses to send text to panes that are working or whose status cannot be
#   confirmed as idle.

set -euo pipefail

PANE="$1"
MSG="$2"
STATUS=$(herdr pane get "$PANE" |
    uv run --no-project python -c 'import sys, json; print(json.load(sys.stdin)["result"]["pane"]["agent_status"])')
if [ "$STATUS" != "idle" ]; then
    echo "SKIP: pane $PANE is '$STATUS' (not idle). Message stays in agmsg inbox; retry when idle." >&2
    exit 3
fi
herdr pane run "$PANE" "$MSG"
echo "nudged $PANE"
