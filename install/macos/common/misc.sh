#!/usr/bin/env bash

# @file install/macos/common/misc.sh
# @brief Install optional macOS utilities and GUI applications.
# @description
#   Installs non-essential brew packages, casks, and user-specific extras for
#   daily development use.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly BREW_PACKAGES=(
    imagemagick
    htop
    terminal-notifier
    watchexec
)

readonly BREW_TAPS=(
    manaflow-ai/cmux
)

readonly CASK_PACKAGES=(
    adobe-acrobat-reader
    cmux
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

# Additional brew packages installed only for user shunk031.
readonly ADDITIONAL_BREW_PACKAGES=(
    tailscale
)

# Add applications controlled by the administrator on the work computer here
readonly ADDITIONAL_CASK_PACKAGES=(
    zoom
)

#
# @description Check whether a brew package or cask is already installed.
# @arg $1 string Package or cask name.
#
function is_brew_package_installed() {
    local package="$1"

    brew list "${package}" &> /dev/null
}

#
# @description Check whether a brew tap is already configured.
# @arg $1 string Tap name.
#
function is_brew_tap_installed() {
    local tap="$1"

    brew tap | grep --fixed-strings --line-regexp --quiet "${tap}"
}

#
# @description Install every missing tap from `BREW_TAPS` unless running in CI.
#
function install_brew_taps() {
    if "${CI:-false}"; then
        return 0
    fi

    local missing_taps=()
    local tap

    for tap in "${BREW_TAPS[@]}"; do
        if ! is_brew_tap_installed "${tap}"; then
            missing_taps+=("${tap}")
        fi
    done

    if [[ ${#missing_taps[@]} -gt 0 ]]; then
        for tap in "${missing_taps[@]}"; do
            brew tap "${tap}"
        done
    fi
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
# @description Install every missing cask from `CASK_PACKAGES`.
#
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

#
# @description Install additional brew packages for the primary user only.
#
function install_additional_brew_packages() {
    # Restrict personal packages to the primary user account.
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

#
# @description Install additional casks that may fail independently.
#
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

#
# @description Open Google Chrome and prompt it to become the default browser.
#
function setup_google_chrome() {
    open "/Applications/Google Chrome.app" --args --make-default-browser
}

#
# @description Install the configured optional macOS packages and casks.
#
function main() {
    install_brew_taps
    install_brew_packages
    install_brew_cask_packages
    install_additional_brew_packages
    # install_additional_cask_packages

    # setup_google_chrome
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
