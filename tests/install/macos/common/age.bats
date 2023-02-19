#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/macos/common/age.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_age
    run uninstall_jq
}

@test "[macos] age" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    [ -x "$(command -v age)" ]
    [ -x "$(command -v jq)" ]
}
