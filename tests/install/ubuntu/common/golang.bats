#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/golang.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_golang

    # reset PATH
    PATH=$(getconf PATH)
    export PATH
}

@test "get_latest_version" {
    run get_latest_version
    [ "${status}" -eq 0 ]
}

@test "install_golang" {
    run install_golang

    export PATH="${PATH}:/usr/local/go/bin"
    [ -x "$(command -v go)" ]
}

@test "main" {
    run main

    export PATH="${PATH}:/usr/local/go/bin"
    [ -x "$(command -v go)" ]
}

@test "run as shellscript" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    export PATH="${PATH}:/usr/local/go/bin"
    [ -x "$(command -v go)" ]
}
