#!/usr/bin/env bash

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -Eeuox pipefail
fi

function install_mecab() {
    sudo apt-get install -y mecab libmecab-dev mecab-ipadic-utf8
}

function main() {
    install_mecab
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
