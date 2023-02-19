#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/ghq.sh"

function setup() {
    load "./install/ubuntu/common/golang.sh"
    main # install golang

    load "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_golang
    run uninstall_ghq

    # reset PATH
    PATH=$(getconf PATH)
    export PATH
}

@test "run as shellscript" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    export GOPATH="${HOME%/}/ghq"
    export PATH="${PATH}:${GOPATH}/bin"
    [ -x "$(command -v ghq)" ]
}
