#!/usr/bin/env bash

# @file install/common/codex-plugins.sh
# @brief Ensure Codex native plugins are installed and enabled.
# @description
#   Activates `mise`, inspects the installed plugins once, and installs only
#   missing or disabled plugins.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly MISE_BIN="${HOME}/.local/bin/mise"

#
# @description Activate `mise` so Codex resolves from the configured toolchain.
#
function activate_mise() {
    if [ -x "${MISE_BIN}" ]; then
        eval "$("${MISE_BIN}" activate bash)"
    fi
}

#
# @description Install a Codex plugin when it is missing or disabled.
# @arg $1 installed_json JSON returned by `codex plugin list --json`.
# @arg $2 source GitHub repository used as the plugin marketplace source.
# @arg $3 plugin_id Plugin identifier in `plugin@marketplace` form.
#
function ensure_codex_plugin() {
    local installed_json="$1"
    local source="$2"
    local plugin_id="$3"

    if jq -e --arg plugin_id "${plugin_id}" 'any(.installed[]; .pluginId == $plugin_id and .enabled)' <<< "${installed_json}" > /dev/null; then
        return
    fi

    "${MISE_BIN}" exec -- codex plugin marketplace remove "${plugin_id#*@}" > /dev/null 2>&1 || true
    "${MISE_BIN}" exec -- codex plugin marketplace add \
        "${source}" \
        --ref main
    "${MISE_BIN}" exec -- codex plugin add \
        "${plugin_id}"
}

#
# @description Ensure all managed Codex native plugins are installed and enabled.
#
function install_codex_plugins() {
    local installed_json

    installed_json="$("${MISE_BIN}" exec -- codex plugin list --json)"
    ensure_codex_plugin \
        "${installed_json}" \
        Imbad0202/academic-research-skills-codex \
        ars-codex@ars-codex
    ensure_codex_plugin \
        "${installed_json}" \
        DietrichGebert/ponytail \
        ponytail@ponytail
}

#
# @description Run the Codex native plugin installation workflow.
#
function main() {
    activate_mise
    install_codex_plugins
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
