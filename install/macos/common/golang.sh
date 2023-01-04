#!/usr/bin/env bash

set -Eeuox pipefail

function install_golang() {
    if ! command -v go >/dev/null; then
        brew install go
    fi
}

function main() {
    install_golang
}

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    main
fi
