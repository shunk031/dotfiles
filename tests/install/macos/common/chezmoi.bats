#!/usr/bin/env bats

set -Eeuo pipefail

function setup() {
    . "./install/macos/common/chezmoi.sh"
}

@test "install chezmoi (macos)" {
    main

    run brew info chezmoi
    [ "${status}" -eq 0 ]
}
