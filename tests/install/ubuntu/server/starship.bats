#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/server/starship.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_starship

    # reset PATH
    PATH=$(getconf PATH)
    export PATH
}

@test "[ubuntu-server] starship" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    export PATH="${PATH}:${HOME%/}/.local/bin"
    [ -x "$(command -v stership)" ]
}
