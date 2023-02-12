#!/usr/bin/env bats

function setup() {
    . "./install/macos/common/ghq.sh"
}

@test "install ghq" {
    main
    [ -x "$(command -v ghq)" ]
}
