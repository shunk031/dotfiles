#!/usr/bin/env bash

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -Eeuox pipefail
fi

function install_mecab_ipadic_neologd_requirements() {
    brew install git curl xz
}

function main() {
    install_mecab_ipadic_neologd_requirements
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
