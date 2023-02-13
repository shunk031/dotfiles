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
    if ! is_age_installed; then
        brew install age
    fi
}

function install_jq() {
    if ! is_jq_installed; then
        brew install jq
    fi
}

function uninstall_age() {
    brew uninstall age
}

function uninstall_jq() {
    brew uninstall jq
}

function main() {
    install_age
    install_jq
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
