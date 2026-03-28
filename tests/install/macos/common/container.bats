#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/macos/common/container.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_container
}

@test "[macos] container" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    [ -x "$(command -v container)" ]
}
