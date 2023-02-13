#!/usr/bin/env bats

function setup() {
    . "./install/ubuntu/common/golang.sh"
}

function teardown() {
    uninstall_golang
}

@test "install golang (ubuntu)" {
    run main
    export PATH="${PATH}:/usr/local/go/bin"
    [ -x "$(command -v go)" ]
}
