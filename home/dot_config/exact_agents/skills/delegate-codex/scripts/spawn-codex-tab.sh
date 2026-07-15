#!/usr/bin/env bash

# @file spawn-codex-tab.sh
# @brief Spawn a disposable Codex implementer in a new labeled Herdr tab.
# @description
#   Wraps agmsg spawn.sh with the Herdr tab terminal helper so callers can use a
#   single command for team, role, project, and optional boot prompt wiring.

set -euo pipefail

TEAM="$1"
NAME="$2"
PROJECT="$3"
PROMPT="${4:-}"
SELF_DIR="$(cd "$(dirname "$0")" && pwd)"

ARGS=(codex "$NAME" --project "$PROJECT" --team "$TEAM"
    --terminal "$SELF_DIR/herdr-spawn-codex.sh {cmd}")
[ -n "$PROMPT" ] && ARGS+=(--boot-prompt "$PROMPT")
export HERDR_SPAWN_LABEL="${HERDR_SPAWN_LABEL:-impl: ${NAME#impl-}}"
exec ~/.agents/skills/agmsg/scripts/spawn.sh "${ARGS[@]}"
