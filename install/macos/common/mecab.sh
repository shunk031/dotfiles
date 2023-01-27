#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_mecab() {
    brew install mecab
}

function install_mecab_ipadic() {
    brew install mecab-ipadic
}

function main() {
    install_mecab
    install_mecab_ipadic
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
