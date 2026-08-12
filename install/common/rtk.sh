#!/usr/bin/env bash

# @file install/common/rtk.sh
# @brief Initialize RTK integrations for the configured agent CLIs.
# @description
#   Activates mise, removes only legacy RTK symlinks owned by this dotfiles
#   source, and lets the pinned RTK binary generate its agent-specific files.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly MISE_BIN="${HOME}/.local/bin/mise"

if [ -z "${RTK_SOURCE_DIR:-}" ]; then
    RTK_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
    readonly RTK_SCRIPT_DIR
    RTK_SOURCE_DIR="$(cd -- "${RTK_SCRIPT_DIR}/../../home" && pwd)"
fi

#
# @description Activate `mise` so the configured RTK binary is on `PATH`.
#
function activate_mise() {
    if [ -x "${MISE_BIN}" ]; then
        eval "$("${MISE_BIN}" activate bash)"
    fi
}

#
# @description Remove an old RTK symlink only when it points to this source.
# @arg $1 target_path Applied home path that may contain the old symlink.
# @arg $2 source_path Source path that proves the symlink is legacy-managed.
#
function remove_legacy_symlink() {
    local target_path="$1"
    local source_path="$2"

    if [ -n "${RTK_SOURCE_DIR}" ] && [ -L "${target_path}" ] &&
        [ "$(readlink "${target_path}")" = "${source_path}" ]; then
        rm "${target_path}"
    fi
}

#
# @description Remove RTK files that the previous PR version managed as symlinks.
#
function remove_legacy_rtk_symlinks() {
    [ -n "${RTK_SOURCE_DIR}" ] || return 0

    remove_legacy_symlink \
        "${HOME}/.claude/RTK.md" \
        "${RTK_SOURCE_DIR}/dot_config/claude/RTK.md"
    remove_legacy_symlink \
        "${HOME}/.codex/RTK.md" \
        "${RTK_SOURCE_DIR}/dot_config/codex/RTK.md"
    remove_legacy_symlink \
        "${HOME}/.gemini/RTK.md" \
        "${RTK_SOURCE_DIR}/dot_config/antigravity-cli/RTK.md"
    remove_legacy_symlink \
        "${HOME}/.gemini/GEMINI.md" \
        "${RTK_SOURCE_DIR}/dot_config/antigravity-cli/GEMINI.md"
    remove_legacy_symlink \
        "${HOME}/.gemini/hooks/rtk-hook-gemini.sh" \
        "${RTK_SOURCE_DIR}/dot_config/antigravity-cli/hooks/rtk-hook-gemini.sh"
}

#
# @description Generate the supported global RTK integrations.
# @see https://www.rtk-ai.app/docs/getting-started/quick-start/
#
function initialize_rtk() {
    rtk init -g --auto-patch
    rtk init -g --gemini --auto-patch
}

#
# @description Run the RTK setup workflow after mise-managed tools are ready.
#
function main() {
    activate_mise
    command -v rtk > /dev/null
    remove_legacy_rtk_symlinks
    initialize_rtk
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
