#!/usr/bin/env bash

set -Eeuo pipefail

function install_chezmoi() {
    sudo sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin
}

function main() {
    install_chezmoi
}

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    main
fi
