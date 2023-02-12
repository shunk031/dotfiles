#!/usr/bin/env bats

function setup() {
    . "./install/ubuntu/common/gh.sh"
}

@test "install gh" {
    run main
    [ -x "$(command -v gh)" ]
}
