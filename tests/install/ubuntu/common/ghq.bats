#!/usr/bin/env bats

function setup() {
    . "./install/ubuntu/common/golang.sh"
    main # install golang

    . "./install/ubuntu/common/ghq.sh"
}

# function teardown() {
#     uninstall_golang
#     uninstall_ghq
# }

@test "install ghq" {
    run main

    export GOPATH="${HOME%/}/ghq"
    export PATH="${PATH}:${GOPATH}/bin"
    [ -x "$(command -v ghq)" ]
}
