#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/macos/common/brew.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

@test "[macos] brew" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    [ -x "$(command -v brew)" ]
}
