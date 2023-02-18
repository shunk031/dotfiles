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

@test "install_rust" {
    run install_rust

    export PATH="${PATH}:${HOME}/.cargo/bin"
    [ -x "$(command -v cargo)" ]
}

@test "main" {
    run main

    export PATH="${PATH}:${HOME}/.cargo/bin"
    [ -x "$(command -v cargo)" ]
}

@test "run as shellscript" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    export PATH="${PATH}:${HOME}/.cargo/bin"
    [ -x "$(command -v cargo)" ]
}
