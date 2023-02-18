#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/age.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_age
    run uninstall_jq
}

@test "install_age" {
    run install_age
    [ -x "$(command -v age)" ]
}

@test "install_jq" {
    run install_jq
    [ -x "$(command -v jq)" ]
}

@test "main" {
    run main
    [ -x "$(command -v age)" ]
    [ -x "$(command -v jq)" ]
}

@test "run as shellscript" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    [ -x "$(command -v age)" ]
    [ -x "$(command -v jq)" ]
}
