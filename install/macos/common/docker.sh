#!/usr/bin/env bash

# @file install/macos/common/docker.sh
# @brief Install Docker Desktop on macOS.
# @description
#   Installs or removes the Docker Desktop cask through Homebrew.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

#
# @description Install the Docker Desktop Homebrew cask.
#
function install_docker() {
    brew install --cask docker
}

#
# @description Remove the Docker Desktop Homebrew cask.
#
function uninstall_docker() {
    brew uninstall --cask docker --force
}

#
# @description Run the Docker Desktop installation flow.
#
function main() {
    install_docker
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
