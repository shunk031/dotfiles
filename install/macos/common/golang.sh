#!/usr/bin/env bash

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -Eeuox pipefail
fi

function install_golang() {
    if ! command -v go >/dev/null; then
        brew install go
    fi
}

function main() {
    install_golang
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
