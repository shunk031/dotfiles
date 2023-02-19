#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/macos/common/ghq.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_ghq
}

@test "[macos] ghq" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"
    [ -x "$(command -v ghq)" ]
}
