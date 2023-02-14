#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly PACKAGES=(
    mecab
    libmecab-dev
    mecab-ipadic-utf8
)

function install_mecab() {
    sudo apt-get install -y "${PACKAGES[@]}"
}

function uninstall_mecab() {
    sudo apt-get remove -y "${PACKAGES[@]}"
}

function main() {
    install_mecab
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
