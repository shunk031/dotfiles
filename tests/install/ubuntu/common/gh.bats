#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/gh.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_gh
}

@test "run as shellscript" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"
    [ -x "$(command -v gh)" ]
}
