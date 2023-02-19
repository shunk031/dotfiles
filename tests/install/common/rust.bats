#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/rust.sh"

function setup() {
    load "${SCRIPT_PATH}"
}

function teardown() {
    uninstall_rust

    # reset PATH
    PATH=$(getconf PATH)
    export PATH
}

@test "run as shellscript" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    export PATH="${PATH}:${HOME}/.cargo/bin"
    [ -x "$(command -v cargo)" ]
}
