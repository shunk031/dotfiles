#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
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
