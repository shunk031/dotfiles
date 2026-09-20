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
# @description Install or enable ponytail when it is not already enabled.
#
function install_ponytail() {
    local installed_json

    installed_json="$(run_claude_plugin list --json)"

    if jq -e 'any(.[]; .id == "ponytail@ponytail" and .enabled)' \
        <<< "${installed_json}" > /dev/null; then
        return
    fi

    if jq -e 'any(.[]; .id == "ponytail@ponytail")' \
        <<< "${installed_json}" > /dev/null; then
        run_claude_plugin enable ponytail@ponytail
        return
    fi

    run_claude_plugin marketplace add DietrichGebert/ponytail
    run_claude_plugin install --scope user --yes ponytail@ponytail
}

#
# @description Run the Claude Code plugin installation workflow.
#
function main() {
    install_ponytail
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
