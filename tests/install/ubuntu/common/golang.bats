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

@test "[ubuntu-common] golang" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    export PATH="${PATH}:/usr/local/go/bin"
    [ -x "$(command -v go)" ]
}
