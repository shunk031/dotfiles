#!/usr/bin/env bash

# @file install/common/agent_skills.sh
# @brief Install shared agent skills.
# @description
#   Activates `mise` when available and installs globally configured skills for
#   coding agents. Start with Claude Code and keep the agent list explicit so
#   Codex or other agents can be added without changing the installer flow.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly MISE_BIN="${HOME}/.local/bin/mise"
readonly SKILL_CREATOR_REPO="https://github.com/anthropics/skills"
readonly SKILL_CREATOR_NAME="skill-creator"
readonly SKILL_CREATOR_AGENTS=(
    claude-code
)

#
# @description Activate `mise` so the skills CLI resolves from the configured toolchain.
#
function activate_mise() {
    if [ -x "${MISE_BIN}" ]; then
        eval "$("${MISE_BIN}" activate bash)"
    fi
}

#
# @description Install the Skill Creator skill globally for configured agents.
#
function install_skill_creator() {
    "${MISE_BIN}" exec npm:skills -- skills add "${SKILL_CREATOR_REPO}" \
        --skill "${SKILL_CREATOR_NAME}" \
        --agent "${SKILL_CREATOR_AGENTS[@]}" \
        --global \
        --yes
}

#
# @description Install all shared agent skills.
#
function install_agent_skills() {
    install_skill_creator
}

#
# @description Run the agent skill installation workflow.
#
function main() {
    activate_mise
    install_agent_skills
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
