#!/usr/bin/env bash

# @file herdr-spawn-codex.sh
# @brief Create a labeled Herdr tab and run the agmsg Codex boot command in it.
# @description
#   This script is used as the agmsg spawn terminal template target. It creates
#   a new tab in the current Herdr workspace, starts the provided boot command,
#   and prints the created pane id for monitoring.

set -euo pipefail

BOOT="$1"
LABEL="${HERDR_SPAWN_LABEL:-impl}"
WS="${HERDR_WORKSPACE_ID:?not inside herdr}"

ENV_ARGS=()
for KEY in ${HERDR_SPAWN_ENV_KEYS:-}; do
    if [[ ! "$KEY" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
        echo "invalid HERDR_SPAWN_ENV_KEYS entry: $KEY" >&2
        exit 2
    fi
    ENV_ARGS+=(--env "${KEY}=${!KEY-}")
done

TAB=$(herdr tab create --workspace "$WS" --label "$LABEL" "${ENV_ARGS[@]}" --no-focus |
    uv run --no-project python -c 'import sys,json;print(json.load(sys.stdin)["result"]["tab"]["tab_id"])')
PANE=$(herdr pane list --workspace "$WS" | TAB="$TAB" uv run --no-project python -c '
import sys, json, os
tab = os.environ["TAB"]
print(next(p["pane_id"] for p in json.load(sys.stdin)["result"]["panes"] if p["tab_id"] == tab))')
herdr pane rename "$PANE" "$LABEL" > /dev/null
herdr pane run "$PANE" "$BOOT" > /dev/null
printf '%s\n' "$PANE"
