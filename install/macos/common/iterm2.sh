#!/usr/bin/env bash

# @file install/macos/common/iterm2.sh
# @brief iTerm2 terminal emulator installation script
# @description
#   This script installs iTerm2, a replacement for Terminal on macOS,
#   and manages its configuration including dynamic profiles.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly ITERM2_CONFIG_NAME="hotkey_window.json"
readonly ITERM2_CONFIG_DIR="${HOME%/}/Library/Application Support/iTerm2/DynamicProfiles"

# @description Install iTerm2 via Homebrew cask
# @exitcode 0 On successful installation
# @exitcode 1 If installation fails
# @example
#   install_item2
function install_item2() {
    brew install --cask iterm2
}

# @description Uninstall iTerm2 and remove its configuration
# @exitcode 0 On successful removal
# @exitcode 1 If removal fails
# @example
#   uninstall_iterm2
function uninstall_iterm2() {
    brew uninstall --cask iterm2
    rm -fv "${ITERM2_CONFIG_DIR}/${ITERM2_CONFIG_NAME}"
}

# @description Initialize iTerm2 by opening it in the background
# @exitcode 0 On success
# @exitcode 1 If iTerm2 cannot be opened
# @example
#   initialize_iterm2
function initialize_iterm2() {
    while ! open -g "/Applications/iTerm.app"; do
        sleep 2
    done
}

# @description Main entry point for the iTerm2 installation script
# @exitcode 0 On success
# @exitcode 1 On failure
# @example
#   ./iterm2.sh
function main() {
    install_item2
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
