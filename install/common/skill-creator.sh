#!/usr/bin/env bash

# @file install/common/skill-creator.sh
# @brief Install the Claude Code skill-creator skill.
# @description
#   Activates `mise` when available and installs Anthropic's skill-creator
#   skill globally for Claude Code.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly MISE_BIN="${HOME}/.local/bin/mise"
readonly SKILL_CREATOR_REPO="anthropics/skills"
readonly SKILL_CREATOR_NAME="skill-creator"
readonly SKILL_CREATOR_AGENT="claude-code"

#
# @description Activate `mise` so skills resolve from the configured toolchain.
#
function activate_mise() {
    if [ -x "${MISE_BIN}" ]; then
        eval "$("${MISE_BIN}" activate bash)"
    fi
}

#
# @description Install the skill-creator skill globally for Claude Code.
#
function install_skill_creator_skill() {
    "${MISE_BIN}" exec npm:skills -- skills add "${SKILL_CREATOR_REPO}" \
        --skill "${SKILL_CREATOR_NAME}" \
        --agent "${SKILL_CREATOR_AGENT}" \
        --global \
        --yes
}

#
# @description Run the skill-creator installation workflow.
#
function main() {
    activate_mise
    install_skill_creator_skill
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
