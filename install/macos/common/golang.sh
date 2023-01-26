#!/usr/bin/env bash

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -Eeuox pipefail
fi

function is_golang_installed() {
    command -v go >/dev/null
}

function install_golang() {
    if ! is_golang_installed; then
        brew install go
    fi
}

function main() {
    install_golang
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
