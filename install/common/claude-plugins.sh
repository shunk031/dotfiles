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
readonly INBOX_PLUGIN_DIR="${HOME}/.local/share/claude/plugins/inbox"
readonly INBOX_REPOSITORY_URL="https://github.com/shunk031/inbox"
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
# @description Clone inbox main or fast-forward its clean main checkout.
#
function update_inbox_clone() {
    local clone_parent="${INBOX_PLUGIN_DIR%/*}"
    local clone_root branch remote upstream head

    mkdir -p "${clone_parent}"
    if [ -L "${INBOX_PLUGIN_DIR}" ]; then
        printf 'Inbox plugin path must not be a symlink: %s\n' "${INBOX_PLUGIN_DIR}" >&2
        return 1
    fi
    if [ ! -e "${INBOX_PLUGIN_DIR}" ]; then
        git clone --branch main --single-branch "${INBOX_REPOSITORY_URL}" "${INBOX_PLUGIN_DIR}"
        return
    fi

    clone_root="$(git -C "${INBOX_PLUGIN_DIR}" rev-parse --show-toplevel)"
    if [ "${clone_root}" != "$(cd "${INBOX_PLUGIN_DIR}" && pwd -P)" ]; then
        printf 'Inbox plugin path is not the root of its git clone: %s\n' "${INBOX_PLUGIN_DIR}" >&2
        return 1
    fi

    branch="$(git -C "${INBOX_PLUGIN_DIR}" branch --show-current)"
    if [ "${branch}" != "main" ]; then
        printf 'Inbox clone must be on main, found %s\n' "${branch:-detached HEAD}" >&2
        return 1
    fi

    remote="$(git -C "${INBOX_PLUGIN_DIR}" remote get-url origin)"
    if [ "${remote}" != "${INBOX_REPOSITORY_URL}" ]; then
        printf 'Inbox clone origin must be %s, found %s\n' "${INBOX_REPOSITORY_URL}" "${remote}" >&2
        return 1
    fi

    if [ -n "$(git -C "${INBOX_PLUGIN_DIR}" status --porcelain --untracked-files=all)" ]; then
        printf 'Inbox clone has local changes: %s\n' "${INBOX_PLUGIN_DIR}" >&2
        return 1
    fi

    upstream="$(git -C "${INBOX_PLUGIN_DIR}" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}')"
    if [ "${upstream}" != "origin/main" ]; then
        printf 'Inbox clone must track origin/main, found %s\n' "${upstream}" >&2
        return 1
    fi

    git -C "${INBOX_PLUGIN_DIR}" pull --ff-only
    head="$(git -C "${INBOX_PLUGIN_DIR}" rev-parse HEAD)"
    upstream="$(git -C "${INBOX_PLUGIN_DIR}" rev-parse '@{upstream}')"
    if [ "${head}" != "${upstream}" ]; then
        printf 'Inbox clone has commits that are not on origin/main\n' >&2
        return 1
    fi
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
)

#
# @description Back up and uninstall the marketplace inbox when it is installed.
#
function remove_marketplace_inbox() {
    local installed_json

    installed_json="$(run_claude_plugin list --json)"
    if ! run_jq -e 'type == "array"' <<< "${installed_json}" > /dev/null; then
        printf 'Claude plugin list did not return a JSON array\n' >&2
        return 1
    fi

    if run_jq -e 'any(.[]; .id == "inbox@inbox")' <<< "${installed_json}" > /dev/null; then
        backup_inbox_store
        run_claude_plugin uninstall inbox@inbox --scope user --keep-data
    fi
}

#
# @description Run the inbox plugin update workflow.
#
function main() {
    update_inbox_clone
    remove_marketplace_inbox
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
