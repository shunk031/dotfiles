#!/usr/bin/env bash

set -Eeuox pipefail

function install_mecab() {
    sudo apt-get install -y mecab libmecab-dev mecab-ipadic-utf8
}

function main() {
    install_mecab
}

# if [ ${#BASH_SOURCE[@]} = 1 ]; then
#     main
# fi
