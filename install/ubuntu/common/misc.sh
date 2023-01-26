#!/usr/bin/env bash

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -Eeuox pipefail
fi

function install_apt_packages() {
    local packages=(
        "exa"
        "jq"
        "htop"
        "shellcheck"
        "openssh-client"
        "vim"
        "zsh"
    )
    for package in "${packages[@]}"; do
        if ! ${CI:-false}; then
            sudo apt-get install -y "${package}"
        fi
    done
}

function main() {
    install_apt_packages
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
