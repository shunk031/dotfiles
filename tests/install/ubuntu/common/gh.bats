#!/usr/bin/env bats

function setup() {
    . "./install/ubuntu/common/gh.sh"
}

@test "install gh" {
    main
    [ -x "$(command -v gh)" ]
}
