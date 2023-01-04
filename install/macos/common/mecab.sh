#!/usr/bin/env bash

set -Eeuox pipefail

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

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    main
fi
