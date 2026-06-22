#!/usr/bin/env bash

# @file install/common/agmsg.sh
# @brief Install agmsg runtime assets.
# @description
#   Activates `mise` when available, then runs `agmsg install`.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly MISE_BIN="${HOME}/.local/bin/mise"

#
# @description Activate `mise` so `agmsg` can resolve from the configured toolchain.
#
function activate_mise() {
    if [ -x "${MISE_BIN}" ]; then
        eval "$("${MISE_BIN}" activate bash)"
    fi
}

#
# @description Install agmsg runtime assets.
#
function install_agmsg() {
    agmsg install
}

#
# @description Run the agmsg installation workflow.
#
function main() {
    activate_mise
    install_agmsg
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
