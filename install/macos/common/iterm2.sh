#!/usr/bin/env bash

set -Eeuox pipefail

function install_item2() {
    brew install --cask iterm2
}

function initialize_iterm2() {
    while ! open -g "/Applications/iTerm.app"; do
        sleep 2
    done
}

function symlinc_config() {
    local iterm2_config_name="hotkey_window.json"
    local iterm2_config_dir="${HOME%/}/Library/Application Support/iTerm2/DynamicProfiles"

    local src_json_path="${HOME%/}/.config/iterm2/${iterm2_config_name}"
    local dst_json_path="${iterm2_config_dir}/${iterm2_config_name}"

    mkdir -p "${iterm2_config_dir}"
    ln -sfnv "${src_json_path}" "${dst_json_path}"
}

function main() {
    install_item2
    # # Disable to avoid the following error message:
    # # > Failed to load preferences from custom directory.
    # # > Failling back to local copy.
    # # This is because chezmoi create dotfiles after running the chezmoi scripts.
    # initialize_iterm2
    symlinc_config
}

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    main
fi
