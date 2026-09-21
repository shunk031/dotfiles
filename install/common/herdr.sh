#!/usr/bin/env bash

# @file install/common/herdr.sh
# @brief Repair Herdr integrations while restoring agent settings.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly MISE_BIN="${HOME}/.local/bin/mise"
readonly HERDR_SKILL_PATH="${HOME}/.agents/skills/herdr/SKILL.md"

#
# @description Install missing or outdated integrations and restore their settings.
# @arg $@ string Herdr command and any prefix arguments.
function sync_herdr_integrations() (
    local claude_dir codex_dir status agent line backup index result
    local -a agents=() settings=()
    claude_dir="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
    codex_dir="${CODEX_HOME:-${HOME}/.codex}"

    if [ -L "${claude_dir}/hooks" ]; then
        printf '%s\n' 'Run chezmoi apply to migrate the Claude hooks directory before syncing Herdr.' >&2
        return 1
    fi

    status="$("$@" integration status)" || return
    for agent in claude codex; do
        line="$(printf '%s\n' "${status}" | sed -n "/^${agent}: /p")"
        case "${line}" in
        "${agent}: current ("*) continue ;;
        "${agent}: not installed"* | "${agent}: outdated ("* | "${agent}: needs repair"*)
            agents+=("${agent}")
            ;;
        *)
            printf 'Unrecognized Herdr integration status for %s; nothing changed.\n' "${agent}" >&2
            return 1
            ;;
        esac
        case "${agent}" in
        claude) settings+=("${claude_dir}/settings.json") ;;
        codex) settings+=("${codex_dir}/hooks.json" "${codex_dir}/config.toml") ;;
        esac
    done
    [ "${#agents[@]}" -gt 0 ] || return 0

    backup="$(mktemp -d)" || return
    trap 'rm -rf -- "${backup}"' EXIT
    for index in "${!settings[@]}"; do
        if [ -f "${settings[index]}" ]; then
            cp -pL "${settings[index]}" "${backup}/${index}" || return
        elif [ -e "${settings[index]}" ] || [ -L "${settings[index]}" ]; then
            printf 'Cannot back up non-file or dangling settings path: %s\n' "${settings[index]}" >&2
            return 1
        fi
    done

    # @description Restore bytes through existing settings symlinks, preserved by Herdr.
    # shellcheck disable=SC2329 # Invoked by the EXIT trap.
    function restore_settings() {
        result=$?
        trap - EXIT
        trap '' HUP INT TERM
        local failed=0
        for index in "${!settings[@]}"; do
            if [ -f "${backup}/${index}" ]; then
                cp -p "${backup}/${index}" "${settings[index]}" || failed=1
            else
                rm -f -- "${settings[index]}" || failed=1
            fi
        done
        if [ "${failed}" -ne 0 ]; then
            printf 'Settings restore failed; backup retained at %s\n' "${backup}" >&2
            exit 1
        fi
        rm -rf -- "${backup}"
        exit "${result}"
    }
    trap 'restore_settings' EXIT
    trap 'exit 129' HUP
    trap 'exit 130' INT
    trap 'exit 143' TERM

    mkdir -p "${claude_dir}" "${codex_dir}" || return
    for agent in "${agents[@]}"; do
        CLAUDE_CONFIG_DIR="${claude_dir}" CODEX_HOME="${codex_dir}" \
            "$@" integration install "${agent}" || return
    done
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
