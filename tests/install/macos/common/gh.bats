#!/usr/bin/env bats

function setup() {
    . "./install/macos/common/gh.sh"
}

@test "install gh" {
    main
    [ -x "$(command -v gh)" ]
}
