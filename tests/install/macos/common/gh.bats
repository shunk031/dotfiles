#!/usr/bin/env bats

function setup() {
    . "./install/macos/common/gh.sh"
}

function teardown() {
    uninstall_gh
}

@test "install gh" {
    main
    [ -x "$(command -v gh)" ]
}
