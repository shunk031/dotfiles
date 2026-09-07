#!/usr/bin/env bash

# @file install/rocky/common/ssh.sh
# @brief Install the OpenSSH client on Rocky Linux.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly PACKAGES=(
    openssh-clients
)

#
# @description Install the Rocky Linux OpenSSH client package.
#
function install_openssh() {
    if command -v ssh > /dev/null 2>&1; then
        return 0
    fi

    sudo --preserve-env=http_proxy,https_proxy,no_proxy dnf install -y "${PACKAGES[@]}"
}

#
# @description Run the OpenSSH client installation flow.
#
function main() {
    install_openssh
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
