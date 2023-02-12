#!/usr/bin/env bats

function setup() {
    . "./install/ubuntu/common/tmux.sh"
}

function teardown() {
    uninstall_tmux
}

@test "install tmux requirements (ubuntu)" {
    run main

    [ -x "$(command -v tmux)" ]
    [ -x "$(command -v xsel)" ]
    [ -x "$(command -v cmake)" ]
}
