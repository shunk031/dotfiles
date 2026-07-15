#!/usr/bin/env bash

# @file wait-pane.sh
# @brief Wait until a Herdr pane is no longer in a working or unknown state.
# @description
#   Polls Herdr for a pane's Codex agent status and prints the first terminal or
#   idle state observed. If the pane disappears, prints "gone".

set -euo pipefail

PANE="$1"
INT="${2:-15}"

while true; do
    S=$(herdr pane get "$PANE" 2> /dev/null |
        uv run --no-project python -c 'import sys,json;print(json.load(sys.stdin)["result"]["pane"]["agent_status"])' \
            2> /dev/null || echo gone)
    case "$S" in
    working | unknown) sleep "$INT" ;;
    *)
        printf '%s\n' "$S"
        exit 0
        ;;
    esac
done
