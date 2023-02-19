#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/macos/common/gh.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_gh
}

@test "[macos] gh" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"
    [ -x "$(command -v gh)" ]
}
