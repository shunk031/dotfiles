#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/macos/common/gh.sh"

function setup() {
    load "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_gh
}

@test "run as shellscript" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"
    [ -x "$(command -v gh)" ]
}
