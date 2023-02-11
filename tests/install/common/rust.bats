#!/usr/bin/env bats

set -Eeuo pipefail

function setup() {
    . "./install/common/rust.sh"
}

@test "install rust" {
    main

    [ -x "$(command -v cargo)" ]
}
