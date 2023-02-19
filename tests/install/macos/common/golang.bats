#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/macos/common/golang.sh"

function setup() {
    load "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_golang

    # reset PATH
    PATH=$(getconf PATH)
    export PATH
}

@test "run as shellscript" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    export PATH="${PATH}:/usr/local/go/bin"
    [ -x "$(command -v go)" ]
}
