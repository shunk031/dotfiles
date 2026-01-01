#!/usr/bin/env bash

# @file install/macos/common/misc.sh
# @brief Miscellaneous packages and applications installation script for macOS
# @description
#   This script installs various Homebrew packages and cask applications.
#   It includes both required packages for all users and optional additional
#   packages for personal computers.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly BREW_PACKAGES=(
    gpg
    imagemagick
    htop
    pinentry-mac
    tailscale
    terminal-notifier
    vim
    watchexec
    zsh
)

readonly CASK_PACKAGES=(
    adobe-acrobat-reader
    cyberduck
    google-chrome
    google-drive
    google-japanese-ime
    ngrok
    slack
    rectangle
    spotify
    vlc
    visual-studio-code
    zotero
    1password
)

# Additional brew packages that I want to install on my personal computer but not on my work computer
readonly ADDITIONAL_BREW_PACKAGES=(
    tailscale
)

# Add applications controlled by the administrator on the work computer here
readonly ADDITIONAL_CASK_PACKAGES=(
    zoom
)

# @description Check if a Homebrew package is installed
# @arg $1 string Package name to check
# @exitcode 0 If package is installed
# @exitcode 1 If package is not installed
function is_brew_package_installed() {
    local package="$1"

    brew list "${package}" &>/dev/null
}

# @description Install Homebrew packages
# @exitcode 0 On successful installation
# @exitcode 1 If installation fails
# @example
#   install_brew_packages
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

# @description Install Homebrew cask packages
# @exitcode 0 On successful installation
# @exitcode 1 If installation fails
# @example
#   install_brew_cask_packages
function install_brew_cask_packages() {
    local missing_packages=()

    for package in "${CASK_PACKAGES[@]}"; do
        if ! is_brew_package_installed "${package}"; then
            missing_packages+=("${package}")
        fi
    done

    if [[ ${#missing_packages[@]} -gt 0 ]]; then
        if "${CI:-false}"; then
            brew info --cask "${missing_packages[@]}"
        else
            brew install --cask --force "${missing_packages[@]}"
        fi
    fi
}

# @description Install additional Homebrew packages for personal computers
# @exitcode 0 On successful installation or if not personal computer
# @exitcode 1 If installation fails
# @example
#   install_additional_brew_packages
function install_additional_brew_packages() {
    # Only install additional brew packages for user shunk031
    if [[ "$(whoami)" != "shunk031" ]]; then
        return 0
    fi

    local missing_packages=()

    for package in "${ADDITIONAL_BREW_PACKAGES[@]}"; do
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

# @description Install additional Homebrew cask packages
# @exitcode 0 On successful installation or partial success
# @exitcode 1 If installation fails
# @example
#   install_additional_cask_packages
function install_additional_cask_packages() {
    local missing_packages=()

    for package in "${ADDITIONAL_CASK_PACKAGES[@]}"; do
        if ! is_brew_package_installed "${package}"; then
            missing_packages+=("${package}")
        fi
    done

    if [[ ${#missing_packages[@]} -gt 0 ]]; then
        if "${CI:-false}"; then
            brew info --cask "${missing_packages[@]}"
        else
            # Temporarily disable error exit to continue even if some packages fail
            set +e
            brew install --cask --force "${missing_packages[@]}"
            # Re-enable error exit
            set -e
        fi
    fi
}

# @description Set Google Chrome as the default browser
# @exitcode 0 On success
# @exitcode 1 If Chrome cannot be opened
# @example
#   setup_google_chrome
function setup_google_chrome() {
    open "/Applications/Google Chrome.app" --args --make-default-browser
}

# @description Main entry point for miscellaneous packages installation script
# @exitcode 0 On success
# @exitcode 1 On failure
# @example
#   ./misc.sh
function main() {
    install_brew_packages
    install_brew_cask_packages
    install_additional_brew_packages
    # install_additional_cask_packages

    # setup_google_chrome
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
