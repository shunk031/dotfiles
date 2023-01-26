#!/usr/bin/env bash

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -Eeuox pipefail
fi

function is_chezmoi_installed() {
    command -v chezmoi &>/dev/null
}

function install_chezmoi() {
    if ! is_chezmoi_installed; then
        brew install chezmoi
    fi
}

function main() {
    install_chezmoi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
