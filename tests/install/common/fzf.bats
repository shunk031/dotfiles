#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/fzf.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_fzf

    # reset PATH
    PATH=$(getconf PATH)
    export PATH
}

@test "main" {
    run main

    export PATH="${PATH}:${HOME}/.fzf/bin"
    [ -x "$(command -v fzf)" ]
}

@test "run as shellscript" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    export PATH="${PATH}:${HOME}/.fzf/bin"
    [ -x "$(command -v fzf)" ]
}
