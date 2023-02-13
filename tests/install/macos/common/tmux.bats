#!/usr/bin/env bats

set -Eeuo pipefail

function setup() {
    . "./install/macos/common/tmux.sh"
}

function teardown() {
    uninstall_tmux
}

@test "install tmux (macos)" {
    run install_tmux

    run brew info tmux
    [ "${status}" -eq 0 ]
    run brew info reattach-to-user-namespace
    [ "${status}" -eq 0 ]
    run brew info cmake
    [ "${status}" -eq 0 ]
}
