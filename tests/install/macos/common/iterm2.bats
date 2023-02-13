#!/usr/bin/env bats

function setup() {
    . "./install/macos/common/iterm2.sh"
}

function teardown() {
    run uninstall_iterm2
}

@test "install iterm2" {
    run main

    run ls "${HOME%/}/Library/Application Support/iTerm2/DynamicProfiles"

    [ -e "/Applications/iTerm.app" ]
    [ -L "${HOME%/}/Library/Application Support/iTerm2/DynamicProfiles/hotkey_window.json" ]
}
