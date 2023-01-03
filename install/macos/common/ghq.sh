#!/usr/bin/env bash

set -Eeuox pipefail

function install_ghq() {
    brew install ghq
}

function main() {
    install_ghq
}

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    main
fi
