#!/usr/bin/env bash

# @file install/ubuntu/server/starship.sh
# @brief Starship shell prompt installation script
# @description
#   This script installs Starship, a minimal, fast, and customizable
#   prompt for any shell. It downloads and installs the latest version
#   to the user's local bin directory.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly BIN_DIR="${HOME}/.local/bin"

# @description Install Starship prompt
# @exitcode 0 On successful installation
# @exitcode 1 If installation fails
# @example
#   install_starship
function install_starship() {
    # equivalent to `https://starship.rs/install.sh`
    local url="https://raw.githubusercontent.com/starship/starship/master/install/install.sh"
    local version="latest"

    mkdir -p "${BIN_DIR}"

    curl -sS "${url}" | dash -s -- \
        --yes \
        --version "${version}" \
        --bin-dir "${BIN_DIR}"
}

# @description Uninstall Starship by removing binary directory
# @exitcode 0 On successful removal
# @exitcode 1 If removal fails
# @example
#   uninstall_starship
function uninstall_starship() {
    rm -rf "${BIN_DIR}"
}

# @description Main entry point for the Starship installation script
# @exitcode 0 On success
# @exitcode 1 On failure
# @example
#   ./starship.sh
function main() {
    install_starship
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
