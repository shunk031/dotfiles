#!/usr/bin/env bash

# @file install/ubuntu/client/misc.sh
# @brief Miscellaneous packages installation script for Ubuntu desktop
# @description
#   This script installs various utility packages including
#   Guake terminal and GParted partition editor.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly PACKAGES=(
    guake
    gparted
)

# @description Install miscellaneous desktop utility packages
# @exitcode 0 On successful installation
# @exitcode 1 If installation fails
# @example
#   install_misc
function install_misc() {
    sudo apt-get install -y "${PACKAGES[@]}"
}

# @description Uninstall miscellaneous utility packages
# @exitcode 0 On successful removal
# @exitcode 1 If removal fails
# @example
#   uninstall_misc
function uninstall_misc() {
    sudo apt-get remove -y "${PACKAGES[@]}"
}

# @description Main entry point for miscellaneous packages installation script
# @exitcode 0 On success
# @exitcode 1 On failure
# @example
#   ./misc.sh
function main() {
    install_misc
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
