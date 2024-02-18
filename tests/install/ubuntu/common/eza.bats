#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/eza.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_eza
}

@test "[ubuntu-common] eza" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    export PATH="${PATH}:${HOME%/}/.local/bin"
    [ -x "$(command -v eza)" ]
}
