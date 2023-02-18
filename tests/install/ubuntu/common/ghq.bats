#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/ghq.sh"

function setup() {
    source "./install/ubuntu/common/golang.sh"
    main # install golang

    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_golang
    run uninstall_ghq

    # reset PATH
    PATH=$(getconf PATH)
    export PATH
}

@test "install_ghq" {
    run install_ghq

    export GOPATH="${HOME%/}/ghq"
    export PATH="${PATH}:${GOPATH}/bin"
    [ -x "$(command -v ghq)" ]
}

@test "main" {
    run main

    export GOPATH="${HOME%/}/ghq"
    export PATH="${PATH}:${GOPATH}/bin"
    [ -x "$(command -v ghq)" ]
}

@test "run as shellscript" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    export GOPATH="${HOME%/}/ghq"
    export PATH="${PATH}:${GOPATH}/bin"
    [ -x "$(command -v ghq)" ]
}
