#!/usr/bin/env bats

function setup() {
    . "./install/ubuntu/common/gh.sh"
}

function teardown() {
    uninstall_gh
}

@test "install gh" {
    run main
    [ -x "$(command -v gh)" ]
}
