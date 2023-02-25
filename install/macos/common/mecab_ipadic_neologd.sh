#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly PACKAGES=(
    # git
    # curl
    xz
)

function install_mecab_ipadic_neologd_requirements() {
    brew install "${PACKAGES[@]}"
}

function uninstall_mecab_ipadic_neologd_requirements() {
    brew uninstall "${PACKAGES[@]}"
}

function main() {
    install_mecab_ipadic_neologd_requirements
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
