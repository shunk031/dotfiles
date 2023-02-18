#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/chezmoi.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_chezmoi
}

@test "install_chezmoi" {
    run install_chezmoi
    [ -x "$(command -v chezmoi)" ]
}

@test "main" {
    run main
    [ -x "$(command -v chezmoi)" ]
}

@test "run as shellscript" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"
    [ -x "$(command -v chezmoi)" ]
}
