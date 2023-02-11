#!/usr/bin/env bats

set -Eeuo pipefail

function setup() {
    . "./install/macos/common/defaults.sh"
}

@test "test for ui" {
    defaults_ui

    [ $(defaults read ~/Library/Preferences/ByHost/com.apple.controlcenter.plist BatteryShowPercentage) -eq 1 ]
}

@test "test for keyboard" {
    defaults_keyboard

    [ $(defaults read NSGlobalDomain KeyRepeat) -eq 2 ]
    [ $(defaults read NSGlobalDomain InitialKeyRepeat) -eq 25 ]
}

@test "test for trackpad" {
    defaults_trackpad

    [ $(defaults read -g com.apple.trackpad.scaling) -eq 2 ]
}
