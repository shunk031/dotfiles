#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/claude-plugins.sh"
readonly TMPL_SCRIPT_PATH="./home/.chezmoiscripts/common/run_after_25-install-claude-plugins.sh.tmpl"
readonly CLAUDE_SETTINGS_PATH="./home/private_dot_config/claude/settings.json"
readonly CLAUDE_SETTINGS_MODIFIER_PATH="./home/dot_claude/modify_settings.json"

function setup() {
    export HOME="${BATS_TEST_TMPDIR}/home"
    mkdir -p "${HOME}/.local/bin"

    CHEZMOI_TEMPLATE_SOURCE="${BATS_TEST_TMPDIR}/chezmoi-source"
    CHEZMOI_TEMPLATE_DESTINATION="${BATS_TEST_TMPDIR}/chezmoi-destination"
    mkdir -p "${CHEZMOI_TEMPLATE_SOURCE}" "${CHEZMOI_TEMPLATE_DESTINATION}"
    CHEZMOI_TEMPLATE_ARGS=(
        --source "${CHEZMOI_TEMPLATE_SOURCE}"
        --destination "${CHEZMOI_TEMPLATE_DESTINATION}"
        --config /dev/null
        --config-format toml
    )

    source "${SCRIPT_PATH}"
}

function write_claude_workflow_mocks() {
    mkdir -p "${BATS_TEST_TMPDIR}/bin"
    export CLAUDE_PLUGINS_MISE_CALLS_PATH="${BATS_TEST_TMPDIR}/mise_calls.txt"

    cat > "${MISE_BIN}" << 'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${CLAUDE_PLUGINS_MISE_CALLS_PATH}"
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

    run grep -c '^exec -- jq ' "${CLAUDE_PLUGINS_MISE_CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "6" ]
}

@test "[common] Claude plugins script rejects invalid plugin list JSON" {
    write_claude_workflow_mocks

    run env \
        CLAUDE_PLUGINS_CLAUDE_CALLS_PATH="${BATS_TEST_TMPDIR}/claude_args.txt" \
        CLAUDE_PLUGIN_LIST_JSON='[{"id":' \
        HOME="${HOME}" \
        bash "${SCRIPT_PATH}"
    [ "${status}" -ne 0 ]

    run cat "${BATS_TEST_TMPDIR}/claude_args.txt"
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "plugin list --json" ]
    [ "${#lines[@]}" -eq 1 ]
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

@test "[common] Claude settings modifier creates initial managed settings without a model" {
    run chezmoi "${CHEZMOI_TEMPLATE_ARGS[@]}" execute-template --with-stdin --file "${CLAUDE_SETTINGS_MODIFIER_PATH}" < /dev/null
    [ "${status}" -eq 0 ]

    run jq -e 'type == "object" and (has("model") | not) and .alwaysThinkingEnabled == true and .enabledPlugins["inbox@inbox"] == true' <<< "${output}"
    [ "${status}" -eq 0 ]
}

@test "[common] Claude settings modifier retains all current shared values" {
    run chezmoi "${CHEZMOI_TEMPLATE_ARGS[@]}" execute-template --with-stdin --file "${CLAUDE_SETTINGS_MODIFIER_PATH}" < "${CLAUDE_SETTINGS_PATH}"
    [ "${status}" -eq 0 ]

    local actual expected
    actual="$(jq -S . <<< "${output}")"
    expected="$(jq -S . "${CLAUDE_SETTINGS_PATH}")"
    [ "${actual}" = "${expected}" ]
}

@test "[common] Claude settings modifier preserves user state and overrides managed keys" {
    run chezmoi "${CHEZMOI_TEMPLATE_ARGS[@]}" execute-template --with-stdin --file "${CLAUDE_SETTINGS_MODIFIER_PATH}" <<< '{"model":"sonnet","runtimeOnly":{"enabled":true},"env":{"USER_VALUE":"keep"},"alwaysThinkingEnabled":false}'
    [ "${status}" -eq 0 ]

    run jq -e '.model == "sonnet" and .runtimeOnly.enabled == true and .env.USER_VALUE == "keep" and .alwaysThinkingEnabled == true' <<< "${output}"
    [ "${status}" -eq 0 ]
}

@test "[common] Claude settings modifier rejects invalid JSON without output" {
    run --separate-stderr chezmoi "${CHEZMOI_TEMPLATE_ARGS[@]}" execute-template --with-stdin --file "${CLAUDE_SETTINGS_MODIFIER_PATH}" <<< '{"model":'
    [ "${status}" -ne 0 ]
    [ -z "${output}" ]
}

@test "[common] Claude settings apply replaces an existing symlink without changing its source" {
    local apply_source="${BATS_TEST_TMPDIR}/apply-source"
    local source_settings="${apply_source}/private_dot_config/claude/settings.json"
    local source_settings_before="${BATS_TEST_TMPDIR}/source-settings.before.json"
    local old_link_target="${HOME}/.config/claude/settings.json"
    local settings="${HOME}/.claude/settings.json"

    mkdir -p "${apply_source}/dot_claude" "${apply_source}/private_dot_config/claude" "${HOME}/.config/claude" "${HOME}/.claude"
    cp "${CLAUDE_SETTINGS_MODIFIER_PATH}" "${apply_source}/dot_claude/modify_settings.json"
    jq '.model = "sonnet" | .runtimeOnly.enabled = true' "${CLAUDE_SETTINGS_PATH}" > "${source_settings}"
    cp "${source_settings}" "${source_settings_before}"
    ln -s "${source_settings}" "${old_link_target}"
    ln -s "${old_link_target}" "${settings}"

    run chezmoi \
        --source "${apply_source}" \
        --destination "${HOME}" \
        --config /dev/null \
        --config-format toml \
        --cache "${BATS_TEST_TMPDIR}/cache" \
        --persistent-state "${BATS_TEST_TMPDIR}/state" \
        apply --force "${settings}"
    [ "${status}" -eq 0 ]
    [ -f "${settings}" ]
    [ ! -L "${settings}" ]

    run jq -e '.model == "sonnet" and .runtimeOnly.enabled == true' "${settings}"
    [ "${status}" -eq 0 ]

    run cmp "${source_settings_before}" "${source_settings}"
    [ "${status}" -eq 0 ]
}
