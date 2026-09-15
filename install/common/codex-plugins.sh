#!/usr/bin/env bash

# @file install/common/codex-plugins.sh
# @brief Install Codex native plugins.
# @description
#   Activates `mise`, registers Codex plugin marketplaces, and installs their
#   plugins.

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
# @description Register Codex plugin marketplaces and install their native plugins.
#
function install_codex_plugins() {
    "${MISE_BIN}" exec -- codex plugin marketplace add \
        Imbad0202/academic-research-skills-codex \
        --ref main
    "${MISE_BIN}" exec -- codex plugin add \
        ars-codex@ars-codex

    "${MISE_BIN}" exec -- codex plugin marketplace add \
        DietrichGebert/ponytail \
        --ref main
    "${MISE_BIN}" exec -- codex plugin add \
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
