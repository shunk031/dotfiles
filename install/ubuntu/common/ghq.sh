#!/usr/bin/env bash

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -Eeuox pipefail
fi

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

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
