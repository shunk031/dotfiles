#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/chezmoi.sh"

function setup() {
    load "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_chezmoi
}

@test "run as shellscript" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"
    [ -x "$(command -v chezmoi)" ]
}
