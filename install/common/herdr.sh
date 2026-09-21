#!/usr/bin/env bash

# @file install/common/herdr.sh
# @brief Sync skill instructions from the installed Herdr binary.
# @description
#   Agent hooks are managed by chezmoi without invoking Herdr's config editor.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly MISE_BIN="${HOME}/.local/bin/mise"
readonly HERDR_SKILL_PATH="${HOME}/.agents/skills/herdr/SKILL.md"

#
# @description Sync the shared Herdr skill from the installed Herdr binary.
#
function sync_herdr_skill() {
    local skill_dir temp

    skill_dir="$(dirname "${HERDR_SKILL_PATH}")"
    mkdir -p "${skill_dir}"
    temp="$(mktemp "${skill_dir}/.SKILL.md.XXXXXX")" || return 1

    if ! "${MISE_BIN}" exec -- herdr --skill > "${temp}"; then
        rm -f "${temp}"
        return 1
    fi

    mv "${temp}" "${HERDR_SKILL_PATH}"
}
