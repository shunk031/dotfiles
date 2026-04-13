#!/usr/bin/env bash

# @file install/macos/common/iterm2.sh
# @brief Install iTerm2 and manage its dynamic profile setup.
# @description
#   Installs the iTerm2 cask and provides helpers for initializing or removing
#   the repository-managed dynamic profile.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly ITERM2_CONFIG_NAME="hotkey_window.json"
readonly ITERM2_CONFIG_DIR="${HOME%/}/Library/Application Support/iTerm2/DynamicProfiles"

#
# @description Install the iTerm2 Homebrew cask.
#
function install_item2() {
    brew install --cask iterm2
}

#
# @description Uninstall iTerm2 and remove the managed dynamic profile file.
#
function uninstall_iterm2() {
    brew uninstall --cask iterm2
    rm -fv "${ITERM2_CONFIG_DIR}/${ITERM2_CONFIG_NAME}"
}

#
# @description Open iTerm2 until the application can be launched.
#
function initialize_iterm2() {
    while ! open -g "/Applications/iTerm.app"; do
        sleep 2
    done
}

#
# @description Run the iTerm2 installation flow.
#
function main() {
    install_item2
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
