#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/exa.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_exa
    run uninstall_jq

    # reset PATH
    PATH=$(getconf PATH)
    export PATH
}

@test "[ubuntu-common] exa" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    export PATH="${PATH}:${HOME%/}/.local/bin"
    [ -x "$(command -v exa)" ]
    [ -x "$(command -v jq)" ]
}
