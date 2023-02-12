#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_apt_packages() {
    local packages=(
        "exa"
        "jq"
        "htop"
        "shellcheck"
        "vim"
        "zsh"
    )
    for package in "${packages[@]}"; do
        sudo apt-get install -y "${package}"
    done
}

function main() {
    install_apt_packages
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
