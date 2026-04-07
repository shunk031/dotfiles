#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly PACKAGES=(
    openssh-client
)

function install_openssh() {
    sudo --preserve-env=http_proxy,https_proxy,no_proxy apt-get install -y "${PACKAGES[@]}"
}

function uninstall_openssh() {
    sudo apt-get remove -y "${PACKAGES[@]}"
}

function main() {
    install_openssh
}

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    main
fi
