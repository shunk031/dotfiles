#!/usr/bin/env bats

function setup() {
    . "./install/macos/common/iterm2.sh"
}

function teardown() {
    uninstall_iterm2
}

@test "install iterm2" {
    run main

    [ -e "/Applications/iTerm.app" ]
    [ -e "${HOME%/}/Library/Application Support/iTerm2/DynamicProfiles/hotkey_window.json" ]
}
