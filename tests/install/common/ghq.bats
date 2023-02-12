#!/usr/bin/env bats

set -Eeuo pipefail

function setup() {
    . "./install/common/ghq.sh"
}

@test "install ghq (common)" {
    run main

    [ -d "${HOME%/}/ghq" ]
}
