#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/macos/common/iterm2.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_iterm2
}

@test "[macos] iterm2" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    [ -e "/Applications/iTerm.app" ]
    [ -L "${HOME%/}/Library/Application Support/iTerm2/DynamicProfiles/hotkey_window.json" ]
}
