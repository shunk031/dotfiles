#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/macos/common/tmux.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_tmux
}

@test "[macos] tmux" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    run brew info tmux
    [ "${status}" -eq 0 ]
    run brew info reattach-to-user-namespace
    [ "${status}" -eq 0 ]
    run brew info cmake
    [ "${status}" -eq 0 ]
}
