#!/usr/bin/env bats

function setup() {
    . "./install/macos/common/chezmoi.sh"
}

function teardown() {
    uninstall_chezmoi
}

@test "install chezmoi (macos)" {
    run main

    [ -x "$(command -v chezmoi)" ]
}
