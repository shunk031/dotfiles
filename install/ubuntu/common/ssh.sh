#!/usr/bin/env bash

# @file install/ubuntu/common/ssh.sh
# @brief Install the OpenSSH client on Ubuntu.
# @description
#   Installs or removes the Ubuntu OpenSSH client package while preserving
#   proxy-related environment variables.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly PACKAGES=(
    openssh-client
)

#
# @description Install the OpenSSH client package.
#
function install_openssh() {
    sudo --preserve-env=http_proxy,https_proxy,no_proxy apt-get install -y "${PACKAGES[@]}"
}

#
# @description Remove the OpenSSH client package.
#
function uninstall_openssh() {
    sudo apt-get remove -y "${PACKAGES[@]}"
}

#
# @description Run the OpenSSH client installation flow.
#
function main() {
    install_openssh
}

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    main
fi
