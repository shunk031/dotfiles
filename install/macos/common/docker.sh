#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_docker() {
    brew install --cask rancher
}

function uninstall_docker() {
    brew uninstall --cask rancher --force
}

function use_rosetta() {
    rdctl set \
        --experimental.virtual-machine.type vz \
        --experimental.virtual-machine.mount.type virtiofs \
        --experimental.virtual-machine.socket-vmnet \
        --experimental.virtual-machine.use-rosetta
}

function main() {
    install_docker
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
