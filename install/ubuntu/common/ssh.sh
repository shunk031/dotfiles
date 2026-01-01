#!/usr/bin/env bash

# @file install/ubuntu/common/ssh.sh
# @brief OpenSSH client installation script
# @description
#   This script installs the OpenSSH client package for secure
#   shell connections to remote servers.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly PACKAGES=(
    openssh-client
)

# @description Install OpenSSH client
# @exitcode 0 On successful installation
# @exitcode 1 If installation fails
# @example
#   install_openssh
function install_openssh() {
    sudo apt-get install -y "${PACKAGES[@]}"
}

# @description Uninstall OpenSSH client
# @exitcode 0 On successful removal
# @exitcode 1 If removal fails
# @example
#   uninstall_openssh
function uninstall_openssh() {
    sudo apt-get remove -y "${PACKAGES[@]}"
}

# @description Main entry point for OpenSSH client installation script
# @exitcode 0 On success
# @exitcode 1 On failure
# @example
#   ./ssh.sh
function main() {
    install_openssh
}

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    main
fi
