#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/uv.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    uninstall_uv

    # reset PATH
    PATH=$(getconf PATH)
    export PATH
}

@test "[common] uv" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    export PATH="${PATH}:${HOME}/.cargo/bin"
    [ -x "$(command -v uv)" ]
}
