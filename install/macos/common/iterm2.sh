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

function symlinc_config() {

    local src_json_path
    local dst_json_path

    src_json_path="$(chezmoi source-path)/dot_config/iterm2/${ITERM2_CONFIG_NAME}"
    dst_json_path="${ITERM2_CONFIG_DIR}/${ITERM2_CONFIG_NAME}"

    mkdir -p "${ITERM2_CONFIG_DIR}"
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

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
