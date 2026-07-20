#!/usr/bin/env bash

# @file spawn-codex-tab.sh
# @brief Spawn a disposable Codex implementer in a new labeled Herdr tab.
# @description
#   Creates the Herdr tab directly instead of routing through agmsg spawn.sh.
#   agmsg spawn.sh prefers tmux placement when $TMUX is set, which is exactly
#   the failure mode this wrapper must avoid.

set -euo pipefail

usage() {
    cat << 'EOF'
Usage: spawn-codex-tab.sh <team> <name> <project>

Creates a new Herdr tab, pre-registers <name> in agmsg for <project>, and runs
Codex with "/agmsg actas <name>" as the initial prompt.

Environment:
  HERDR_WORKSPACE_ID   Required by herdr sessions.
  HERDR_CODEX_BIN      Codex executable to run. Defaults to "codex".
  HERDR_SPAWN_LABEL    Herdr tab label. Defaults to "impl: <name without impl->".
  HERDR_SPAWN_ENV_KEYS Space-separated environment variable names to pass to
                       herdr tab create as --env KEY=VALUE.
EOF
}

[ "${1:-}" != "-h" ] && [ "${1:-}" != "--help" ] || {
    usage
    exit 0
}

[ "$#" -eq 3 ] || {
    usage >&2
    exit 2
}

TEAM="$1"
NAME="$2"
PROJECT="$3"
LABEL="${HERDR_SPAWN_LABEL:-impl: ${NAME#impl-}}"
WS="${HERDR_WORKSPACE_ID:?not inside herdr}"
CODEX_BIN="${HERDR_CODEX_BIN:-codex}"
AGMSG_SCRIPTS_DIR="${AGMSG_SCRIPTS_DIR:-$HOME/.agents/skills/agmsg/scripts}"
JOIN_SCRIPT="$AGMSG_SCRIPTS_DIR/join.sh"

[ -d "$PROJECT" ] || {
    echo "spawn-codex-tab: project path does not exist: $PROJECT" >&2
    exit 1
}
PROJECT="$(cd "$PROJECT" && pwd)"

command -v herdr > /dev/null 2>&1 || {
    echo "spawn-codex-tab: herdr not found on PATH" >&2
    exit 1
}
command -v "$CODEX_BIN" > /dev/null 2>&1 || {
    echo "spawn-codex-tab: Codex executable not found: $CODEX_BIN" >&2
    exit 1
}
[ -x "$JOIN_SCRIPT" ] || {
    echo "spawn-codex-tab: agmsg join.sh not found: $JOIN_SCRIPT" >&2
    exit 1
}

ENV_ARGS=()
for KEY in ${HERDR_SPAWN_ENV_KEYS:-}; do
    if [[ ! "$KEY" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
        echo "spawn-codex-tab: invalid HERDR_SPAWN_ENV_KEYS entry: $KEY" >&2
        exit 2
    fi
    ENV_ARGS+=(--env "${KEY}=${!KEY-}")
done

AGMSG_RESOLVE_PROJECT=0 "$JOIN_SCRIPT" "$TEAM" "$NAME" codex "$PROJECT" > /dev/null

BOOT_DIR="${TMPDIR:-/tmp}/delegate-codex-spawn"
mkdir -p "$BOOT_DIR"
find "$BOOT_DIR" -name 'boot-*.sh' -type f -mtime +1 -delete 2> /dev/null || true
BOOT_BASE="$(mktemp "$BOOT_DIR/boot-XXXXXX")"
BOOT="$BOOT_BASE.sh"
mv "$BOOT_BASE" "$BOOT"
{
    echo '#!/usr/bin/env bash'
    echo 'set -euo pipefail'
    printf 'cd %q\n' "$PROJECT"
    printf 'exec %q %q\n' "$CODEX_BIN" "/agmsg actas $NAME"
} > "$BOOT"
chmod +x "$BOOT"

if [ "${#ENV_ARGS[@]}" -gt 0 ]; then
    TAB=$(herdr tab create --workspace "$WS" --label "$LABEL" "${ENV_ARGS[@]}" --no-focus |
        uv run --no-project python -c 'import sys,json;print(json.load(sys.stdin)["result"]["tab"]["tab_id"])')
else
    TAB=$(herdr tab create --workspace "$WS" --label "$LABEL" --no-focus |
        uv run --no-project python -c 'import sys,json;print(json.load(sys.stdin)["result"]["tab"]["tab_id"])')
fi
PANE=$(herdr pane list --workspace "$WS" | TAB="$TAB" uv run --no-project python -c '
import sys, json, os
tab = os.environ["TAB"]
print(next(p["pane_id"] for p in json.load(sys.stdin)["result"]["panes"] if p["tab_id"] == tab))')

herdr pane rename "$PANE" "$LABEL" > /dev/null
herdr pane run "$PANE" "$BOOT" > /dev/null

printf 'tab_id=%s\n' "$TAB"
printf 'pane_id=%s\n' "$PANE"
