#!/usr/bin/env bash

set -Eeuox pipefail

function install_tmux() {
    brew install tmux reattach-to-user-namespace cmake
}

function main() {
    install_tmux
}

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    main
fi
