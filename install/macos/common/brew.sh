#!/usr/bin/env bash

# @file install/macos/common/brew.sh
# @brief Install Homebrew and apply repository defaults.
# @description
#   Ensures Homebrew is installed on macOS and disables analytics for the local
#   user.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

#
# @description Check whether Homebrew is already available on `PATH`.
#
function is_homebrew_exists() {
    command -v brew &> /dev/null
}

#
# @description Install Homebrew when it is not present.
#
function install_homebrew() {
    if ! is_homebrew_exists; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
}

#
# @description Disable Homebrew analytics for the current user.
#
function opt_out_of_analytics() {
    brew analytics off
}

#
# @description Install Homebrew and apply repository defaults.
#
function main() {
    install_homebrew
    opt_out_of_analytics
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
