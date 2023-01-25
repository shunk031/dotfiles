#!/usr/bin/env bash

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -Eeuox pipefail
fi

function install_misc() {
    sudo apt-get install -y guake gparted
}

function main() {
    install_misc
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
