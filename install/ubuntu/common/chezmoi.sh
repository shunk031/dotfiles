#!/usr/bin/env bash

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -Eeuox pipefail
fi

function install_chezmoi() {
    sudo sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin
}

function main() {
    install_chezmoi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
