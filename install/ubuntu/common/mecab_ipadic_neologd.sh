#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_mecab_ipadic_neologd_requirements() {
    sudo apt-get install -y git make curl xz-utils file
}

function main() {
    install_mecab_ipadic_neologd_requirements
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
