#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/age.sh"

function setup() {
    load "./install/ubuntu/common/golang.sh"
    main # install golang

    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_golang
    run uninstall_age
    run uninstall_jq
}

@test "[ubuntu-common] age" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    export GOPATH="${HOME}/ghq"
    export PATH="${PATH}:${GOPATH}/bin"
    [ -x "$(command -v age)" ]
    [ -x "$(command -v jq)" ]
}
