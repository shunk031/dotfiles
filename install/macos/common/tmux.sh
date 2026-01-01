#!/usr/bin/env bash

# @file install/macos/common/tmux.sh
# @brief Tmux and related dependencies installation script for macOS
# @description
#   This script installs tmux, reattach-to-user-namespace for clipboard integration,
#   and cmake which is required for building tmux plugins.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly PACKAGES=(
    tmux
    # git
    reattach-to-user-namespace
    cmake
)

# @description Install tmux and its dependencies via Homebrew
# @exitcode 0 On successful installation
# @exitcode 1 If installation fails
# @example
#   install_tmux
function install_tmux() {
    # On GitHub Actions macOS instances, reinstalling CMake fails. 
    # Implement the following workaround to avoid this issue.
    # ref. [macOS] Pinned CMake causes some homebrew installs to fail · Issue #12912 · actions/runner-images https://github.com/actions/runner-images/issues/12912#issuecomment-3240845829 
    for package in "${PACKAGES[@]}"; do
        brew list "${package}" || brew install "${package}"
    done
}

# @description Uninstall tmux and its dependencies
# @exitcode 0 On successful removal
# @exitcode 1 If removal fails
# @example
#   uninstall_tmux
function uninstall_tmux() {
    brew uninstall "${PACKAGES[@]}"
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
