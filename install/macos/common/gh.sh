#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_gh() {
    brew install gh
}

function uninstall_gh() {
    brew uninstall gh
}

function main() {
    install_gh
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
