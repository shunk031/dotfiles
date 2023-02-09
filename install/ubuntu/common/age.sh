#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_age() {
    sudo apt-get install -y age
}

function install_jq() {
    if command -v jq &>/dev/null; then
        sudo apt-get install -y jq
    fi
}

function main() {
    install_age
    install_jq
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
