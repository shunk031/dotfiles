#!/usr/bin/env bash

# @file install/macos/common/brew.sh
# @brief Homebrew package manager installation script
# @description
#   This script installs Homebrew, the package manager for macOS,
#   and configures privacy settings by disabling analytics.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

# @description Check if Homebrew command is available in PATH
# @exitcode 0 If Homebrew is installed
# @exitcode 1 If Homebrew is not installed
function is_homebrew_exists() {
    command -v brew &>/dev/null
}

# @description Install Homebrew package manager
# @exitcode 0 On success or if Homebrew is already installed
# @exitcode 1 If installation fails
# @example
#   install_homebrew
function install_homebrew() {
    if ! is_homebrew_exists; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
}

# @description Disable Homebrew analytics to protect privacy
# @exitcode 0 On success
# @exitcode 1 If command fails
# @example
#   opt_out_of_analytics
function opt_out_of_analytics() {
    brew analytics off
}

# @description Main entry point for the Homebrew installation script
# @exitcode 0 On success
# @exitcode 1 On failure
# @example
#   ./brew.sh
function main() {
    install_homebrew
    opt_out_of_analytics
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
