#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/macos/common/chezmoi.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_chezmoi
}

@test "[macos] chezmoi" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"
    [ -x "$(command -v chezmoi)" ]
}
