#!/usr/bin/env bash

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -Eeuox pipefail
fi

function install_chezmoi() {
    if ! command -v chezmoi >/dev/null; then
        brew install chezmoi
    fi
}

function main() {
    install_chezmoi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
