#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_nodebrew() {
    brew install nodebrew
}

function main() {
    install_nodebrew
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
