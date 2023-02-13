#!/usr/bin/env bats

function setup() {
    . "./install/macos/common/ghq.sh"
}

function teardown() {
    run uninstall_ghq
}

@test "install ghq" {
    run main
    [ -x "$(command -v ghq)" ]
}
