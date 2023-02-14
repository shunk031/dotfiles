#!/usr/bin/env bats

function setup() {
    . "./install/ubuntu/common/misc.sh"
}

function teardown() {
    run uninstall_apt_packages
}

@test "install misc (ubuntu)" {
    run main

    [ -x "$(command -v exa)" ]
    [ -x "$(command -v jq)" ]
    [ -x "$(command -v htop)" ]
    [ -x "$(command -v shellcheck)" ]
    [ -x "$(command -v vim)" ]
    [ -x "$(command -v zsh)" ]
}
