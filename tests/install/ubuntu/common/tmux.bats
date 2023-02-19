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

@test "[ubuntu-common] tmux" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    [ -x "$(command -v tmux)" ]
    [ -x "$(command -v xsel)" ]
    [ -x "$(command -v cmake)" ]
}
