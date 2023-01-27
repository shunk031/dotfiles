#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
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
