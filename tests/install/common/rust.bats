#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/rust.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    uninstall_rust

    # reset PATH
    PATH=$(getconf PATH)
    export PATH
}

@test "[common] rust" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    export PATH="${PATH}:${HOME}/.cargo/bin"
    [ -x "$(command -v cargo)" ]
}
