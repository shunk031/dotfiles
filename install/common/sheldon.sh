#!/usr/bin/env bash

# @file install/common/sheldon.sh
# @brief Sheldon shell plugin manager installation script
# @description
#   This script installs sheldon, a fast and configurable shell plugin manager.
#   It downloads and installs the latest version from the official repository
#   to the user's local bin directory.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly BIN_DIR="${HOME}/.local/bin"

# @description Install sheldon shell plugin manager
# @exitcode 0 On successful installation
# @exitcode 1 On installation failure
# @example
#   install_sheldon
function install_sheldon() {
    mkdir -p "${BIN_DIR}"

    curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh |
        bash -s -- --repo rossmacarthur/sheldon --to "${BIN_DIR}" --force
}

# @description Uninstall sheldon by removing the binary
# @exitcode 0 On successful removal
# @exitcode 1 If removal fails
# @example
#   uninstall_sheldon
function uninstall_sheldon() {
    rm "${BIN_DIR}/sheldon"
}

# @description Main entry point for the sheldon installation script
# @exitcode 0 On success
# @exitcode 1 On failure
# @example
#   ./sheldon.sh
function main() {
    install_sheldon
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
