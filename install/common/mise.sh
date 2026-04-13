#!/usr/bin/env bash

# @file install/common/mise.sh
# @brief Install and bootstrap `mise`.
# @description
#   Downloads a pinned standalone `mise` release and runs `mise install`
#   against the repository tool definitions.

# set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

export MISE_INSTALL_PATH="${HOME}/.local/bin/mise"
readonly DEFAULT_NPM_MIN_RELEASE_AGE_DAYS=7

#
# @description Install the pinned standalone `mise` binary and activate it.
#
function install_mise() {
    # https://mise.run
    local version="v2026.3.7"
    local url="https://raw.githubusercontent.com/jdx/mise/refs/tags/${version}/packaging/standalone/install.envsubst"

    export MISE_CURRENT_VERSION="${version}"
    curl "${url}" | sh
    unset MISE_CURRENT_VERSION

    eval "$(~/.local/bin/mise activate bash)"
}

#
# @description Install all tools declared for this repository through `mise`.
#
function run_mise_install() {
    # `MISE_CURRENT_VERSION` is interpreted by mise as a tool env override for `current`.
    unset MISE_CURRENT_VERSION
    mise install --before "${DEFAULT_NPM_MIN_RELEASE_AGE_DAYS}d"
}

#
# @description Remove the standalone `mise` binary from the local bin dir.
#
function uninstall_mise() {
    rm "${MISE_INSTALL_PATH}"
}

#
# @description Install `mise` and the configured tools.
#
function main() {
    install_mise
    run_mise_install
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
