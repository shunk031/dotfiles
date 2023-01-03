#!/usr/bin/env bash

set -Eeuo pipefail

function install_item2() {
    brew install --cask iterm2
}

function initialize_iterm2() {
    open -g "/Applications/iTerm.app" && sleep 2
}

function symlinc_config() {
    local iterm2_config_name="hotkey_window.json"

    local src_json_path="${HOME%/}/.config/iterm2/${iterm2_config_name}"
    local dst_json_path="${HOME%/}/Library/Application Support/iTerm2/DynamicProfiles/${iterm2_config_name}"

    ln -sfnv "${src_json_path}" "${dst_json_path}"
}

function main() {
    install_item2
    initialize_iterm2
    symlinc_config
}

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    main
fi
