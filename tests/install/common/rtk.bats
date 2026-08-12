#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/rtk.sh"
readonly TEMPLATE_PATH="./home/.chezmoiscripts/common/run_after_30-install-rtk.sh.tmpl"

function setup() {
    export HOME="${BATS_TEST_TMPDIR}/home"
    mkdir -p "${HOME}"
    source "${SCRIPT_PATH}"
}

@test "[common] initialize_rtk uses the supported global init modes" {
    local calls_path="${BATS_TEST_TMPDIR}/rtk_calls.txt"

    rtk() {
        printf '%s\n' "$*" >> "${calls_path}"
    }

    initialize_rtk

    run cat "${calls_path}"
    [ "${status}" -eq 0 ]
    [ "${output}" = $'init -g --auto-patch\ninit -g --codex\ninit -g --gemini --auto-patch' ]
}

@test "[common] legacy RTK symlinks are removed only when source-owned" {
    local source_root="${BATS_TEST_TMPDIR}/source"
    local unrelated_target="${BATS_TEST_TMPDIR}/unrelated"

    mkdir -p "${HOME}/.claude" "${HOME}/.codex" "${HOME}/.gemini/hooks"
    mkdir -p "${source_root}/dot_config/claude"
    mkdir -p "${source_root}/dot_config/codex"
    mkdir -p "${source_root}/dot_config/antigravity-cli/hooks"

    ln -s "${source_root}/dot_config/claude/RTK.md" "${HOME}/.claude/RTK.md"
    ln -s "${source_root}/dot_config/codex/RTK.md" "${HOME}/.codex/RTK.md"
    ln -s "${unrelated_target}" "${HOME}/.gemini/RTK.md"
    ln -s "${source_root}/dot_config/antigravity-cli/GEMINI.md" "${HOME}/.gemini/GEMINI.md"
    ln -s \
        "${source_root}/dot_config/antigravity-cli/hooks/rtk-hook-gemini.sh" \
        "${HOME}/.gemini/hooks/rtk-hook-gemini.sh"

    RTK_SOURCE_DIR="${source_root}"
    remove_legacy_rtk_symlinks

    [ ! -L "${HOME}/.claude/RTK.md" ]
    [ ! -L "${HOME}/.codex/RTK.md" ]
    [ -L "${HOME}/.gemini/RTK.md" ]
    [ ! -L "${HOME}/.gemini/GEMINI.md" ]
    [ ! -L "${HOME}/.gemini/hooks/rtk-hook-gemini.sh" ]
}

@test "[common] run-after template wires the chezmoi source directory" {
    run grep -F 'DOTFILES_CHEZMOI_SOURCE_DIR="{{ .chezmoi.sourceDir }}"' "${TEMPLATE_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '{{ include "../install/common/rtk.sh" }}' "${TEMPLATE_PATH}"
    [ "${status}" -eq 0 ]
}
