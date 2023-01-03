#!/usr/bin/env bash

set -Eeuox pipefail

function install_ghq() {
    /usr/local/go/bin/go install github.com/x-motemen/ghq@latest
}

function main() {
    install_ghq
}

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    main
fi
