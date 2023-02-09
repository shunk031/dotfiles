#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_age() {
    if command -v age &>/dev/null; then
        brew install age
    fi
}

function install_jq() {
    if command -v jq &>/dev/null; then
        brew install jq
    fi
}

function main() {
    install_age
    install_jq
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
