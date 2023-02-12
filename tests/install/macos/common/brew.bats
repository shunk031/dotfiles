#!/usr/bin/env bats

set -Eeuo pipefail

function setup() {
    . "./install/macos/common/brew.sh"
}

@test "install brew" {
    run main

    [ -x "$(command -v brew)" ]
}
