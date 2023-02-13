#!/usr/bin/env bats

function setup() {
    . "./install/macos/common/gh.sh"
}

function teardown() {
    run uninstall_gh
}

@test "install gh" {
    run main
    [ -x "$(command -v gh)" ]
}
