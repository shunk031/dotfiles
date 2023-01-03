#!/usr/bin/env bash

set -Eeuox pipefail

function install_misc() {
    sudo apt-get install -y guake gparted
}

function main() {
    install_misc
}

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    main
fi
