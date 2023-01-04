#!/usr/bin/env bash

set -Eeuox pipefail

function install_mecab_ipadic_neologd_requirements() {
    brew install git curl xz
}

function main() {
    install_mecab_ipadic_neologd_requirements
}

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    main
fi
