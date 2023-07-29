#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/age.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_age
    run uninstall_jq

    # reset PATH
    PATH=$(getconf PATH)
    export PATH
}

@test "[ubuntu-common] age" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    export PATH="${PATH}:${HOME%/}/.local/bin"
    [ -x "$(command -v age)" ]
    [ -x "$(command -v jq)" ]
}
