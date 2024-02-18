#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_eza() {
    brew install eza
}

function uninstall_eza() {
    brew uninstall eza
}

function main() {
    install_eza
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
