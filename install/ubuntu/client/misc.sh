#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly PACKAGES=(
    guake
    gparted
)

function install_misc() {
    sudo apt-get install -y "${PACKAGES[@]}"
}

function uninstall_misc() {
    sudo apt-get remove -y "${PACKAGES[@]}"
}

function main() {
    install_misc
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
