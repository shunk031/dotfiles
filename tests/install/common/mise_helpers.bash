# shellcheck shell=bash

function write_mise_with_stale_named_runner() {
    cat > "${MISE_BIN}" << 'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${MISE_CALLS_PATH}"

if [ "$1" = "exec" ]; then
    if [ "${2:-}" != "--" ]; then
        printf '%s\n' 'SyntaxError: The requested module '\''node:util'\'' does not provide an export named '\''styleText'\''' >&2
        printf '%s\n' 'Node.js v18.20.3' >&2
        exit 1
    fi

    shift 2
    "$@"
fi
EOF
    chmod +x "${MISE_BIN}"
}
