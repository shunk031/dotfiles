#!/usr/bin/env bash

# @file install/ubuntu/common/misc.sh
# @brief Essential utilities installation script for Ubuntu
# @description
#   This script installs common command-line utilities including
#   busybox, curl, gpg, htop, vim, wget, and zsh.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly PACKAGES=(
    busybox
    curl
    gpg
    htop
    unzip
    vim
    wget
    zsh
)

# @description Install essential command-line utility packages
# @exitcode 0 On successful installation
# @exitcode 1 If installation fails
# @example
#   install_apt_packages
function install_apt_packages() {
    sudo apt-get install -y "${PACKAGES[@]}"
}

# @description Uninstall utility packages
# @exitcode 0 On successful removal
# @exitcode 1 If removal fails
# @example
#   uninstall_apt_packages
function uninstall_apt_packages() {
    sudo apt-get remove -y "${PACKAGES[@]}"
}

# @description Main entry point for utilities installation script
# @exitcode 0 On success
# @exitcode 1 On failure
# @example
#   ./misc.sh
function main() {
    install_apt_packages
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
