#!/usr/bin/env bats

function setup() {
    . "$(chezmoi source-path)/install/ubuntu/common/golang.sh"
    main # install golang

    . "$(chezmoi source-path)/install/ubuntu/common/ghq.sh"
}

function teardown() {
    uninstall_golang
    uninstall_ghq
}

@test "install ghq" {
    main # install ghq
    [ -x "$(command -v ${HOME}/ghq/bin/ghq)" ]
}
