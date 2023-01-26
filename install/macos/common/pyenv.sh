#!/usr/bin/env bash

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -Eeuox pipefail
fi

function install_pyenv_requirements() {
    brew install openssl readline sqlite3 xz zlib tcl-tk
}

function main() {
    install_pyenv_requirements
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
