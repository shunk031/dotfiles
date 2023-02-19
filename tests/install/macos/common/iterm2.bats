#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/macos/common/iterm2.sh"

function setup() {
    load "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_iterm2
}

@test "run as shellscript" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    [ -e "/Applications/iTerm.app" ]
    [ -L "${HOME%/}/Library/Application Support/iTerm2/DynamicProfiles/hotkey_window.json" ]
}
