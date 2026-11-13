#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/claude-plugins.sh"
readonly TMPL_SCRIPT_PATH="./home/.chezmoiscripts/common/run_after_25-install-claude-plugins.sh.tmpl"
readonly CLAUDE_SETTINGS_PATH="./home/private_dot_config/claude/settings.json"
readonly CLAUDE_SETTINGS_MODIFIER_PATH="./home/dot_claude/modify_settings.json"

function setup() {
    export HOME="${BATS_TEST_TMPDIR}/home"
    REAL_GIT_BIN="$(command -v git)"
    export REAL_GIT_BIN
    mkdir -p "${HOME}/.local/bin"

    CHEZMOI_TEMPLATE_SOURCE="${BATS_TEST_TMPDIR}/chezmoi-source"
    CHEZMOI_TEMPLATE_DESTINATION="${HOME}"
    mkdir -p "${CHEZMOI_TEMPLATE_SOURCE}" "${CHEZMOI_TEMPLATE_DESTINATION}"
    CHEZMOI_TEMPLATE_ARGS=(
        --source "${CHEZMOI_TEMPLATE_SOURCE}"
        --destination "${CHEZMOI_TEMPLATE_DESTINATION}"
        --config /dev/null
        --config-format toml
    )

    MOCK_BIN="${BATS_TEST_TMPDIR}/bin"
    MOCK_GIT_CALLS_PATH="${BATS_TEST_TMPDIR}/git_calls.txt"
    MOCK_CLAUDE_CALLS_PATH="${BATS_TEST_TMPDIR}/claude_calls.txt"
}

function teardown() {
    chmod -R u+w "${BATS_TEST_TMPDIR}" 2> /dev/null || true
}

function write_claude_workflow_mocks() {
    mkdir -p "${MOCK_BIN}"
    export MOCK_BIN MOCK_GIT_CALLS_PATH MOCK_CLAUDE_CALLS_PATH
    export CLAUDE_PLUGIN_LIST_JSON='[]'
    export CLAUDE_MARKETPLACE_LIST_JSON='[]'
    export MOCK_GIT_DIRTY=0 MOCK_GIT_FAIL_PULL=0
    export MOCK_GIT_BRANCH=main MOCK_GIT_UPSTREAM=origin/main
    export MOCK_GIT_HEAD=main-commit MOCK_GIT_UPSTREAM_HEAD=main-commit
    export MOCK_CLAUDE_REQUIRE_BACKUP=0

    cat > "${HOME}/.local/bin/mise" << 'MOCK_MISE'
#!/usr/bin/env bash
if [ "$1" = "exec" ]; then
    [ "${2:-}" = "--" ] || exit 1
    shift 2
    "$@"
fi
MOCK_MISE
    chmod +x "${HOME}/.local/bin/mise"

    cat > "${MOCK_BIN}/git" << 'MOCK_GIT'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${MOCK_GIT_CALLS_PATH}"
if [ "${1:-}" = "clone" ]; then
    [ "$#" -eq 6 ] || exit 2
    [ "$2" = "--branch" ] && [ "$3" = "main" ] && [ "$4" = "--single-branch" ] || exit 2
    [ "$5" = "https://github.com/shunk031/inbox" ] || exit 2
    mkdir -p "$6/.git"
    exit
fi
[ "${1:-}" = "-C" ] || exit 2
repo_dir="$2"
shift 2
case "$*" in
    "rev-parse --show-prefix") printf '' ;;
    "branch --show-current") printf '%s\n' "${MOCK_GIT_BRANCH}" ;;
    "config --get remote.origin.url") "${REAL_GIT_BIN}" -C "${repo_dir}" config --get remote.origin.url ;;
    "remote get-url origin") "${REAL_GIT_BIN}" -C "${repo_dir}" remote get-url origin ;;
    "status --porcelain --untracked-files=all")
        if [ "${MOCK_GIT_DIRTY}" = "1" ]; then printf ' M local-change\n'; fi
        ;;
    "rev-parse --abbrev-ref --symbolic-full-name @{upstream}") printf '%s\n' "${MOCK_GIT_UPSTREAM}" ;;
    "pull --ff-only") [ "${MOCK_GIT_FAIL_PULL}" != "1" ] ;;
    "rev-parse HEAD") printf '%s\n' "${MOCK_GIT_HEAD}" ;;
    "rev-parse @{upstream}") printf '%s\n' "${MOCK_GIT_UPSTREAM_HEAD}" ;;
    *) printf 'Unexpected git command: %s\n' "$*" >&2; exit 2 ;;
esac
MOCK_GIT
    chmod +x "${MOCK_BIN}/git"

    cat > "${MOCK_BIN}/claude" << 'MOCK_CLAUDE'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${MOCK_CLAUDE_CALLS_PATH}"
case "$*" in
    "plugin list --json")
        if [ -n "${CLAUDE_PLUGIN_LIST_FILE:-}" ]; then
            cat "${CLAUDE_PLUGIN_LIST_FILE}"
        else
            printf '%s\n' "${CLAUDE_PLUGIN_LIST_JSON:-[]}"
        fi
        ;;
    "plugin marketplace list --json") printf '%s\n' "${CLAUDE_MARKETPLACE_LIST_JSON}" ;;
    "plugin uninstall inbox@inbox --scope user --keep-data")
        if [ "${MOCK_CLAUDE_REQUIRE_BACKUP}" = "1" ]; then
            [ -f "${CLAUDE_EXPECT_BACKUP_FILE}" ] || exit 3
            if stat -f '%Lp' "${CLAUDE_EXPECT_BACKUP_FILE}" >/dev/null 2>&1; then
                mode="$(stat -f '%Lp' "${CLAUDE_EXPECT_BACKUP_FILE}")"
            else
                mode="$(stat -c '%a' "${CLAUDE_EXPECT_BACKUP_FILE}")"
            fi
            case "${mode}" in *[2367]*) exit 4 ;; esac
            [ -d "${CLAUDE_EXPECT_BACKUP_DIR}" ] || exit 4
            if stat -f '%Lp' "${CLAUDE_EXPECT_BACKUP_DIR}" >/dev/null 2>&1; then
                mode="$(stat -f '%Lp' "${CLAUDE_EXPECT_BACKUP_DIR}")"
            else
                mode="$(stat -c '%a' "${CLAUDE_EXPECT_BACKUP_DIR}")"
            fi
            case "${mode}" in *[2367]*) exit 4 ;; esac
        fi
        [ "${CLAUDE_FAIL_UNINSTALL:-0}" != "1" ] || exit 5
        if [ -n "${CLAUDE_PLUGIN_LIST_FILE:-}" ]; then
            printf '[]\n' > "${CLAUDE_PLUGIN_LIST_FILE}"
        fi
        ;;
    "plugin marketplace remove inbox") : ;;
    *) printf 'Unexpected Claude command: %s\n' "$*" >&2; exit 2 ;;
esac
MOCK_CLAUDE
    chmod +x "${MOCK_BIN}/claude"
    export PATH="${MOCK_BIN}:${PATH}"
}

function inbox_plugin_dir() {
    printf '%s\n' "${HOME}/.local/share/claude/plugins/inbox"
}

function create_existing_clone() {
    local clone_dir="$(inbox_plugin_dir)"
    mkdir -p "${clone_dir}"
    "${REAL_GIT_BIN}" init --quiet "${clone_dir}"
    "${REAL_GIT_BIN}" -C "${clone_dir}" remote add origin https://github.com/shunk031/inbox
}

function use_fixed_backup_time() {
    cat > "${MOCK_BIN}/date" << 'MOCK_DATE'
#!/usr/bin/env bash
case "$1" in
    '+%Y-%m-%d') printf '2026-11-13\n' ;;
    '+%H%M%S') printf '010203\n' ;;
    *) exit 2 ;;
esac
MOCK_DATE
    chmod +x "${MOCK_BIN}/date"
}

function run_claude_plugin_script() {
    run env HOME="${HOME}" bash "${SCRIPT_PATH}"
}

function file_mode() {
    if stat -f '%Lp' "$1" > /dev/null 2>&1; then
        stat -f '%Lp' "$1"
    else
        stat -c '%a' "$1"
    fi
}

@test "[common] Claude plugins run-after template includes the installer" {
    run cat "${TMPL_SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = '{{ include "../install/common/claude-plugins.sh" }}' ]
}

@test "[common] Claude plugins script clones inbox main when missing" {
    write_claude_workflow_mocks

    run_claude_plugin_script
    [ "${status}" -eq 0 ]
    [ -d "$(inbox_plugin_dir)/.git" ]

    run cat "${MOCK_GIT_CALLS_PATH}"
    [ "${lines[0]}" = "clone --branch main --single-branch https://github.com/shunk031/inbox $(inbox_plugin_dir)" ]

    run cat "${MOCK_CLAUDE_CALLS_PATH}"
    [ "${lines[0]}" = "plugin list --json" ]
    [ "${#lines[@]}" -eq 1 ]
}

@test "[common] Claude plugins script fast-forwards an existing clean main clone" {
    write_claude_workflow_mocks
    create_existing_clone

    run_claude_plugin_script
    [ "${status}" -eq 0 ]
    run grep -Fx -- "-C $(inbox_plugin_dir) pull --ff-only" "${MOCK_GIT_CALLS_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] Claude plugins script reads the literal origin despite insteadOf" {
    write_claude_workflow_mocks
    create_existing_clone
    local global_git_config="${BATS_TEST_TMPDIR}/gitconfig"
    cat > "${global_git_config}" << 'GIT_CONFIG'
[url "https://mirror.example/"]
	insteadOf = https://github.com/
GIT_CONFIG
    export GIT_CONFIG_GLOBAL="${global_git_config}"

    run_claude_plugin_script
    [ "${status}" -eq 0 ]
    run grep -Fx -- "-C $(inbox_plugin_dir) config --get remote.origin.url" "${MOCK_GIT_CALLS_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] Claude plugins script refuses a symlinked inbox path" {
    write_claude_workflow_mocks
    local target="${BATS_TEST_TMPDIR}/inbox-target"
    mkdir -p "${target}/.git" "${HOME}/.local/share/claude/plugins"
    ln -s "${target}" "$(inbox_plugin_dir)"

    run_claude_plugin_script
    [ "${status}" -ne 0 ]
    [ ! -e "${MOCK_CLAUDE_CALLS_PATH}" ]
}

@test "[common] Claude plugins script refuses a branch other than main" {
    write_claude_workflow_mocks
    create_existing_clone
    export MOCK_GIT_BRANCH=feature

    run_claude_plugin_script
    [ "${status}" -ne 0 ]
    [ ! -e "${MOCK_CLAUDE_CALLS_PATH}" ]
}

@test "[common] Claude plugins script refuses the wrong origin" {
    write_claude_workflow_mocks
    create_existing_clone
    "${REAL_GIT_BIN}" -C "$(inbox_plugin_dir)" config remote.origin.url https://example.invalid/inbox

    run_claude_plugin_script
    [ "${status}" -ne 0 ]
    [ ! -e "${MOCK_CLAUDE_CALLS_PATH}" ]
}

@test "[common] Claude plugins script refuses the wrong upstream" {
    write_claude_workflow_mocks
    create_existing_clone
    export MOCK_GIT_UPSTREAM=origin/other

    run_claude_plugin_script
    [ "${status}" -ne 0 ]
    [ ! -e "${MOCK_CLAUDE_CALLS_PATH}" ]
}

@test "[common] Claude plugins script refuses a clone still behind after pull" {
    write_claude_workflow_mocks
    create_existing_clone
    export MOCK_GIT_HEAD=stale-commit

    run_claude_plugin_script
    [ "${status}" -ne 0 ]
    run grep -Fx -- "-C $(inbox_plugin_dir) pull --ff-only" "${MOCK_GIT_CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [ ! -e "${MOCK_CLAUDE_CALLS_PATH}" ]
}

@test "[common] Claude plugins script refuses a dirty inbox clone" {
    write_claude_workflow_mocks
    create_existing_clone
    export MOCK_GIT_DIRTY=1 CLAUDE_PLUGIN_LIST_JSON='[{"id":"inbox@inbox","enabled":true}]'

    run_claude_plugin_script
    [ "${status}" -ne 0 ]
    [ ! -e "${MOCK_CLAUDE_CALLS_PATH}" ]
}

@test "[common] Claude plugins script refuses a clone that cannot fast-forward" {
    write_claude_workflow_mocks
    create_existing_clone
    export MOCK_GIT_FAIL_PULL=1 CLAUDE_PLUGIN_LIST_JSON='[{"id":"inbox@inbox","enabled":true}]'

    run_claude_plugin_script
    [ "${status}" -ne 0 ]
    [ ! -e "${MOCK_CLAUDE_CALLS_PATH}" ]
}

@test "[common] Claude plugins script fails on invalid plugin list JSON" {
    write_claude_workflow_mocks
    create_existing_clone
    export CLAUDE_PLUGIN_LIST_JSON='[{"id":'

    run_claude_plugin_script
    [ "${status}" -ne 0 ]

    run cat "${MOCK_CLAUDE_CALLS_PATH}"
    [ "${lines[0]}" = "plugin list --json" ]
    [ "${#lines[@]}" -eq 1 ]
}

@test "[common] Claude plugins script backs up read-only store files before uninstalling" {
    write_claude_workflow_mocks
    local config_dir="${BATS_TEST_TMPDIR}/claude-config"
    local state_dir="${BATS_TEST_TMPDIR}/state"
    local source_file="${config_dir}/plugins/store/inbox_inbox-session.json"
    local second_source_file="${config_dir}/plugins/store/inbox_inbox-project.json"
    local backup_file="${state_dir}/inbox-store-backup/$(date '+%Y-%m-%d')/inbox_inbox-session.json"
    local second_backup_file="${state_dir}/inbox-store-backup/$(date '+%Y-%m-%d')/inbox_inbox-project.json"
    create_existing_clone
    mkdir -p "${config_dir}/plugins/store"
    printf '{"saved":true}\n' > "${source_file}"
    printf '{"saved":"project"}\n' > "${second_source_file}"
    export CLAUDE_CONFIG_DIR="${config_dir}" XDG_STATE_HOME="${state_dir}"
    export CLAUDE_PLUGIN_LIST_JSON='[{"id":"inbox@inbox","enabled":true}]'
    export MOCK_CLAUDE_REQUIRE_BACKUP=1 CLAUDE_EXPECT_BACKUP_FILE="${backup_file}"
    export CLAUDE_EXPECT_BACKUP_DIR="$(dirname "${backup_file}")"

    run_claude_plugin_script
    [ "${status}" -eq 0 ]
    [ -f "${backup_file}" ]
    [ -f "${second_backup_file}" ]
    [ "$(file_mode "${CLAUDE_EXPECT_BACKUP_DIR}")" = "500" ]
    [ "$(file_mode "${backup_file}")" = "400" ]
    [ "$(file_mode "${second_backup_file}")" = "400" ]

    run cat "${MOCK_CLAUDE_CALLS_PATH}"
    [ "${lines[0]}" = "plugin list --json" ]
    [ "${lines[1]}" = "plugin uninstall inbox@inbox --scope user --keep-data" ]
    [ "${lines[2]}" = "plugin marketplace list --json" ]
    [ "${#lines[@]}" -eq 3 ]
}

@test "[common] Claude plugins script removes the inbox marketplace after uninstall" {
    write_claude_workflow_mocks
    create_existing_clone
    export CLAUDE_PLUGIN_LIST_JSON='[{"id":"inbox@inbox","enabled":true}]'
    export CLAUDE_MARKETPLACE_LIST_JSON='[{"name":"inbox"}]'

    run_claude_plugin_script
    [ "${status}" -eq 0 ]

    run cat "${MOCK_CLAUDE_CALLS_PATH}"
    [ "${lines[0]}" = "plugin list --json" ]
    [ "${lines[1]}" = "plugin uninstall inbox@inbox --scope user --keep-data" ]
    [ "${lines[2]}" = "plugin marketplace list --json" ]
    [ "${lines[3]}" = "plugin marketplace remove inbox" ]
    [ "${#lines[@]}" -eq 4 ]
}

@test "[common] Claude plugins script adds a time suffix when today's backup folder exists" {
    write_claude_workflow_mocks
    local config_dir="${BATS_TEST_TMPDIR}/claude-config"
    local state_dir="${BATS_TEST_TMPDIR}/state"
    local backup_root="${state_dir}/inbox-store-backup"
    local source_file="${config_dir}/plugins/store/inbox_inbox-session.json"
    local date_dir="${backup_root}/2026-11-13"
    local backup_dir="${backup_root}/2026-11-13-010203"
    create_existing_clone
    mkdir -p "${config_dir}/plugins/store" "${date_dir}"
    printf 'keep\n' > "${date_dir}/existing.json"
    printf '{"saved":true}\n' > "${source_file}"
    use_fixed_backup_time
    export CLAUDE_CONFIG_DIR="${config_dir}" XDG_STATE_HOME="${state_dir}"
    export CLAUDE_PLUGIN_LIST_JSON='[{"id":"inbox@inbox","enabled":true}]'

    run_claude_plugin_script
    [ "${status}" -eq 0 ]
    [ -f "${backup_dir}/inbox_inbox-session.json" ]
    [ "$(cat "${date_dir}/existing.json")" = "keep" ]
}

@test "[common] Claude plugins script keeps a failed uninstall backup and suffixes the retry" {
    write_claude_workflow_mocks
    create_existing_clone
    use_fixed_backup_time
    local config_dir="${BATS_TEST_TMPDIR}/claude-config"
    local state_dir="${BATS_TEST_TMPDIR}/state"
    local store_dir="${config_dir}/plugins/store"
    local backup_root="${state_dir}/inbox-store-backup"
    local source_file="${store_dir}/inbox_inbox-session.json"
    local date_dir="${backup_root}/2026-11-13"
    local retry_dir="${backup_root}/2026-11-13-010203"
    mkdir -p "${store_dir}"
    printf '{"saved":true}\n' > "${source_file}"
    export CLAUDE_CONFIG_DIR="${config_dir}" XDG_STATE_HOME="${state_dir}"
    export CLAUDE_PLUGIN_LIST_JSON='[{"id":"inbox@inbox","enabled":true}]'
    export CLAUDE_FAIL_UNINSTALL=1

    run_claude_plugin_script
    [ "${status}" -ne 0 ]
    [ -f "${date_dir}/inbox_inbox-session.json" ]

    export CLAUDE_FAIL_UNINSTALL=0
    run_claude_plugin_script
    [ "${status}" -eq 0 ]
    [ -f "${date_dir}/inbox_inbox-session.json" ]
    [ -f "${retry_dir}/inbox_inbox-session.json" ]
}

@test "[common] Claude plugins script refuses an existing time-suffixed backup folder" {
    write_claude_workflow_mocks
    create_existing_clone
    use_fixed_backup_time
    local config_dir="${BATS_TEST_TMPDIR}/claude-config"
    local state_dir="${BATS_TEST_TMPDIR}/state"
    local store_dir="${config_dir}/plugins/store"
    local backup_root="${state_dir}/inbox-store-backup"
    local date_dir="${backup_root}/2026-11-13"
    local retry_dir="${backup_root}/2026-11-13-010203"
    mkdir -p "${store_dir}" "${date_dir}" "${retry_dir}"
    printf 'preserve\n' > "${retry_dir}/existing.json"
    printf '{"saved":true}\n' > "${store_dir}/inbox_inbox-session.json"
    export CLAUDE_CONFIG_DIR="${config_dir}" XDG_STATE_HOME="${state_dir}"
    export CLAUDE_PLUGIN_LIST_JSON='[{"id":"inbox@inbox","enabled":true}]'

    run --separate-stderr env HOME="${HOME}" bash "${SCRIPT_PATH}"
    [ "${status}" -ne 0 ]
    [[ "${stderr}" == *"Cannot create inbox store backup directory"* ]]
    [ "$(cat "${retry_dir}/existing.json")" = "preserve" ]
    run cat "${MOCK_CLAUDE_CALLS_PATH}"
    [ "${lines[0]}" = "plugin list --json" ]
    [ "${#lines[@]}" -eq 1 ]
}

@test "[common] Claude plugins script stops before uninstall when store backup fails" {
    write_claude_workflow_mocks
    local config_dir="${BATS_TEST_TMPDIR}/claude-config"
    local state_dir="${BATS_TEST_TMPDIR}/state"
    create_existing_clone
    mkdir -p "${config_dir}/plugins/store"
    printf '{"saved":true}\n' > "${config_dir}/plugins/store/inbox_inbox-session.json"
    cat > "${MOCK_BIN}/cp" << 'MOCK_CP'
#!/usr/bin/env bash
exit 1
MOCK_CP
    chmod +x "${MOCK_BIN}/cp"
    export CLAUDE_CONFIG_DIR="${config_dir}" XDG_STATE_HOME="${state_dir}"
    export CLAUDE_PLUGIN_LIST_JSON='[{"id":"inbox@inbox","enabled":true}]'

    run_claude_plugin_script
    [ "${status}" -ne 0 ]

    run cat "${MOCK_CLAUDE_CALLS_PATH}"
    [ "${lines[0]}" = "plugin list --json" ]
    [ "${#lines[@]}" -eq 1 ]
}

@test "[common] Claude plugins script skips store backup when no source file exists" {
    write_claude_workflow_mocks
    local config_dir="${BATS_TEST_TMPDIR}/claude-config"
    local state_dir="${BATS_TEST_TMPDIR}/state"
    create_existing_clone
    mkdir -p "${config_dir}/plugins/store"
    export CLAUDE_CONFIG_DIR="${config_dir}" XDG_STATE_HOME="${state_dir}"
    export CLAUDE_PLUGIN_LIST_JSON='[{"id":"inbox@inbox","enabled":true}]'

    run_claude_plugin_script
    [ "${status}" -eq 0 ]
    [ ! -e "${state_dir}/inbox-store-backup" ]
    run grep -Fx -- "plugin uninstall inbox@inbox --scope user --keep-data" "${MOCK_CLAUDE_CALLS_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] Claude plugins script does not back up or uninstall on later applies" {
    write_claude_workflow_mocks
    local config_dir="${BATS_TEST_TMPDIR}/claude-config"
    local state_dir="${BATS_TEST_TMPDIR}/state"
    local source_file="${config_dir}/plugins/store/inbox_inbox-session.json"
    local list_file="${BATS_TEST_TMPDIR}/plugins.json"
    create_existing_clone
    mkdir -p "${config_dir}/plugins/store"
    printf '{"saved":true}\n' > "${source_file}"
    printf '[{"id":"inbox@inbox","enabled":true}]\n' > "${list_file}"
    export CLAUDE_CONFIG_DIR="${config_dir}" XDG_STATE_HOME="${state_dir}"
    export CLAUDE_PLUGIN_LIST_FILE="${list_file}"
    export MOCK_CLAUDE_REQUIRE_BACKUP=1
    export CLAUDE_EXPECT_BACKUP_FILE="${state_dir}/inbox-store-backup/$(date '+%Y-%m-%d')/inbox_inbox-session.json"
    export CLAUDE_EXPECT_BACKUP_DIR="${state_dir}/inbox-store-backup/$(date '+%Y-%m-%d')"

    run_claude_plugin_script
    [ "${status}" -eq 0 ]
    run_claude_plugin_script
    [ "${status}" -eq 0 ]

    run grep -Fc -- "plugin uninstall inbox@inbox --scope user --keep-data" "${MOCK_CLAUDE_CALLS_PATH}"
    [ "${output}" = "1" ]
    run find "${state_dir}/inbox-store-backup" -mindepth 1 -maxdepth 1 -type d
    [ "${#lines[@]}" -eq 1 ]
    run grep -Fc -- "-C $(inbox_plugin_dir) pull --ff-only" "${MOCK_GIT_CALLS_PATH}"
    [ "${output}" = "2" ]
}

@test "[common] Claude settings disable Ponytail and remove the inbox marketplace route" {
    run jq -e '.enabledPlugins["ponytail@ponytail"] == false and .env.CLAUDE_CODE_PLUGIN_DIRS == "~/.local/share/claude/plugins/inbox" and (.enabledPlugins | has("inbox@inbox") | not) and (.extraKnownMarketplaces | has("ponytail") | not) and (.extraKnownMarketplaces | has("inbox") | not)' "${CLAUDE_SETTINGS_PATH}"
    [ "${status}" -eq 0 ]

    run chezmoi "${CHEZMOI_TEMPLATE_ARGS[@]}" execute-template --with-stdin --file "${CLAUDE_SETTINGS_MODIFIER_PATH}" < /dev/null
    [ "${status}" -eq 0 ]
    run jq -e '.enabledPlugins["ponytail@ponytail"] == false and (.enabledPlugins | has("inbox@inbox") | not) and (.extraKnownMarketplaces | has("ponytail") | not) and (.extraKnownMarketplaces | has("inbox") | not)' <<< "${output}"
    [ "${status}" -eq 0 ]
}

@test "[common] Claude settings remove a previous inbox route and preserve other plugins" {
    run chezmoi "${CHEZMOI_TEMPLATE_ARGS[@]}" execute-template --with-stdin --file "${CLAUDE_SETTINGS_MODIFIER_PATH}" <<< '{"enabledPlugins":{"ponytail@ponytail":true,"inbox@inbox":true,"other@other":true},"extraKnownMarketplaces":{"ponytail":{"source":{"source":"github","repo":"ponytail/ponytail"}},"inbox":{"source":{"source":"github","repo":"shunk031/inbox","ref":"main"}},"other":{"source":{"source":"github","repo":"other/repo"}}}}'
    [ "${status}" -eq 0 ]

    run jq -e '.enabledPlugins["ponytail@ponytail"] == false and (.enabledPlugins | has("inbox@inbox") | not) and .enabledPlugins["other@other"] == true and (.extraKnownMarketplaces | has("ponytail") | not) and (.extraKnownMarketplaces | has("inbox") | not) and .extraKnownMarketplaces.other.source.repo == "other/repo"' <<< "${output}"
    [ "${status}" -eq 0 ]
}

@test "[common] Claude settings modifier renders the watched inbox clone and keeps recorded items" {
    local clone_dir="~/.local/share/claude/plugins/inbox"

    run chezmoi "${CHEZMOI_TEMPLATE_ARGS[@]}" execute-template --with-stdin --file "${CLAUDE_SETTINGS_MODIFIER_PATH}" < /dev/null
    [ "${status}" -eq 0 ]
    run jq -e --arg clone_dir "${clone_dir}" '.env.CLAUDE_CODE_PLUGIN_DIRS == $clone_dir and .env.CLAUDE_CODE_PLUGIN_DIR_WATCH == "1" and .env.INBOX_RECORDED_ITEMS_ONLY == "1" and (.enabledPlugins | has("inbox@inbox") | not) and (.extraKnownMarketplaces | has("inbox") | not)' <<< "${output}"
    [ "${status}" -eq 0 ]

    run chezmoi "${CHEZMOI_TEMPLATE_ARGS[@]}" execute-template --with-stdin --file "${CLAUDE_SETTINGS_MODIFIER_PATH}" <<< '{"env":{"CLAUDE_CODE_PLUGIN_DIRS":"~/.local/share/claude/plugins/inbox:/user/plugins:/another/plugins","CLAUDE_CODE_PLUGIN_DIR_WATCH":"0","INBOX_RECORDED_ITEMS_ONLY":"0"}}'
    [ "${status}" -eq 0 ]
    run jq -e --arg clone_dir "${clone_dir}" '.env.CLAUDE_CODE_PLUGIN_DIRS == ($clone_dir + ":/user/plugins:/another/plugins") and .env.CLAUDE_CODE_PLUGIN_DIR_WATCH == "1" and .env.INBOX_RECORDED_ITEMS_ONLY == "1"' <<< "${output}"
    [ "${status}" -eq 0 ]
}

@test "[common] Claude subagent feed hooks preserve existing hooks and render once" {
    local rendered command
    command="bash \"\$HOME/.local/bin/common/claude-subagent-feed\""

    run jq -e --arg command "${command}" '
        ([.hooks.PostToolUse[] | select(.matcher == "Agent") | .hooks[] | select(.command == $command and .async == true)] | length) == 1
        and ([.hooks.SubagentStop[] | select(has("matcher") | not) | .hooks[] | select(.command == $command and .async == true)] | length) == 1
        and any(.hooks.PostToolUse[]; .matcher == "Write|Edit|MultiEdit")
    ' "${CLAUDE_SETTINGS_PATH}"
    [ "${status}" -eq 0 ]

    run chezmoi "${CHEZMOI_TEMPLATE_ARGS[@]}" execute-template --with-stdin --file "${CLAUDE_SETTINGS_MODIFIER_PATH}" < "${CLAUDE_SETTINGS_PATH}"
    [ "${status}" -eq 0 ]
    rendered="${output}"
    run jq -e --arg command "${command}" '
        ([.hooks.PostToolUse[] | select(.matcher == "Agent") | .hooks[] | select(.command == $command and .async == true)] | length) == 1
        and ([.hooks.SubagentStop[] | select(has("matcher") | not) | .hooks[] | select(.command == $command and .async == true)] | length) == 1
        and any(.hooks.PostToolUse[]; .matcher == "Write|Edit|MultiEdit")
        and any(.hooks.PreToolUse[]; .matcher == "Bash")
        and any(.hooks.SessionStart[]; .matcher == "^(startup|resume|clear|compact|fork)$")
        and any(.hooks.Stop[].hooks[]; .command | contains("markdown-sentence-length stop claude"))
    ' <<< "${rendered}"
    [ "${status}" -eq 0 ]

    run chezmoi "${CHEZMOI_TEMPLATE_ARGS[@]}" execute-template --with-stdin --file "${CLAUDE_SETTINGS_MODIFIER_PATH}" <<< "${rendered}"
    [ "${status}" -eq 0 ]
    run jq -e --arg command "${command}" '
        ([.hooks.PostToolUse[] | select(.matcher == "Agent") | .hooks[] | select(.command == $command and .async == true)] | length) == 1
        and ([.hooks.SubagentStop[] | select(has("matcher") | not) | .hooks[] | select(.command == $command and .async == true)] | length) == 1
    ' <<< "${output}"
    [ "${status}" -eq 0 ]
}

@test "[common] Claude settings modifier creates initial Fable low-effort defaults" {
    run chezmoi "${CHEZMOI_TEMPLATE_ARGS[@]}" execute-template --with-stdin --file "${CLAUDE_SETTINGS_MODIFIER_PATH}" < /dev/null
    [ "${status}" -eq 0 ]

    run jq -e 'type == "object" and .model == "fable" and .modelSettings["claude-fable-5-2"].effortLevel == "low" and .modelSettings["claude-opus-5-5"].effortLevel == "high" and .alwaysThinkingEnabled == true and .promptSuggestionEnabled == false and (.enabledPlugins | has("inbox@inbox") | not) and .env.CLAUDE_CODE_PLUGIN_DIR_WATCH == "1" and .env.INBOX_RECORDED_ITEMS_ONLY == "1"' <<< "${output}"
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
