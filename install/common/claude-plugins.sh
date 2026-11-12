#!/usr/bin/env bash

# @file install/common/claude-plugins.sh
# @brief Ensure managed Claude Code plugins are installed and enabled.
# @description
#   Runs Claude Code through the configured mise toolchain and changes only the
#   missing or disabled plugin state. Claude Code does not list a marketplace
#   whose recorded source differs from the one the settings declare, so the
#   script adds it again, which records the declared source. Each time it adds
#   a marketplace, an installed plugin from it is installed again, so the plugin
#   comes from the declared source.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly MISE_BIN="${HOME}/.local/bin/mise"
readonly CLAUDE_SETTINGS_FILE="${HOME}/.claude/settings.json"

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
# @description Print the GitHub source the applied settings declare for a marketplace.
# @arg $1 marketplace Marketplace name.
# @stdout `owner/repo`, or `owner/repo@ref` when the source pins a ref.
#
function declared_marketplace_source() {
    run_jq -er --arg name "$1" \
        '.extraKnownMarketplaces[$name].source | select(.source == "github") | .repo + (if .ref then "@" + .ref else "" end)' \
        "${CLAUDE_SETTINGS_FILE}" || {
        printf 'No GitHub marketplace %s is declared in %s\n' "$1" "${CLAUDE_SETTINGS_FILE}" >&2
        return 1
    }
}

#
# @description Print the source of a marketplace Claude Code already knows.
# @arg $1 marketplace Marketplace name.
# @stdout The source in the form `declared_marketplace_source` prints, or nothing when it is unknown.
#
function known_marketplace_source() {
    local marketplaces_json

    marketplaces_json="$(run_claude_plugin marketplace list --json)"
    run_jq -r --arg name "$1" \
        '.[] | select(.name == $name) | (.repo // "") + (if .ref then "@" + .ref else "" end)' \
        <<< "${marketplaces_json}"
}

#
# @description Install or enable a Claude Code plugin from the marketplace source the settings declare.
# @arg $1 plugin_id Plugin id in `plugin@marketplace` form.
#
function ensure_claude_plugin() {
    local plugin_id="$1"
    local marketplace="${plugin_id#*@}"
    local declared known installed_json
    local is_added=false

    declared="$(declared_marketplace_source "${marketplace}")"
    known="$(known_marketplace_source "${marketplace}")"
    if [ "${known}" != "${declared}" ]; then
        run_claude_plugin marketplace add "${declared}"
        is_added=true
    fi

    installed_json="$(run_claude_plugin list --json)"
    if ! run_jq -e 'type == "array"' <<< "${installed_json}" > /dev/null; then
        printf 'Claude plugin list did not return a JSON array\n' >&2
        return 1
    fi

    if [ "${is_added}" = true ] && run_jq -e --arg plugin_id "${plugin_id}" \
        "any(.[]; .id == \$plugin_id)" \
        <<< "${installed_json}" > /dev/null; then
        # Claude Code can keep the copy it cached for the same version, so the
        # plugin is uninstalled, keeping its data, and installed again.
        run_claude_plugin uninstall --keep-data "${plugin_id}"
        run_claude_plugin install --scope user --yes "${plugin_id}"
        return
    fi

    if run_jq -e --arg plugin_id "${plugin_id}" \
        "any(.[]; .id == \$plugin_id and .enabled)" \
        <<< "${installed_json}" > /dev/null; then
        return
    fi

    if run_jq -e --arg plugin_id "${plugin_id}" \
        "any(.[]; .id == \$plugin_id)" \
        <<< "${installed_json}" > /dev/null; then
        run_claude_plugin enable "${plugin_id}"
        return
    fi

    run_claude_plugin install --scope user --yes "${plugin_id}"
}

#
# @description Run the Claude Code plugin installation workflow.
#
function main() {
    ensure_claude_plugin "inbox@inbox"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
