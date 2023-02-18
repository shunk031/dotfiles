#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/tmux.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_tmux
}

@test "PACKAGES" {
    [ ${#PACKAGES[@]} -eq 3 ]
}

@test "main" {
    run main

    [ -x "$(command -v tmux)" ]
    [ -x "$(command -v xsel)" ]
    [ -x "$(command -v cmake)" ]
}

@test "main with set -x" {
    run main

    [ -x "$(command -v tmux)" ]
    [ -x "$(command -v xsel)" ]
    [ -x "$(command -v cmake)" ]
}

@test "run as shellscript" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    [ -x "$(command -v tmux)" ]
    [ -x "$(command -v xsel)" ]
    [ -x "$(command -v cmake)" ]
}
