#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly PACKAGES=(
    # git
    make
    # curl
    xz-utils
    file
)

function install_mecab_ipadic_neologd_requirements() {
    sudo apt-get install -y "${PACKAGES[@]}"
}

function uninstall_mecab_ipadic_neologd_requirements() {
    sudo apt-get remove -y "${PACKAGES[@]}"
}

function main() {
    install_mecab_ipadic_neologd_requirements
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
