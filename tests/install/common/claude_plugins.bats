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
elif [ "$*" = "plugin marketplace list --json" ]; then
    printf '%s\n' "${CLAUDE_MARKETPLACE_LIST_JSON:-[]}"
fi
EOF
    chmod +x "${BATS_TEST_TMPDIR}/bin/claude"
    export PATH="${BATS_TEST_TMPDIR}/bin:${PATH}"

    mkdir -p "${HOME}/.claude"
    cp "${CLAUDE_SETTINGS_PATH}" "${HOME}/.claude/settings.json"
}

readonly INBOX_SOURCE="shunk031/inbox@v0.3.0-fork.1"
readonly INBOX_KNOWN='[{"name":"inbox","source":"github","repo":"shunk031/inbox","ref":"v0.3.0-fork.1"}]'

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
    [ "${lines[0]}" = "plugin marketplace list --json" ]
    [ "${lines[1]}" = "plugin marketplace add ${INBOX_SOURCE}" ]
    [ "${lines[2]}" = "plugin list --json" ]
    [ "${lines[3]}" = "plugin install --scope user --yes inbox@inbox" ]
    [ "${#lines[@]}" -eq 4 ]

    run grep -c '^exec -- jq ' "${CLAUDE_PLUGINS_MISE_CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "6" ]
}

@test "[common] Claude plugins script adds a marketplace listed with another source and reinstalls its plugin" {
    write_claude_workflow_mocks

    run env \
        CLAUDE_PLUGINS_CLAUDE_CALLS_PATH="${BATS_TEST_TMPDIR}/claude_args.txt" \
        CLAUDE_MARKETPLACE_LIST_JSON='[{"name":"inbox","source":"github","repo":"petekp/inbox"}]' \
        CLAUDE_PLUGIN_LIST_JSON='[{"id":"inbox@inbox","enabled":true}]' \
        HOME="${HOME}" \
        bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]

    run cat "${BATS_TEST_TMPDIR}/claude_args.txt"
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "plugin marketplace list --json" ]
    [ "${lines[1]}" = "plugin marketplace add ${INBOX_SOURCE}" ]
    [ "${lines[2]}" = "plugin list --json" ]
    [ "${lines[3]}" = "plugin uninstall --keep-data inbox@inbox" ]
    [ "${lines[4]}" = "plugin install --scope user --yes inbox@inbox" ]
    [ "${#lines[@]}" -eq 5 ]
}

@test "[common] Claude plugins script reinstalls a plugin when it adds its marketplace" {
    write_claude_workflow_mocks

    run env \
        CLAUDE_PLUGINS_CLAUDE_CALLS_PATH="${BATS_TEST_TMPDIR}/claude_args.txt" \
        CLAUDE_PLUGIN_LIST_JSON='[{"id":"inbox@inbox","enabled":true}]' \
        HOME="${HOME}" \
        bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]

    run cat "${BATS_TEST_TMPDIR}/claude_args.txt"
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "plugin marketplace list --json" ]
    [ "${lines[1]}" = "plugin marketplace add ${INBOX_SOURCE}" ]
    [ "${lines[2]}" = "plugin list --json" ]
    [ "${lines[3]}" = "plugin uninstall --keep-data inbox@inbox" ]
    [ "${lines[4]}" = "plugin install --scope user --yes inbox@inbox" ]
    [ "${#lines[@]}" -eq 5 ]
}

@test "[common] Claude plugins script rejects invalid plugin list JSON" {
    write_claude_workflow_mocks

    run env \
        CLAUDE_PLUGINS_CLAUDE_CALLS_PATH="${BATS_TEST_TMPDIR}/claude_args.txt" \
        CLAUDE_MARKETPLACE_LIST_JSON="${INBOX_KNOWN}" \
        CLAUDE_PLUGIN_LIST_JSON='[{"id":' \
        HOME="${HOME}" \
        bash "${SCRIPT_PATH}"
    [ "${status}" -ne 0 ]

    run cat "${BATS_TEST_TMPDIR}/claude_args.txt"
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "plugin marketplace list --json" ]
    [ "${lines[1]}" = "plugin list --json" ]
    [ "${#lines[@]}" -eq 2 ]
}

@test "[common] Claude plugins script skips enabled plugins" {
    write_claude_workflow_mocks

    run env \
        CLAUDE_PLUGINS_CLAUDE_CALLS_PATH="${BATS_TEST_TMPDIR}/claude_args.txt" \
        CLAUDE_MARKETPLACE_LIST_JSON="${INBOX_KNOWN}" \
        CLAUDE_PLUGIN_LIST_JSON='[{"id":"inbox@inbox","enabled":true}]' \
        HOME="${HOME}" \
        bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]

    run cat "${BATS_TEST_TMPDIR}/claude_args.txt"
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "plugin marketplace list --json" ]
    [ "${lines[1]}" = "plugin list --json" ]
    [ "${#lines[@]}" -eq 2 ]
}

@test "[common] Claude plugins script enables disabled plugins" {
    write_claude_workflow_mocks

    run env \
        CLAUDE_PLUGINS_CLAUDE_CALLS_PATH="${BATS_TEST_TMPDIR}/claude_args.txt" \
        CLAUDE_MARKETPLACE_LIST_JSON="${INBOX_KNOWN}" \
        CLAUDE_PLUGIN_LIST_JSON='[{"id":"inbox@inbox","enabled":false}]' \
        HOME="${HOME}" \
        bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]

    run cat "${BATS_TEST_TMPDIR}/claude_args.txt"
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "plugin marketplace list --json" ]
    [ "${lines[1]}" = "plugin list --json" ]
    [ "${lines[2]}" = "plugin enable inbox@inbox" ]
    [ "${#lines[@]}" -eq 3 ]
}

@test "[common] Claude settings disable Ponytail and keep inbox enabled" {
    run jq -e '.enabledPlugins["ponytail@ponytail"] == false and .enabledPlugins["inbox@inbox"] == true and (.extraKnownMarketplaces | has("ponytail") | not)' "${CLAUDE_SETTINGS_PATH}"
    [ "${status}" -eq 0 ]

    run chezmoi "${CHEZMOI_TEMPLATE_ARGS[@]}" execute-template --with-stdin --file "${CLAUDE_SETTINGS_MODIFIER_PATH}" < /dev/null
    [ "${status}" -eq 0 ]
    run jq -e '.enabledPlugins["ponytail@ponytail"] == false and .enabledPlugins["inbox@inbox"] == true and (.extraKnownMarketplaces | has("ponytail") | not)' <<< "${output}"
    [ "${status}" -eq 0 ]
}

@test "[common] Claude settings disable previously enabled Ponytail" {
    run chezmoi "${CHEZMOI_TEMPLATE_ARGS[@]}" execute-template --with-stdin --file "${CLAUDE_SETTINGS_MODIFIER_PATH}" <<< '{"enabledPlugins":{"ponytail@ponytail":true,"other@other":true},"extraKnownMarketplaces":{"ponytail":{"source":{"source":"github","repo":"ponytail/ponytail"}},"other":{"source":{"source":"github","repo":"other/repo"}}}}'
    [ "${status}" -eq 0 ]

    run jq -e '.enabledPlugins["ponytail@ponytail"] == false and .enabledPlugins["other@other"] == true and .enabledPlugins["inbox@inbox"] == true and (.extraKnownMarketplaces | has("ponytail") | not) and .extraKnownMarketplaces.other.source.repo == "other/repo"' <<< "${output}"
    [ "${status}" -eq 0 ]
}

@test "[common] Claude settings enable inbox from the pinned fork with recorded items only" {
    run jq -e '.enabledPlugins["inbox@inbox"] == true and .extraKnownMarketplaces.inbox.source == {"source":"github","repo":"shunk031/inbox","ref":"v0.3.0-fork.1"} and .env.INBOX_RECORDED_ITEMS_ONLY == "1"' "${CLAUDE_SETTINGS_PATH}"
    [ "${status}" -eq 0 ]

    run chezmoi "${CHEZMOI_TEMPLATE_ARGS[@]}" execute-template --with-stdin --file "${CLAUDE_SETTINGS_MODIFIER_PATH}" <<< '{"extraKnownMarketplaces":{"inbox":{"source":{"source":"github","repo":"petekp/inbox"}}}}'
    [ "${status}" -eq 0 ]
    run jq -e '.extraKnownMarketplaces.inbox.source == {"source":"github","repo":"shunk031/inbox","ref":"v0.3.0-fork.1"}' <<< "${output}"
    [ "${status}" -eq 0 ]
}

@test "[common] Claude settings modifier creates initial Fable low-effort defaults" {
    run chezmoi "${CHEZMOI_TEMPLATE_ARGS[@]}" execute-template --with-stdin --file "${CLAUDE_SETTINGS_MODIFIER_PATH}" < /dev/null
    [ "${status}" -eq 0 ]

    run jq -e 'type == "object" and .model == "fable" and .modelSettings["claude-fable-5-2"].effortLevel == "low" and .modelSettings["claude-opus-5-5"].effortLevel == "high" and .alwaysThinkingEnabled == true and .promptSuggestionEnabled == false and .enabledPlugins["inbox@inbox"] == true' <<< "${output}"
    [ "${status}" -eq 0 ]
}

@test "[common] Claude settings modifier retains all current shared values" {
    run chezmoi "${CHEZMOI_TEMPLATE_ARGS[@]}" execute-template --with-stdin --file "${CLAUDE_SETTINGS_MODIFIER_PATH}" < "${CLAUDE_SETTINGS_PATH}"
    [ "${status}" -eq 0 ]

    local actual expected
    actual="$(jq -S . <<< "${output}")"
    expected="$(
        jq --arg command 'command -v node >/dev/null 2>&1 || exit 0; ~/.local/bin/common/markdown-sentence-length pre claude' '
            def markdown_hook: {"type":"command","command":$command,"timeout":120};
            .hooks.PreToolUse |= (
                if any(.[]; .matcher == "Bash") then
                    map(if .matcher == "Bash" then .hooks += [markdown_hook] else . end)
                else
                    [{"matcher":"Bash","hooks":[markdown_hook]}] + .
                end
            )' "${CLAUDE_SETTINGS_PATH}" | jq -S .
    )"
    [ "${actual}" = "${expected}" ]
}

@test "[common] Claude sentence-length hooks fail open when Node.js is unavailable" {
    local empty_bin="${BATS_TEST_TMPDIR}/empty-bin"
    local rendered hook_command command_count

    mkdir -p "${empty_bin}"
    run chezmoi "${CHEZMOI_TEMPLATE_ARGS[@]}" execute-template --with-stdin --file "${CLAUDE_SETTINGS_MODIFIER_PATH}" < "${CLAUDE_SETTINGS_PATH}"
    [ "${status}" -eq 0 ]
    rendered="${output}"

    command_count="$(jq '[.. | objects | .command? // empty | select(contains("markdown-sentence-length"))] | length' <<< "${rendered}")"
    [ "${command_count}" -eq 4 ]
    while IFS= read -r hook_command; do
        run /usr/bin/env -i "PATH=${empty_bin}" "HOME=${HOME}" /bin/sh -c "${hook_command}"
        [ "${status}" -eq 0 ]
        [ -z "${output}" ]
    done < <(jq -r '.. | objects | .command? // empty | select(contains("markdown-sentence-length"))' <<< "${rendered}")
}

@test "[common] Claude settings modifier preserves user state and overrides managed keys" {
    run chezmoi "${CHEZMOI_TEMPLATE_ARGS[@]}" execute-template --with-stdin --file "${CLAUDE_SETTINGS_MODIFIER_PATH}" <<< '{"model":"sonnet","runtimeOnly":{"enabled":true},"env":{"USER_VALUE":"keep"},"alwaysThinkingEnabled":false}'
    [ "${status}" -eq 0 ]

    run jq -e '.model == "fable" and .modelSettings["claude-fable-5-2"].effortLevel == "low" and .runtimeOnly.enabled == true and .env.USER_VALUE == "keep" and .alwaysThinkingEnabled == true' <<< "${output}"
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

    run jq -e '.model == "fable" and .modelSettings["claude-fable-5-2"].effortLevel == "low" and .runtimeOnly.enabled == true' "${settings}"
    [ "${status}" -eq 0 ]

    run cmp "${source_settings_before}" "${source_settings}"
    [ "${status}" -eq 0 ]
}
