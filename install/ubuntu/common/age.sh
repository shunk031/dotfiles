#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function is_jq_installed() {
    command -v jq &>/dev/null
}

function install_age() {
    sudo apt-get install -y age
}

function install_jq() {
    if ! is_jq_installed; then
        sudo apt-get install -y jq
    fi
}

function uninstall_age() {
    sudo apt-get remove -y age
}

function uninstall_jq() {
    sudo apt-get remove -y jq
}

function main() {
    install_jq
    install_age
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
