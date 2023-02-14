#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly PACKAGES=(
    build-essential
    libssl-dev
    zlib1g-dev
    libbz2-dev
    libreadline-dev
    libsqlite3-dev
    curl
    llvm
    libncursesw5-dev
    xz-utils
    tk-dev
    libxml2-dev
    libxmlsec1-dev
    libffi-dev
    liblzma-dev
)

function install_pyenv_requirements() {
    sudo apt-get install -y "${PACKAGES[@]}"
}

function uninstall_pyenv_requirements() {
    sudo apt-get remove -y "${PACKAGES[@]}"
}

function main() {
    install_pyenv_requirements
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
