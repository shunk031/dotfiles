#!/usr/bin/env bash

# set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_container() {
    brew install --cask container
    yes | container system start
}

function uninstall_container() {
    brew uninstall container --force
}

function main() {
    install_container
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
