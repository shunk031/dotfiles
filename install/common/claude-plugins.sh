#!/usr/bin/env bash

# @file install/common/claude-plugins.sh
# @brief Ensure managed Claude Code plugins are installed and enabled.
# @description
#   Runs Claude Code through the configured mise toolchain and changes only the
#   missing or disabled plugin state.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly MISE_BIN="${HOME}/.local/bin/mise"

#
# @description Run a Claude Code plugin command through mise.
# @arg $@ command Arguments after `claude plugin`.
#
function run_claude_plugin() {
    "${MISE_BIN}" exec -- claude plugin "$@"
}

#
# @description Install or enable a Claude Code plugin when it is not already enabled.
# @arg $1 plugin_id Plugin id in `plugin@marketplace` form.
# @arg $2 marketplace_repo GitHub repository that provides the marketplace.
#
function ensure_claude_plugin() {
    local plugin_id="$1"
    local marketplace_repo="$2"
    local installed_json

    installed_json="$(run_claude_plugin list --json)"
    if ! "${MISE_BIN}" exec -- jq -e 'type == "array"' <<< "${installed_json}" > /dev/null; then
        printf 'Claude plugin list did not return a JSON array\n' >&2
        return 1
    fi

    if "${MISE_BIN}" exec -- jq -e --arg plugin_id "${plugin_id}" \
        'any(.[]; .id == $plugin_id and .enabled)' \
        <<< "${installed_json}" > /dev/null; then
        return
    fi

    if "${MISE_BIN}" exec -- jq -e --arg plugin_id "${plugin_id}" \
        'any(.[]; .id == $plugin_id)' \
        <<< "${installed_json}" > /dev/null; then
        run_claude_plugin enable "${plugin_id}"
        return
    fi

    run_claude_plugin marketplace add "${marketplace_repo}"
    run_claude_plugin install --scope user --yes "${plugin_id}"
}

#
# @description Run the Claude Code plugin installation workflow.
#
function main() {
    ensure_claude_plugin "ponytail@ponytail" "DietrichGebert/ponytail"
    ensure_claude_plugin "inbox@inbox" "petekp/inbox"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
