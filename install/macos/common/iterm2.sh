#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly ITERM2_CONFIG_NAME="hotkey_window.json"
readonly ITERM2_CONFIG_DIR="${HOME%/}/Library/Application Support/iTerm2/DynamicProfiles"

function install_item2() {
    brew install --cask iterm2
}

function uninstall_iterm2() {
    brew uninstall --cask iterm2
    rm -fv "${ITERM2_CONFIG_DIR}/${ITERM2_CONFIG_NAME}"
}

function initialize_iterm2() {
    while ! open -g "/Applications/iTerm.app"; do
        sleep 2
    done
}

function main() {
    install_item2
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
