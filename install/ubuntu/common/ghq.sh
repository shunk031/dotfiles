#!/usr/bin/env bash

function install_ghq() {
    export GOPATH="${HOME}/ghq"
    /usr/local/go/bin/go install github.com/x-motemen/ghq@latest
}

function uninstall_ghq() {
    rm -f "${HOME}/ghq/bin/ghq"
}

function main() {
    install_ghq
}

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    set -Eeuox pipefail
    main
fi
