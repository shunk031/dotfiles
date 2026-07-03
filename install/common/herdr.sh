#!/usr/bin/env bash

# @file install/common/herdr.sh
# @brief Install Herdr integrations and skill assets.
# @description
#   Activates `mise` when available, installs Herdr integrations for configured
#   coding agents, and installs the shared Herdr skill globally.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly MISE_BIN="${HOME}/.local/bin/mise"
readonly HERDR_SKILL_REPO="ogulcancelik/herdr"
readonly HERDR_SKILL_NAME="herdr"
readonly HERDR_SKILL_AGENTS=(
    claude-code
    codex
    antigravity-cli
)

readonly HERDR_INTEGRATIONS=(
    claude
    codex
)

#
# @description Activate `mise` so Herdr and Node.js resolve from the configured toolchain.
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
    mise install herdr
}

#
# @description Install Herdr integrations for every configured coding agent.
#
function install_herdr_integrations() {
    for integration in "${HERDR_INTEGRATIONS[@]}"; do
        herdr integration install "${integration}"
    done
}

#
# @description Install the shared Herdr skill globally.
#
function install_herdr_skill() {
    npx -y skills add "${HERDR_SKILL_REPO}" \
        --skill "${HERDR_SKILL_NAME}" \
        --agent "${HERDR_SKILL_AGENTS[@]}" \
        --global \
        --yes
}

#
# @description Run the Herdr installation workflow.
#
function main() {
    activate_mise
    install_herdr
    install_herdr_integrations
    install_herdr_skill
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
