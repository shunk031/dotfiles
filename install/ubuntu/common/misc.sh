#!/usr/bin/env bash

set -Eeuox pipefail

function install_apt_packages() {
    local packages=(
        "exa"
        "jq"
        "htop"
        "shellcheck"
        "openssh-client"
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

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    main
fi
