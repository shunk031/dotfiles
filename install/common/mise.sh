#!/usr/bin/env bash

# @file install/common/mise.sh
# @brief Mise tool installation script
# @description
#   This script installs mise, a polyglot tool version manager.
#   It downloads and installs mise from the official repository
#   to the user's local bin directory.

# set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

export MISE_INSTALL_PATH="${HOME}/.local/bin/mise"

# @description Install mise tool version manager
# @exitcode 0 On successful installation
# @exitcode 1 On installation failure
# @example
#   install_mise
function install_mise() {
    # https://mise.run
    local version="v2025.9.25"
    local url="https://raw.githubusercontent.com/jdx/mise/refs/tags/${version}/packaging/standalone/install.envsubst"
    
    export MISE_CURRENT_VERSION="${version}"
    curl "${url}" | sh

    eval "$(~/.local/bin/mise activate bash)"
}

# @description Uninstall mise by removing the binary
# @exitcode 0 On successful removal
# @exitcode 1 If removal fails
# @example
#   uninstall_mise
function uninstall_mise() {
    rm "${MISE_INSTALL_PATH}"
}

# @description Main entry point for the mise installation script
# @exitcode 0 On success
# @exitcode 1 On failure
# @example
#   ./mise.sh
function main() {
    install_mise
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi


