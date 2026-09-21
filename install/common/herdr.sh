#!/usr/bin/env bash

# @file install/common/herdr.sh
# @brief Sync official hook assets and skill instructions from Herdr.
# @description
#   Integration installers only edit disposable configurations. Agent settings
#   remain source-owned; only the generated hook scripts are published.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly MISE_BIN="${HOME}/.local/bin/mise"
readonly HERDR_SKILL_PATH="${HOME}/.agents/skills/herdr/SKILL.md"

#
# @description Refresh hook assets without editing agent configuration files.
# @arg $@ string Herdr command and any prefix arguments.
function sync_herdr_integrations() (
    set -Eeuo pipefail
    local staging claude_dir codex_dir
    claude_dir="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
    codex_dir="${CODEX_HOME:-${HOME}/.codex}"

    if [ -L "${claude_dir}/hooks" ]; then
        printf '%s\n' 'Run chezmoi apply to migrate the Claude hooks directory before syncing Herdr.' >&2
        return 1
    fi

    staging="$(mktemp -d)"
    trap 'rm -rf -- "${staging}"' EXIT
    mkdir -p "${staging}/claude" "${staging}/codex"
    CLAUDE_CONFIG_DIR="${staging}/claude" "$@" integration install claude
    CODEX_HOME="${staging}/codex" "$@" integration install codex

    mkdir -p "${claude_dir}/hooks" "${codex_dir}"
    install -m 755 "${staging}/claude/hooks/herdr-agent-state.sh" "${claude_dir}/hooks/herdr-agent-state.sh"
    install -m 755 "${staging}/codex/herdr-agent-state.sh" "${codex_dir}/herdr-agent-state.sh"
)

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

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    sync_herdr_integrations "${1:-herdr}"
fi
