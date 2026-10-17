#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/claude-plugins.sh"
readonly TMPL_SCRIPT_PATH="./home/.chezmoiscripts/common/run_after_25-install-claude-plugins.sh.tmpl"
readonly CLAUDE_SETTINGS_PATH="./home/dot_config/claude/settings.json"

function setup() {
    export HOME="${BATS_TEST_TMPDIR}/home"
    mkdir -p "${HOME}/.local/bin"

    source "${SCRIPT_PATH}"
}

function write_claude_workflow_mocks() {
    mkdir -p "${BATS_TEST_TMPDIR}/bin"

    cat > "${MISE_BIN}" << 'EOF'
#!/usr/bin/env bash
if [ "$1" = "exec" ]; then
    [ "${2:-}" = "--" ] || exit 1
    shift 2
    "$@"
fi
EOF
    chmod +x "${MISE_BIN}"

    cat > "${BATS_TEST_TMPDIR}/bin/claude" << 'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${CLAUDE_PLUGINS_CLAUDE_CALLS_PATH}"
if [ "$*" = "plugin list --json" ]; then
    printf '%s\n' "${CLAUDE_PLUGIN_LIST_JSON}"
fi
EOF
    chmod +x "${BATS_TEST_TMPDIR}/bin/claude"
    export PATH="${BATS_TEST_TMPDIR}/bin:${PATH}"
}

@test "[common] Claude plugins run-after template includes the installer" {
    run cat "${TMPL_SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = '{{ include "../install/common/claude-plugins.sh" }}' ]
}

@test "[common] Claude plugins script installs missing plugins" {
    write_claude_workflow_mocks

    run env \
        CLAUDE_PLUGINS_CLAUDE_CALLS_PATH="${BATS_TEST_TMPDIR}/claude_args.txt" \
        CLAUDE_PLUGIN_LIST_JSON='[]' \
        HOME="${HOME}" \
        bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]

    run cat "${BATS_TEST_TMPDIR}/claude_args.txt"
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "plugin list --json" ]
    [ "${lines[1]}" = "plugin marketplace add DietrichGebert/ponytail" ]
    [ "${lines[2]}" = "plugin install --scope user --yes ponytail@ponytail" ]
    [ "${lines[3]}" = "plugin list --json" ]
    [ "${lines[4]}" = "plugin marketplace add petekp/inbox" ]
    [ "${lines[5]}" = "plugin install --scope user --yes inbox@inbox" ]
    [ "${#lines[@]}" -eq 6 ]
}

@test "[common] Claude plugins script skips enabled plugins" {
    write_claude_workflow_mocks

    run env \
        CLAUDE_PLUGINS_CLAUDE_CALLS_PATH="${BATS_TEST_TMPDIR}/claude_args.txt" \
        CLAUDE_PLUGIN_LIST_JSON='[{"id":"ponytail@ponytail","enabled":true},{"id":"inbox@inbox","enabled":true}]' \
        HOME="${HOME}" \
        bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]

    run cat "${BATS_TEST_TMPDIR}/claude_args.txt"
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "plugin list --json" ]
    [ "${lines[1]}" = "plugin list --json" ]
    [ "${#lines[@]}" -eq 2 ]
}

@test "[common] Claude plugins script enables disabled plugins" {
    write_claude_workflow_mocks

    run env \
        CLAUDE_PLUGINS_CLAUDE_CALLS_PATH="${BATS_TEST_TMPDIR}/claude_args.txt" \
        CLAUDE_PLUGIN_LIST_JSON='[{"id":"ponytail@ponytail","enabled":false},{"id":"inbox@inbox","enabled":false}]' \
        HOME="${HOME}" \
        bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]

    run cat "${BATS_TEST_TMPDIR}/claude_args.txt"
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "plugin list --json" ]
    [ "${lines[1]}" = "plugin enable ponytail@ponytail" ]
    [ "${lines[2]}" = "plugin list --json" ]
    [ "${lines[3]}" = "plugin enable inbox@inbox" ]
    [ "${#lines[@]}" -eq 4 ]
}

@test "[common] Claude settings enable inbox and register its GitHub marketplace" {
    run jq -e '.enabledPlugins["inbox@inbox"] == true and .extraKnownMarketplaces.inbox.source.source == "github" and .extraKnownMarketplaces.inbox.source.repo == "petekp/inbox"' "${CLAUDE_SETTINGS_PATH}"
    [ "${status}" -eq 0 ]
}
