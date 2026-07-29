#!/usr/bin/env bash

# @file install/common/skills.sh
# @brief Install upstream agent skills.
# @description
#   Activates `mise` when available and installs installer-managed skills with
#   the pinned `skills` CLI.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly MISE_BIN="${HOME}/.local/bin/mise"

#
# @description Activate `mise` so skills resolve from the configured toolchain.
#
function activate_mise() {
    if [ -x "${MISE_BIN}" ]; then
        eval "$("${MISE_BIN}" activate bash)"
    fi
}

#
# @description Install upstream skills managed by tool-specific installers.
#
function install_skills() {
    [ ! -e "${HOME}/.claude/skills/skill-creator" ] || return 0
    [ -x "${MISE_BIN}" ] || return 0

    "${MISE_BIN}" exec npm:skills -- skills add anthropics/skills \
        --skill skill-creator \
        --agent claude-code \
        --global \
        --yes
}

#
# @description Run the skills installation workflow.
#
function main() {
    activate_mise
    install_skills
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
