#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/sheldon.sh"

function setup() {
    sudo apt-get install -qy curl
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_sheldon

    # reset PATH
    PATH=$(getconf PATH)
    export PATH

    sudo apt-get remove -qy curl
}

@test "[ubuntu-server] sheldon" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    export PATH="${PATH}:${HOME%/}/.local/bin"
    [ -x "$(command -v sheldon)" ]
}
