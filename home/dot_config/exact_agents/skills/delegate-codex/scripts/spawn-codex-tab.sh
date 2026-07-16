#!/usr/bin/env bash

# @file spawn-codex-tab.sh
# @brief Spawn a disposable Codex implementer in a new labeled Herdr tab.
# @description
#   Wraps agmsg spawn.sh with the Herdr tab terminal helper so callers can use a
#   single command for team, role, project, and optional boot prompt wiring.
# @option --effort medium|xhigh Select default or extra-high Codex reasoning effort.
# @arg $1 team Agmsg team name.
# @arg $2 name Implementer actas identity.
# @arg $3 project Project path for the spawned Codex session.
# @arg $4 boot-prompt Optional initial task for the spawned Codex session.

set -euo pipefail

EFFORT="medium"
while [ $# -gt 0 ]; do
    case "$1" in
    --effort)
        EFFORT="${2:?--effort needs medium|xhigh}"
        shift 2
        ;;
    --)
        shift
        break
        ;;
    --*)
        echo "unknown option: $1" >&2
        exit 2
        ;;
    *)
        break
        ;;
    esac
done

case "$EFFORT" in
medium | xhigh) ;;
*)
    echo "--effort must be medium or xhigh" >&2
    exit 2
    ;;
esac

TEAM="${1:?TEAM is required}"
NAME="${2:?NAME is required}"
PROJECT="${3:?PROJECT is required}"
PROMPT="${4:-}"
SELF_DIR="$(cd "$(dirname "$0")" && pwd)"

ARGS=(codex "$NAME" --project "$PROJECT" --team "$TEAM"
    --terminal "$SELF_DIR/herdr-spawn-codex.sh {cmd}")
if [ "$EFFORT" = "xhigh" ]; then
    ARGS+=(--cli-arg -c --cli-arg 'model_reasoning_effort="xhigh"')
fi
[ -n "$PROMPT" ] && ARGS+=(--boot-prompt "$PROMPT")
export HERDR_SPAWN_LABEL="${HERDR_SPAWN_LABEL:-impl: ${NAME#impl-}}"
exec ~/.agents/skills/agmsg/scripts/spawn.sh "${ARGS[@]}"
