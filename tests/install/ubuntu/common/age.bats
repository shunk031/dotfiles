#!/usr/bin/env bats

function setup() {
    . "./install/ubuntu/common/age.sh"
}

function teardown() {
    uninstall_age
    uninstall_jq
}

@test "install age (ubuntu)" {
    run install_age
    [ -x "$(command -v age)" ]

    run install_jq
    [ -x "$(command -v jq)" ]
}
