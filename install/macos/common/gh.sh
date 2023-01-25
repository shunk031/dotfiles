#!/usr/bin/env bash

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -Eeuox pipefail
fi

function install_gh() {
    brew install gh
}

function main() {
    install_gh
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
