#!/usr/bin/env bash

# @file install/common/mise.sh
# @brief Install and bootstrap `mise`.
# @description
#   Downloads a pinned standalone `mise` release and runs `mise install`.

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
    local version="v2026.6.13"
    local url="https://github.com/jdx/mise/releases/download/${version}/install.sh"

    export MISE_VERSION="${version}"
    curl -fsSL "${url}" | sh
    unset MISE_VERSION

    eval "$(~/.local/bin/mise activate bash)"
}

#
# @description Run `mise install` with the repository npm age gate.
#
function run_mise_install() {
    # These installer envvars are interpreted by mise as tool env overrides.
    unset MISE_CURRENT_VERSION
    unset MISE_VERSION
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
