#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly PACKAGES=(
    gpg
    jq
    htop
    shellcheck
    vim
    zsh
)

function install_apt_packages() {
    sudo apt-get install -y "${PACKAGES[@]}"
}

function install_cargo_packages() {
    local cargo_cmd="${HOME%/}/.cargo/bin/cargo"
    # "${cargo_cmd}" install exa
}

function uninstall_apt_packages() {
    sudo apt-get remove -y "${PACKAGES[@]}"
}

function main() {
    install_apt_packages
    install_cargo_packages
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
