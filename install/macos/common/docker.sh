#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_docker_docker_compose() {
    brew install --cask docker
}

function uninstall_docker_docker_compose() {
    brew uninstall docker
}

function main() {
    install_docker_docker_compose
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
