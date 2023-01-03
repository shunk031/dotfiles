#!/usr/bin/env bash

set -Eeuox pipefail

function is_xcode_installed() {
    local xcode_path
    xcode_path="/Applications/XCode.app"

    if [ -d "${xcode_path}" ]; then
        return 0
    else
        return 1
    fi
}

function install_xcode() {
    if ! is_xcode_installed; then
        open macappstores://itunes.apple.com/en/app/xcode/id497799835
    fi
}

function main() {
    install_xcode
}

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    main
fi
