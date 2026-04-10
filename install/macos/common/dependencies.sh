#!/usr/bin/env bash

#
# dependencies.sh
#
# Installs the essential command-line packages required for the dotfiles to function properly.
# This script is limited to core dependencies.
# For optional utilities, GUI apps, or user-specific tools, see install/macos/common/misc.sh.
#

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly BREW_PACKAGES=(
    cmake
    git
    gpg
    pinentry-mac
    vim
    zsh
)

function is_brew_package_installed() {
    local package="$1"

    brew list "${package}" &> /dev/null
}

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

function main() {
    install_brew_packages
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
