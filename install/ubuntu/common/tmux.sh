#!/usr/bin/env bash

# @file install/ubuntu/common/tmux.sh
# @brief Tmux and related dependencies installation script for Ubuntu
# @description
#   This script installs tmux, xsel for clipboard integration,
#   and cmake which is required for building tmux plugins.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly PACKAGES=(
    tmux
    # git
    xsel
    cmake
)

# @description Install tmux and its dependencies
# @exitcode 0 On successful installation
# @exitcode 1 If installation fails
# @example
#   install_tmux
function install_tmux() {
    sudo apt-get install -y "${PACKAGES[@]}"
}

# @description Uninstall tmux and its dependencies
# @exitcode 0 On successful removal
# @exitcode 1 If removal fails
# @example
#   uninstall_tmux
function uninstall_tmux() {
    sudo apt-get remove -y "${PACKAGES[@]}"
}

# @description Main entry point for the tmux installation script
# @exitcode 0 On success
# @exitcode 1 On failure
# @example
#   ./tmux.sh
function main() {
    install_tmux
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
