#!/usr/bin/env bats

function setup() {
    . "./install/macos/common/golang.sh"
}

function teardown() {
    run uninstall_golang
}

@test "install golang (macos)" {
    run main
    export PATH="${PATH}:/usr/local/go/bin"
    [ -x "$(command -v go)" ]
}
