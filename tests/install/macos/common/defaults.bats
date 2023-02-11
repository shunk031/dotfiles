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

    [ $(defaults read NSGlobalDomain com.apple.mouse.tapBehavior) -eq 1 ]
    [ $(defaults -currentHost read NSGlobalDomain com.apple.mouse.tapBehavior) -eq 1 ]
    [ $(defaults read com.apple.AppleMultitouchTrackpad Clicking) -eq 1 ]
    [ $(defaults read com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking) -eq 1 ]

    [ $(defaults read com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag) -eq 1 ]
    [ $(defaults read com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag) -eq 1 ]
}

@test "test for control center" {
    defaults_controlcenter

    [ $(defaults read com.apple.controlcenter "NSStatusItem Visible Bluetooth") -eq 1 ]
}

@test "test for dock" {
    defaults_dock

    [ $(defaults read com.apple.dock autohide) -eq 1 ]
    [ $(defaults read com.apple.dock tilesize) -eq 30 ]
}
