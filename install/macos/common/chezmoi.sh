#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

if [ -e "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

function is_chezmoi_installed() {
    command -v chezmoi &>/dev/null
}

function install_chezmoi() {
    if ! is_chezmoi_installed; then
        brew install chezmoi
    fi
}

function uninstall_chezmoi() {
    brew uninstall chezmoi
}

function main() {
    install_chezmoi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
