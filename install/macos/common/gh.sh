#!/usr/bin/env bash

set -Eeuox pipefail

function install_gh() {
    brew install gh
}

function main() {
    install_gh
}

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    main
fi
