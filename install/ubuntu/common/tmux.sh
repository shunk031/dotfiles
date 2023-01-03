#!/usr/bin/env bash

set -Eeuox pipefail

function install_tmux() {
    sudo apt-get install -y tmux xsel cmake
}

function main() {
    install_tmux
}

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    main
fi
