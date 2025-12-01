#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/sheldon.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_sheldon

    # reset PATH
    PATH=$(getconf PATH)
    export PATH
}

@test "[ubuntu-server] sheldon" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    export PATH="${PATH}:${HOME%/}/.local/bin"
    [ -x "$(command -v sheldon)" ]
}
