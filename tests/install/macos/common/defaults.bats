#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/macos/common/defaults.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function dock_app_path() {
    local dock_plist="$1"
    local app_index="$2"

    plutil -extract "persistent-apps.${app_index}.tile-data.file-data._CFURLString" raw -o - "${dock_plist}"
}

@test "[macos] test for ui" {
    defaults_ui

    [ $(defaults read ~/Library/Preferences/ByHost/com.apple.controlcenter.plist BatteryShowPercentage) -eq 1 ]
}

@test "[macos] test for keyboard" {
    defaults_keyboard

    [ $(defaults read NSGlobalDomain KeyRepeat) -eq 2 ]
    [ $(defaults read NSGlobalDomain InitialKeyRepeat) -eq 25 ]
}

@test "[macos] test for trackpad" {
    defaults_trackpad

    [ $(defaults read -g com.apple.trackpad.scaling) -eq 2 ]

    [ $(defaults read NSGlobalDomain com.apple.mouse.tapBehavior) -eq 1 ]
    [ $(defaults -currentHost read NSGlobalDomain com.apple.mouse.tapBehavior) -eq 1 ]
    [ $(defaults read com.apple.AppleMultitouchTrackpad Clicking) -eq 1 ]
    [ $(defaults read com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking) -eq 1 ]

    [ $(defaults read com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag) -eq 1 ]
    [ $(defaults read com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag) -eq 1 ]
}

@test "[macos] test for control center" {
    defaults_controlcenter

    [ $(defaults read com.apple.controlcenter "NSStatusItem Visible Bluetooth") -eq 1 ]
}

@test "[macos] test for dock" {
    defaults_dock

    local dock_plist
    dock_plist="$(mktemp)"

    [ $(defaults read com.apple.dock autohide) -eq 1 ]
    [ $(defaults read com.apple.dock tilesize) -eq 30 ]
    [ $(defaults read com.apple.dock mru-spaces) -eq 0 ]

    defaults export com.apple.dock - > "${dock_plist}"

    [ "$(dock_app_path "${dock_plist}" 0)" = "/Applications/Google Chrome.app" ]
    [ "$(dock_app_path "${dock_plist}" 1)" = "/Applications/Visual Studio Code.app" ]
    [ "$(dock_app_path "${dock_plist}" 2)" = "/Applications/Slack.app" ]
    [ "$(dock_app_path "${dock_plist}" 3)" = "/Applications/iTerm.app" ]
    [ "$(dock_app_path "${dock_plist}" 4)" = "/Applications/cmux.app" ]
    [ "$(dock_app_path "${dock_plist}" 5)" = "$(get_system_app_path)" ]

    rm -f "${dock_plist}"
}
