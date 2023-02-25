#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function is_age_installed() {
    command -v age &>/dev/null
}

function is_jq_installed() {
    command -v jq &>/dev/null
}

function install_age() {
    export GOPATH="${HOME%/}/ghq"

    if ! is_age_installed; then
        /usr/local/go/bin/go install filippo.io/age/...@latest
    fi
}

function install_jq() {
    if ! is_jq_installed; then
        sudo apt-get install -y jq
    fi
}

function uninstall_age() {
    rm -v "${GOPATH%/}/bin/age"
}

function uninstall_jq() {
    sudo apt-get remove -y jq
}

function main() {
    install_age
    install_jq
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
