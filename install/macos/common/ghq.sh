#!/usr/bin/env bash

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -Eeuox pipefail
fi

function install_ghq() {
    brew install ghq
}

function main() {
    install_ghq
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
