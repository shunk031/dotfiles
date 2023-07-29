#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/macos/common/exa.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_exa
}

@test "[macos] ghq" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"
    [ -x "$(command -v exa)" ]
}
