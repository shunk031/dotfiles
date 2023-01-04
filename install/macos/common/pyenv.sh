#!/usr/bin/env bash

set -Eeuox pipefail

function install_pyenv_requirements() {
    brew install openssl readline sqlite3 xz zlib tcl-tk
}

function main() {
    install_pyenv_requirements
}

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    main
fi
