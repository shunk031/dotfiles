#!/usr/bin/env bash

set -Eeuox pipefail

function defaults_ui() {
    # Display battery percentage
    # ref. https://github.com/todd-dsm/mac-ops/issues/39#issuecomment-962459353
    defaults write ~/Library/Preferences/ByHost/com.apple.controlcenter.plist BatteryShowPercentage -bool true
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

function kill_affected_applications() {
    local apps=(
        "Activity Monitor"
        "Address Book"
        "Calendar"
        "cfprefsd"
        "Contacts"
        "Dock"
        "Finder"
        "Google Chrome Canary"
        "Google Chrome"
        "Mail"
        "Messages"
        "Opera"
        "Photos"
        "Safari"
        "SizeUp"
        "Spectacle"
        "SystemUIServer"
        "Terminal"
        "Transmission"
        "Tweetbot"
        "Twitter"
        "iCal"
    )
    for app in "${apps[@]}"; do
        killall "${app}" &>/dev/null
    done
}

function main() {

    defaults_ui
    defaults_dock
    defaults_finder
    defaults_screencapture

    kill_affected_applications
}

# if [ ${#BASH_SOURCE[@]} = 1 ]; then
#     main
# fi
