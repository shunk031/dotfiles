#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function apt_install_eza() {
    sudo apt install -y eza
}

function apt_install_exa() {
    sudo apt install -y exa
}

function install_eza() {
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --yes --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    sudo apt update

    if ! apt_install_eza; then
        apt_install_exa
    fi
}

function uninstall_eza() {
    sudo apt-get remove -y eza
}

function main() {
    install_eza
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
