#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/aqua.sh"

function setup() {
    source "${SCRIPT_PATH}"
}


function teardown() {
    run uninstall_aqua
}

@test "[common] aqua" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    [ -x "$(command -v aqua)" ]
}
