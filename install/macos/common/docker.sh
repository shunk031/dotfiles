#!/usr/bin/env bash

# @file install/macos/common/docker.sh
# @brief Docker Desktop installation script for macOS
# @description
#   This script installs Docker Desktop using Homebrew cask.
#   Docker Desktop provides containerization capabilities on macOS.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

# @description Install Docker Desktop via Homebrew cask
# @exitcode 0 On successful installation
# @exitcode 1 If installation fails
# @example
#   install_docker
function install_docker() {
    brew install --cask docker
}

# @description Uninstall Docker Desktop
# @exitcode 0 On successful removal
# @exitcode 1 If removal fails
# @example
#   uninstall_docker
function uninstall_docker() {
    brew uninstall --cask docker --force
}

# @description Main entry point for the Docker installation script
# @exitcode 0 On success
# @exitcode 1 On failure
# @example
#   ./docker.sh
function main() {
    install_docker
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
