#!/usr/bin/env bash

set -Eeuox pipefail

function install_openssh() {
    sudo apt-get install -y openssh-client
}

function main() {
    install_openssh
}

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    main
fi
