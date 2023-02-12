#!/usr/bin/env bats

function setup() {
    . "./install/macos/common/iterm2.sh"
}

@test "install iterm2" {
    main

    [ -e "/Applications/iTerm.app" ]
    [ -e "${HOME%/}/Library/Application Support/iTerm2/DynamicProfiles/hotkey_window.json" ]
}
