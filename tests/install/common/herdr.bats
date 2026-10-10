#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/herdr.sh"
readonly MISE_HELPERS_PATH="./tests/install/common/mise_helpers.bash"

function setup() {
    export HOME="${BATS_TEST_TMPDIR}/home"
    mkdir -p "${HOME}/.local/bin"
    export CLAUDE_CONFIG_DIR="$HOME/.claude"
    export CODEX_HOME="$HOME/.codex"
    OBSERVER_PID=''

    source "${SCRIPT_PATH}"
    source "${MISE_HELPERS_PATH}"
}

function teardown() {
    if [[ -n "${OBSERVER_PID}" ]] && kill -0 "${OBSERVER_PID}" 2> /dev/null; then
        kill "${OBSERVER_PID}" 2> /dev/null || true
        wait "${OBSERVER_PID}" 2> /dev/null || true
    fi
    PATH=$(getconf PATH)
    export PATH
}

@test "[common] sync_herdr_skill succeeds when the named npm runner is stale" {
    mkdir -p "${BATS_TEST_TMPDIR}/bin"
    MISE_CALLS_PATH="${BATS_TEST_TMPDIR}/mise_args.txt"
    HERDR_CALLS_PATH="${BATS_TEST_TMPDIR}/herdr_args.txt"
    export MISE_CALLS_PATH HERDR_CALLS_PATH
    write_mise_with_stale_named_runner

    cat > "${BATS_TEST_TMPDIR}/bin/herdr" << 'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" > "${HERDR_CALLS_PATH}"
printf '%s\n' 'generated Herdr skill'
EOF
    chmod +x "${BATS_TEST_TMPDIR}/bin/herdr"

    PATH="${BATS_TEST_TMPDIR}/bin:${PATH}" run sync_herdr_skill
    [ "${status}" -eq 0 ]

    run cat "${BATS_TEST_TMPDIR}/mise_args.txt"
    [ "${status}" -eq 0 ]
    [ "${output}" = "exec -- herdr --skill" ]

    run cat "${BATS_TEST_TMPDIR}/herdr_args.txt"
    [ "${status}" -eq 0 ]
    [ "${output}" = "--skill" ]

    run cat "${HOME}/.agents/skills/herdr/SKILL.md"
    [ "${status}" -eq 0 ]
    [ "${output}" = "generated Herdr skill" ]
}

@test "[common] sync_herdr_skill writes the shared skill from Herdr" {
    MISE_CALLS_PATH="${BATS_TEST_TMPDIR}/mise_args.txt"
    export MISE_CALLS_PATH
    cat > "${MISE_BIN}" << 'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${MISE_CALLS_PATH}"
if [ "$*" = "exec -- herdr --skill" ]; then
    printf '%s\n' 'generated Herdr skill'
fi
EOF
    chmod +x "${MISE_BIN}"

    sync_herdr_skill

    run cat "${BATS_TEST_TMPDIR}/mise_args.txt"
    [ "${status}" -eq 0 ]
    [ "${output}" = "exec -- herdr --skill" ]

    run cat "${HOME}/.agents/skills/herdr/SKILL.md"
    [ "${status}" -eq 0 ]
    [ "${output}" = "generated Herdr skill" ]
}

@test "[common] sync_herdr_integrations refuses the old source-directory symlink" {
    mkdir -p "${HOME}/.claude" "${BATS_TEST_TMPDIR}/source-hooks"
    ln -s "${BATS_TEST_TMPDIR}/source-hooks" "${HOME}/.claude/hooks"

    run sync_herdr_integrations false

    [ "${status}" -eq 1 ]
    [[ "${output}" == *'chezmoi apply'* ]]
    [ ! -e "${BATS_TEST_TMPDIR}/source-hooks/herdr-agent-state.sh" ]
}

@test "[common] sync targets stale integrations and restores settings after failure" {
    local herdr_bin="${BATS_TEST_TMPDIR}/herdr"
    local codex_settings_source="${BATS_TEST_TMPDIR}/codex-hooks.json"

    cat > "${herdr_bin}" << 'EOF'
#!/usr/bin/env bash
set -eu
printf '%s\n' "$*" >> "${HERDR_CALLS_PATH}"
case "$*" in
    'integration status')
        printf '%s\n' "${HERDR_STATUS}"
        ;;
    'integration install codex')
        printf '%s\n' 'installer hooks' > "${CODEX_HOME}/hooks.json"
        printf '%s\n' 'installer config' > "${CODEX_HOME}/config.toml"
        printf '%s\n' 'new Codex hook' > "${CODEX_HOME}/herdr-agent-state.sh"
        exit 23
        ;;
    'integration install claude')
        exit 99
        ;;
    *) exit 1 ;;
esac
EOF
    chmod +x "${herdr_bin}"
    mkdir -p "${HOME}/.codex"
    printf '%s\n' 'source-owned hooks' > "${codex_settings_source}"
    ln -s "${codex_settings_source}" "${HOME}/.codex/hooks.json"
    export HERDR_CALLS_PATH="${BATS_TEST_TMPDIR}/herdr_calls.txt"
    export HERDR_STATUS=$'claude: current (v1)\ncodex: needs repair'

    run sync_herdr_integrations "${herdr_bin}"

    [ "${status}" -ne 0 ]
    [ -L "${HOME}/.codex/hooks.json" ]
    [ "$(readlink "${HOME}/.codex/hooks.json")" = "${codex_settings_source}" ]
    [ "$(< "${codex_settings_source}")" = 'source-owned hooks' ]
    [ ! -e "${HOME}/.codex/config.toml" ]
    [ "$(< "${HERDR_CALLS_PATH}")" = $'integration status\nintegration install codex' ]

    : > "${HERDR_CALLS_PATH}"
    export HERDR_STATUS=$'claude: current (v1)\ncodex: current (v2)'
    run sync_herdr_integrations "${herdr_bin}"

    [ "${status}" -eq 0 ]
    [ "$(< "${HERDR_CALLS_PATH}")" = 'integration status' ]
}

@test "[common] sync finishes restoring settings despite repeated signals" {
    local herdr_bin="${BATS_TEST_TMPDIR}/herdr"
    local codex_settings_source="${BATS_TEST_TMPDIR}/codex-hooks.json"

    cat > "${herdr_bin}" << 'EOF'
#!/usr/bin/env bash
set -eu
printf '%s\n' "$*" >> "${HERDR_CALLS_PATH}"
case "$*" in
    'integration status')
        printf '%s\n' 'claude: current (v1)' 'codex: needs repair'
        ;;
    'integration install codex')
        printf '%s\n' 'installer hooks' > "${CODEX_HOME}/hooks.json"
        printf '%s\n' 'installer config' > "${CODEX_HOME}/config.toml"
        kill -TERM "$$"
        ;;
    *) exit 1 ;;
esac
EOF
    chmod +x "${herdr_bin}"
    mkdir -p "${BATS_TEST_TMPDIR}/bin"
    cat > "${BATS_TEST_TMPDIR}/bin/cp" << 'EOF'
#!/usr/bin/env bash
if [ "$1" = -p ]; then
    kill -TERM "$PPID"
fi
/bin/cp "$@"
EOF
    chmod +x "${BATS_TEST_TMPDIR}/bin/cp"
    mkdir -p "${HOME}/.codex"
    printf '%s\n' 'source-owned hooks' > "${codex_settings_source}"
    ln -s "${codex_settings_source}" "${HOME}/.codex/hooks.json"
    export HERDR_CALLS_PATH="${BATS_TEST_TMPDIR}/herdr_signal_calls.txt"

    PATH="${BATS_TEST_TMPDIR}/bin:${PATH}" run sync_herdr_integrations "${herdr_bin}"

    [ "${status}" -eq 143 ]
    [ -L "${HOME}/.codex/hooks.json" ]
    [ "$(readlink "${HOME}/.codex/hooks.json")" = "${codex_settings_source}" ]
    [ "$(< "${codex_settings_source}")" = 'source-owned hooks' ]
    [ ! -e "${HOME}/.codex/config.toml" ]
}
