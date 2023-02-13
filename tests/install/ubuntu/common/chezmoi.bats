#!/usr/bin/env bats

function setup() {
    . "./install/ubuntu/common/chezmoi.sh"
}

function teardown() {
    run uninstall_chezmoi
}

@test "install chezmoi (ubuntu)" {
    run main
    [ -x "$(command -v chezmoi)" ]
}
