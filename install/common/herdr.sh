#!/usr/bin/env bash

# @file install/common/herdr.sh
# @brief Install Herdr integrations and skill assets.
# @description
#   Activates `mise` when available, installs Herdr integrations for configured
#   coding agents, and syncs the shared Herdr skill from the installed binary.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly MISE_BIN="${HOME}/.local/bin/mise"
readonly HERDR_SKILL_PATH="${HOME}/.agents/skills/herdr/SKILL.md"

readonly HERDR_INTEGRATIONS=(
    claude
)

#
# @description Activate `mise` so Herdr and skills resolve from the configured toolchain.
#
function activate_mise() {
    if [ -x "${MISE_BIN}" ]; then
        eval "$("${MISE_BIN}" activate bash)"
    fi
}

#
# @description Install Herdr with `mise`.
#
function install_herdr() {
    "${MISE_BIN}" install herdr
}

#
# @description Install Herdr integrations for every configured coding agent.
#
function install_herdr_integrations() {
    for integration in "${HERDR_INTEGRATIONS[@]}"; do
        "${MISE_BIN}" exec -- herdr integration install "${integration}"
    done
}

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

#
# @description Run the Herdr installation workflow.
#
function main() {
    activate_mise
    install_herdr
    install_herdr_integrations
    sync_herdr_skill
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
