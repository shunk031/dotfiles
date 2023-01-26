#!/usr/bin/env bash

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -Eeuox pipefail
fi

function install_tmux() {
    sudo apt-get install -y tmux xsel cmake
}

function main() {
    install_tmux
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
