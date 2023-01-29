#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_openssh() {
    sudo apt-get install -y openssh-client
}

function main() {
    install_openssh
}

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    main
fi
