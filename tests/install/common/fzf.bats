#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/fzf.sh"

function setup() {
    load "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_fzf

    # reset PATH
    PATH=$(getconf PATH)
    export PATH
}

@test "run as shellscript" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    export PATH="${PATH}:${HOME}/.fzf/bin"
    [ -x "$(command -v fzf)" ]
}
