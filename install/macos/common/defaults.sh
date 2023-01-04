#!/usr/bin/env bash

set -Euox pipefail

function defaults_ui() {
    # Display battery percentage
    # ref. https://github.com/todd-dsm/mac-ops/issues/39#issuecomment-962459353
    defaults write ~/Library/Preferences/ByHost/com.apple.controlcenter.plist BatteryShowPercentage -bool true
}

function defaults_keyboard() {
    # Set a blazingly fast keyboard repeat rate
    defaults write NSGlobalDomain KeyRepeat -int 2
    # Set a shorter Delay until key repeat
    defaults write NSGlobalDomain InitialKeyRepeat -int 25
}

function defaults_trackpad() {

    defaults write -g com.apple.trackpad.scaling 2

    # Trackpad: enable tap to click for this user and for the login screen
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

    # Enable 3-fingers drag
    defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
}

function defaults_dock() {
    # Automatically hide and show the Dock
    defaults write com.apple.dock autohide -bool true
    # Set the icon size of Dock items to 30 pixels
    defaults write com.apple.dock tilesize -int 30
}

function defaults_finder() {
    # Show all filename extensions
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    # Disable the warning when changing a file extension
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
}

function defaults_screencapture() {
    # Save screenshots to ${HOME}/Pictures/
    defaults write com.apple.screencapture location -string "${HOME}/Pictures/"
    defaults write com.apple.screencapture name -string "Screen Shot"
}

function defaults_assistant() {
    defaults write com.apple.assistant.support "Assistant Enabled" -bool false
    defaults write com.apple.assistant.support "Dictation Enabled" -bool false
}

function kill_affected_applications() {
    local apps=(
        "Activity Monitor"
        "Calendar"
        "cfprefsd"
        "Dock"
        "Finder"
        "Google Chrome Canary"
        "Google Chrome"
        "SizeUp"
        "Spectacle"
        "SystemUIServer"
        "Terminal"
        "Transmission"
        "Twitter"
    )
    for app in "${apps[@]}"; do
        killall "${app}" &>/dev/null
    done
}

function main() {

    defaults_ui
    defaults_dock
    defaults_finder
    defaults_keyboard
    defaults_trackpad
    defaults_assistant
    defaults_screencapture

    kill_affected_applications
}

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    main
fi
