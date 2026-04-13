#!/usr/bin/env bash

# @file install/macos/common/tmux.sh
# @brief Install tmux on macOS.
# @description
#   Installs or removes `tmux`, with a GitHub Actions-specific workaround for
#   brew dependency resolution.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly PACKAGES=(
    tmux
)

#
# @description Install `tmux` while tolerating the CI CMake pinning issue.
#
function install_tmux() {
    # On GitHub Actions macOS instances, reinstalling CMake fails.
    # Implement the following workaround to avoid this issue.
    # ref. [macOS] Pinned CMake causes some homebrew installs to fail · Issue #12912 · actions/runner-images https://github.com/actions/runner-images/issues/12912#issuecomment-3240845829
    for package in "${PACKAGES[@]}"; do
        brew list "${package}" || brew install "${package}"
    done
}

#
# @description Remove the installed `tmux` package.
#
function uninstall_tmux() {
    brew uninstall "${PACKAGES[@]}"
}

#
# @description Run the tmux installation flow.
#
function main() {
    install_tmux
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
