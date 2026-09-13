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
readonly ITERM2_PREFERENCES_DOMAIN="com.googlecode.iterm2"
# iTerm2 expands this tilde when it reads the custom preferences setting.
# shellcheck disable=SC2088
readonly ITERM2_PREFERENCES_SOURCE="~/.local/share/chezmoi/home/dot_config/iterm2/"
readonly ITERM2_PREFERENCES_SOURCE_PATH="${HOME%/}/.local/share/chezmoi/home/dot_config/iterm2"

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
# @description Restore iTerm2's custom preferences folder to the canonical dotfiles source.
# @stderr An error when the source preferences plist is missing or malformed.
# @exitcode 0 When the custom preferences settings are reconciled.
# @exitcode 1 When the source preferences plist cannot be loaded.
#
function reconcile_iterm2_preferences_source() {
    local preferences_file="${ITERM2_PREFERENCES_SOURCE_PATH}/${ITERM2_PREFERENCES_DOMAIN}.plist"
    local current_source
    local load_from_custom_folder

    if ! plutil -lint "${preferences_file}" > /dev/null 2>&1; then
        printf 'iTerm2 preferences plist is missing or malformed: %s\n' "${preferences_file}" >&2
        return 1
    fi

    current_source="$(defaults read "${ITERM2_PREFERENCES_DOMAIN}" PrefsCustomFolder 2> /dev/null || true)"
    load_from_custom_folder="$(defaults read "${ITERM2_PREFERENCES_DOMAIN}" LoadPrefsFromCustomFolder 2> /dev/null || true)"

    if [ "${current_source}" != "${ITERM2_PREFERENCES_SOURCE}" ]; then
        defaults write "${ITERM2_PREFERENCES_DOMAIN}" PrefsCustomFolder "${ITERM2_PREFERENCES_SOURCE}"
    fi
    if [ "${load_from_custom_folder}" != "1" ]; then
        defaults write "${ITERM2_PREFERENCES_DOMAIN}" LoadPrefsFromCustomFolder -bool true
    fi
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
