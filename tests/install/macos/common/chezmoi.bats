#!/usr/bin/env bats

set -Eeuo pipefail

function setup() {
    . "./install/macos/common/chezmoi.sh"
}

function teardown() {
    uninstall_chezmoi
}

@test "install chezmoi (macos)" {
    main

    [ -x "$(command -v chezmoi)" ]
}
