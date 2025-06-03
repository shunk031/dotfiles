#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/aws_cli.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_awscli
}

@test "[ubuntu-common] age" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    [ -x "$(command -v aws)" ]
}
