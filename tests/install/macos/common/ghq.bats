#!/usr/bin/env bats

function setup() {
    . "./install/macos/common/ghq.sh"
}

function teardown() {
    uninstall_ghq
}

@test "install ghq" {
    main
    [ -x "$(command -v ghq)" ]
}
