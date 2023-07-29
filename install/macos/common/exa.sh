#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_exa() {
    brew install exa
}

function uninstall_exa() {
    brew uninstall exa
}

function main() {
    install_exa
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
