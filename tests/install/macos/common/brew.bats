#!/usr/bin/env bats

function setup() {
    . "./install/macos/common/brew.sh"
}

@test "install brew" {
    run install_homebrew

    [ -x "$(command -v brew)" ]
}
