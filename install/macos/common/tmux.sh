#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly PACKAGES=(
    tmux
    # git
    reattach-to-user-namespace
    cmake
)

function install_tmux() {
    brew install "${PACKAGES[@]}"
}

function uninstall_tmux() {
    brew uninstall "${PACKAGES[@]}"
}

function main() {
    install_tmux
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
