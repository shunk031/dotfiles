#!/usr/bin/env bash

set -Eeuox pipefail

PACKAGES=(
    "exa"
    "jq"
    "htop"
    "shellcheck"
    "vim"
    "zsh"
)

function install_apt_packages() {
    sudo apt-get update -y

    for package in "${PACKAGES[@]}"; do
        if ! ${CI:-false}; then
            sudo apt-get install -y "${package}"
        fi
    done
}

function uninstall_apt_packages() {
    for package in "${PACKAGES[@]}"; do
        if ! ${CI:-false}; then
            sudo apt-get remove -y "${package}"
        fi
    done
}

function main() {
    install_apt_packages
}

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    main
fi
