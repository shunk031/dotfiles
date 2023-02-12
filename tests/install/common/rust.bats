#!/usr/bin/env bats

set -Eeuo pipefail

function setup() {
    . "./install/common/rust.sh"
}

@test "install rust" {
    main

    export PATH="${PATH}:${HOME}/.cargo/bin"
    [ -x "$(command -v cargo)" ]
}
