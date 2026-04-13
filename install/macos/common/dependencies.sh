#!/usr/bin/env bash

# @file install/macos/common/dependencies.sh
# @brief Install essential Homebrew packages for macOS.
# @description
#   Installs the core command-line packages required by the dotfiles.
#   Optional utilities and GUI applications live in
#   `install/macos/common/misc.sh`.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly BREW_PACKAGES=(
    cmake
    git
    gawk
    gpg
    pinentry-mac
    vim
    zsh
)

#
# @description Check whether a Homebrew package is already installed.
# @arg $1 string Homebrew package name.
#
function is_brew_package_installed() {
    local package="$1"

    brew list "${package}" &> /dev/null
}

#
# @description Install every missing package from `BREW_PACKAGES`.
#
function install_brew_packages() {
    local missing_packages=()

    for package in "${BREW_PACKAGES[@]}"; do
        if ! is_brew_package_installed "${package}"; then
            missing_packages+=("${package}")
        fi
    done

    if [[ ${#missing_packages[@]} -gt 0 ]]; then
        if "${CI:-false}"; then
            brew info "${missing_packages[@]}"
        else
            brew install --force "${missing_packages[@]}"
        fi
    fi
}

#
# @description Install the required Homebrew dependencies.
#
function main() {
    install_brew_packages
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
