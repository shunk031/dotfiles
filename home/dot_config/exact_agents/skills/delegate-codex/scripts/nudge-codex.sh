#!/usr/bin/env bash

# @file nudge-codex.sh
# @brief Safely nudge an available Codex TUI pane through Herdr.
# @description
#   Refuses to send text to panes that are working or whose status cannot be
#   confirmed as idle or done.

set -euo pipefail

PANE="$1"
MSG="$2"
STATUS=$(herdr pane get "$PANE" |
    uv run --no-project python -c 'import sys, json; print(json.load(sys.stdin)["result"]["pane"]["agent_status"])')
case "$STATUS" in
    idle|done) ;;
    *)
        echo "SKIP: pane $PANE is '$STATUS' (not idle or done). Message stays in agmsg inbox; retry when idle or done." >&2
        exit 3
        ;;
esac
herdr pane run "$PANE" "$MSG"
echo "nudged $PANE"
