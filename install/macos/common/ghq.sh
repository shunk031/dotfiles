#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_ghq() {
    brew install ghq
}

function uninstall_ghq() {
    brew uninstall ghq
}

function main() {
    install_ghq
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
