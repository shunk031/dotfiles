#!/usr/bin/env bash

# @file install/common/claude-plugins.sh
# @brief Update the inline inbox plugin and remove its marketplace installation.
# @description
#   Fast-forwards the managed inbox clone on every apply and preserves the old
#   marketplace store before uninstalling that copy.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly MISE_BIN="${HOME}/.local/bin/mise"
readonly CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
readonly INBOX_STORE_BACKUP_ROOT="${XDG_STATE_HOME:-${HOME}/.local/state}/inbox-store-backup"

#
# @description Run a Claude Code plugin command through mise.
# @arg $@ command Arguments after `claude plugin`.
#
function run_claude_plugin() {
    "${MISE_BIN}" exec -- claude plugin "$@"
}

#
# @description Run jq through mise.
# @arg $@ args Arguments for jq.
#
function run_jq() {
    "${MISE_BIN}" exec -- jq "$@"
}

#
# @description Copy the marketplace plugin store into a new read-only backup folder.
#
function backup_inbox_store() (
    local -a store_files=()
    local backup_dir file

    shopt -s nullglob
    store_files=("${CLAUDE_CONFIG_DIR}/plugins/store/inbox_inbox-"*.json)
    shopt -u nullglob
    if ((${#store_files[@]} == 0)); then
        return 0
    fi

    umask 077
    mkdir -p "${INBOX_STORE_BACKUP_ROOT}"
    backup_dir="${INBOX_STORE_BACKUP_ROOT}/$(date '+%Y-%m-%d')"
    if [ -e "${backup_dir}" ]; then
        backup_dir="${backup_dir}-$(date '+%H%M%S')"
    fi
    if ! mkdir "${backup_dir}"; then
        printf 'Cannot create inbox store backup directory: %s\n' "${backup_dir}" >&2
        return 1
    fi

    for file in "${store_files[@]}"; do
        if ! cp "${file}" "${backup_dir}/"; then
            printf 'Failed to back up inbox store file: %s\n' "${file}" >&2
            return 1
        fi
        if ! chmod a-w "${backup_dir}/${file##*/}"; then
            printf 'Failed to make inbox store backup read-only: %s\n' "${backup_dir}/${file##*/}" >&2
            return 1
        fi
    done

    if ! chmod a-w "${backup_dir}"; then
        printf 'Failed to make inbox store backup directory read-only: %s\n' "${backup_dir}" >&2
        return 1
    fi
)

#
# @description Back up and uninstall the marketplace inbox when it is installed.
#
function remove_marketplace_inbox() {
    local installed_json marketplaces_json

    installed_json="$(run_claude_plugin list --json)"
    if ! run_jq -e 'type == "array"' <<< "${installed_json}" > /dev/null; then
        printf 'Claude plugin list did not return a JSON array\n' >&2
        return 1
    fi

    if run_jq -e 'any(.[]; .id == "inbox@inbox")' <<< "${installed_json}" > /dev/null; then
        backup_inbox_store
        run_claude_plugin uninstall inbox@inbox --scope user --keep-data

        marketplaces_json="$(run_claude_plugin marketplace list --json)"
        if ! run_jq -e 'type == "array"' <<< "${marketplaces_json}" > /dev/null; then
            printf 'Claude plugin marketplace list did not return a JSON array\n' >&2
            return 1
        fi
        if run_jq -e 'any(.[]; .name == "inbox")' <<< "${marketplaces_json}" > /dev/null; then
            run_claude_plugin marketplace remove inbox
        fi
    fi
}

#
# @description Run the inbox plugin update workflow.
#
function main() {
    "${HOME}/.local/bin/common/claude-inbox-pull" --ensure
    remove_marketplace_inbox
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
